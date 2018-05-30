global class BatchRestore implements Database.Batchable<sObject>{
        public String Query;
        Integer i=0;
        List<EmailMessage> lemailrestore= new List<EmailMessage>();
        List<String> atids = new List<String>();
        list<case> arch_update=new List<Case>();
        map<id,case> map_casemap;
        map<id, attachment> map_atm;
        map <Integer,List<id>> IndexAttachmentMap =new Map<Integer,List<id>>();
        map<Id,List<id>> EmailIDAttachmentMap=new map<Id,List<id>>();
        map <id,Attachment> AllAttach=new Map<id,Attachment>();
        //constructor to pass Query for extracting specific cases 
        global BatchRestore( String Query)
        {
                   this.Query=Query;
        }
       
        // Start Method
        global Database.QueryLocator start(Database.BatchableContext BC)
        {
         return Database.getQueryLocator(query);
        }
      
       // Execute Logic
        global void execute(Database.BatchableContext BC, List<Case> lcases)
        {
            map_casemap =  new map<id,case>(lcases);
            map_atm = new map<id, attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                             IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                                             SystemModstamp FROM attachment where  ParentId in : map_casemap.keySet() and  Name like '%Parser.txt' ]); 
            Map <id,Attachment> AllAttach=new Map<id,Attachment>([Select Id,ParentId,Name,body,ContentType,description,IsPrivate,ownerId From Attachment where ParentID in :map_casemap.keySet()]);
            for(Attachment at:map_atm.values())
            {
            //Reading Parser Files from attachment object relevant to cases extracted in restored query and
            // creating a email corresponding to every parser and fetching attachment ids in parser
            String bodyContent = at.body.toString(); //bodyContent is body of parser file
            String[] lstring = bodycontent.split('#%#');
            system.debug('############################'+ lstring);
            System.debug('####################'+at.id);
            EmailMessage em=new EmailMessage();
            em.BccAddress=lstring[1];
            em.CcAddress=lstring[2];
            em.FromAddress=lstring[3];
            em.FromName=lstring[4];
            em.Headers=lstring[5];
            em.ParentId=lstring[6]; // Assigning parent id from parser file 
            em.TextBody=lstring[7];
            em.ToAddress=lstring[9];
            em.Subject=lstring[10];
            lemailrestore.add(em); 


            if(lstring.size()==12)  //check if attachment ids are there or not 
            {
                atids.clear();
                atids = lstring[11].split(';'); //atids contains  attachment ids stored in parser file
                //system.debug('##############atids############ inside if condition'+atids);
                    
                // Storing list of ids
                if(atids.size()>0)
                {
                    //system.debug('##########ATTACHMENTIDS##########'+ atids);
                    List<id> AttachmentsID=new List<id>(); // temp list this will contain attachment ids to be inserted       
                        For(integer j=0;j<atids.size();j++)
                        {    
                            AttachmentsID.add(atids[j]);
                            //System.debug('######################### '+AttachmentsID );
                        } 
                        IndexAttachmentMap.put(i++,AttachmentsID);// saving attachment ids with indexes in Map
                        //SYstem.debug('#############'+ AttachmentsID +'   '+ i);

                }
            }
            if(lstring.size()<12)
            {
                i++;
            }
            }
        insert lemailrestore;   //email objects inserted    
        
        for(integer j=0;j<lemailrestore.size();j++)
        {
            if(IndexAttachmentMap.get(j)!=NULL)
            {
            EmailIDAttachmentMap.put(lemailrestore[j].id, IndexAttachmentMap.get(j)) ;  //saving emailid and corresponding attachments id using map1 
            //IndexAttachmentMap.remove(j);
            }
        }

        List<Attachment> atmList=new List<Attachment>();
        List<Attachment> atmLis=new List<Attachment>();
        for(id eid : EmailIDAttachmentMap.keySet() )   // traversing list of inserted email ids in map2
         {      
             List<id> atid;
             if(EmailIDAttachmentMap.get(eid) != NULL)
             {
                 atid=new List<id>(EmailIDAttachmentMap.get(eid));// saving a set of ids for specific email id
             }
             for(Integer j=0;j<atid.size();j++)
             {
                    Attachment At=AllAttach.get(atid[j]);
                    attachment atch = new attachment();
                    atch.Body = At.Body;
                    atch.ContentType = At.ContentType;
                    atch.Description = At.Description;
                    atch.IsPrivate =  At.IsPrivate;
                    atch.Name  = At.Name.substringAfterLast('_') ;
                    atch.OwnerId = At.OwnerId;
                    atch.ParentId = eid;
                    atmList.add(atch);  
                    atmLis.add(at); 
             }                   
         } 

         insert atmList; //insert
         //delete atmLis;
         del();
         for(Case c:map_casemap.values())
         {
             c.IsArchived__c=False;
             arch_update.add(c);
         }
         update arch_update;
    }
void del()
    {
        List<Attachment> ParserfilesDelete=new List<Attachment>();
        List<Attachment> EmailfilesDelete=new List<Attachment>();
        ParserfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like '%Parser.txt' and ParentId in :map_casemap.keySet()];
        EmailfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'EM%.pdf' and ParentId in :map_casemap.keySet()];
        //Delete ParserfilesDelete;
        //Delete EmailfilesDelete;
    }
     
        
     
        global void finish(Database.BatchableContext BC)
        {
           AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,
           TotalJobItems, CreatedBy.Email
           from AsyncApexJob where Id =:BC.getJobId()];
         
           Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           String[] toAddresses = new String[] {a.CreatedBy.Email};
           mail.setToAddresses(toAddresses);
           mail.setSubject('BatchScheduleArchive  ' + a.Status);
           mail.setPlainTextBody('No. of Batches processed' + a.TotalJobItems +
          'with '+ a.NumberOfErrors + ' failures.');
           Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }