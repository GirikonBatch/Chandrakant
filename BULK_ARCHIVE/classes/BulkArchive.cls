public class BulkArchive{

    
    
    public String CaseStatus{get;set;}
    public String CaseReason{get;set;}
    public String CaseOrigin{get;set;}
    public String CaseCreatedOlder{get;set;}
    public Integer RecordSize{get;set;}
    public String CaseClosedOlder{get; set;}
    public String Query; //holds the soql to be executed
    public String Case_Status;
    public String Case_Reason;
    public String Case_Origin;
    public String Case_Created_Older;
    public String Case_Closed_Older;
    public Boolean arch{get;set;}
    public Boolean rest{get;set;}
    
    public boolean b{get;set;}
    map<id,case> map_casemap;
    map<id, EmailMessage> map_email;         
    map<id, attachment> map_atm;
    public list<Case> c{get;set;}
    
    string aid='';
    list<EmailMessage> ldel_email = new list<EmailMessage>();
    list<attachment> lattach = new list<attachment>();  // list to add attachments
    list<attachment> lemailpdf = new list<attachment>();  // list to insert emails
    list<attachment> lparser=new list<attachment>();
    
    public BulkArchive()
    {
        b=false;
        Query='';
        Case_Status='';
        Case_Origin='';
        Case_Created_Older='';
        Case_Closed_Older='';
    }
    public Void ArchiveCases()
    {
        ldel_email.clear();
        lattach.clear();
        lemailpdf.clear();
        
        Query='SELECT AccountId,AssetId,CaseNumber,'+
            'ClosedDate,ContactEmail,ContactFax,ContactId,ContactMobile,ContactPhone,CreatedById,CreatedDate,'+
            'Days_Since_Last_Update__c,Description,EngineeringReqNumber__c,Id,IsArchived__c,IsClosed,IsDeleted,'+
            'IsEscalated,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Origin,OwnerId,ParentId,'+
            'PotentialLiability__c,Priority,Product__c,Reason,SLAViolation__c,SourceId,Status,Subject,SuppliedCompany,'+
            'SuppliedEmail,SuppliedName,SuppliedPhone,SystemModstamp,Type FROM Case where IsArchived__c=false';
        Case_Status=(CaseStatus=='closed'? ' AND IsClosed  = true' : ' And status =  \''+CaseStatus+'\'');
        case_Origin=(CaseOrigin=='z'? '' : ' AND origin =  \''+CaseOrigin+'\'');
        case_created_older=(CaseCreatedOlder=='All'? '' : ' AND CreatedDate < LAST_N_DAYS:'+CaseCreatedOlder);
        case_closed_older=(CaseClosedOlder=='All'? '' : ' AND ClosedDate < LAST_N_DAYS:'+CaseClosedOlder);
        Query+=Case_Status+case_Origin+case_created_older+case_closed_older+' limit '+RecordSize;
        
        list<case> casemap=Database.query(Query);
        
        
        map_casemap =  new map<id,case>(casemap);
        
        
        
        map_email = new map<id, EmailMessage>([SELECT ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,Counter__c,FromAddress,FromName,
                                              Hasattachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,
                                              LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,
                                              ReplyToEmailMessageId,Status,Subject,SystemModstamp,TextBody,ThreadIdentifier,ToAddress,
                                              ValidatedFromAddress FROM EmailMessage where ParentId in : map_casemap.keySet() ]) ;
        
        map_atm = new  map<id, attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                             IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                                             SystemModstamp FROM attachment where ParentId in : map_email.keySet()]);
        
        
        for(attachment at : map_atm.values())
                {
                    
                    attachment atch = new attachment();
                    EmailMessage em =  map_email.get(at.ParentId);
                    atch.Body = at.Body;
                    atch.ContentType = at.ContentType;
                    atch.Description = at.Description;
                    atch.IsPrivate =  at.IsPrivate;
                    atch.Name  =  'ATT'+'_' +em.Counter__c +'_'+ at.Name;
                    atch.OwnerId = at.OwnerId;
                    atch.ParentId = em.ParentId ;
                    
                    //system.debug('##############'+ atch);
                     lattach.add(atch);
      
                }
        
                if(lattach.size()>0)
                insert lattach;    
        
        for( EmailMessage em : map_email.values() )
                {
                     
                     aid = '';  
                     for(attachment a:lattach )
                        {
                         string s = a.Name;
                                 if(s.startsWith('ATT'+ '_'+ em.Counter__c))
                                 {
                                    aid = aid+a.Id+';' ;
                                 } 
                        }
                        //creating pdf for evry email 
                        attachment at = new attachment();

                        at.ParentId =  em.ParentId; //binding pdf with its relevant case
                        at.Name = 'EM'+'_'+ em.Counter__c+'_.pdf';
                        at.Body = blob.toPDF(em.FromName+'<br/>'+em.FromAddress+'<br/>'+em.CcAddress +'<br/>' +em.BccAddress+'<br/>'+em.Subject+'<br/>' +em.TextBody +'<br/>'  );
                                        
                        lemailpdf.add(at);
                         
                        //creating parser file for every email
                        attachment parse = new attachment();
                        parse.ParentId = em.ParentId;
                        parse.Name = em.Counter__c+'_'+em.Subject+'_Parser.txt';
                        parse.Body =  blob.valueOf('#%#'+em.BccAddress+ //1st 
                                                '#%#'+em.CcAddress+ //2nd
                                                '#%#'+em.FromAddress+
                                                '#%#'+em.FromName+
                                                '#%#'+em.Headers+
                                                '#%#'+em.ParentId+ // 6th ie case id
                                                '#%#'+em.TextBody+ //body
                                                '#%#'+em.Status+
                                                '#%#'+em.ToAddress+
                                                '#%#'+em.Subject+
                                                '#%#'+aid);
                        lparser.add(parse);      
                        ldel_email.add(em);
           
                }
            
        
            insert lemailpdf;
            insert lparser;      
            //delete ldel_email;  
            if(ldel_email.size()>0)
            database.emptyRecycleBin(ldel_email);

            //deleting tasks to reduce memory 
            list<task> t = [SELECT Id,TaskSubtype,WhatId,WhoId FROM Task WHERE TaskSubtype = 'email' AND WhatId in: map_casemap.keySet()];
            delete t;
            if(t.size()>0)
            database.emptyRecycleBin(t);
            List<Case> b=new List<Case>();
            //checking the case field IsArchived so that it is not archived again
            For(Case v:map_casemap.values())
            {
            v.IsArchived__c=true;
            b.add(v);
            }
        
            update b;            
    }
    
    public void show()
    //method to show the cases that are going to be archived
    {   arch=false;rest=true;
        b=true; // variable that renders the 
        Query='SELECT AccountId,AssetId,CaseNumber,'+
            'ClosedDate,ContactEmail,ContactFax,ContactId,ContactMobile,ContactPhone,CreatedById,CreatedDate,'+
            'Days_Since_Last_Update__c,Description,EngineeringReqNumber__c,Id,IsArchived__c,IsClosed,IsDeleted,'+
            'IsEscalated,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Origin,OwnerId,ParentId,'+
            'PotentialLiability__c,Priority,Product__c,Reason,SLAViolation__c,SourceId,Status,Subject,SuppliedCompany,'+
            'SuppliedEmail,SuppliedName,SuppliedPhone,SystemModstamp,Type FROM Case where IsArchived__c=False';
        Case_Status=(CaseStatus=='closed'? ' AND IsClosed  = true' : ' AND status =  \''+CaseStatus+'\'');
        case_Origin=(CaseOrigin=='z'? '' : ' AND origin =  \''+CaseOrigin+'\'');
        case_created_older=(CaseCreatedOlder=='All'? '' : ' AND CreatedDate < LAST_N_DAYS:'+CaseCreatedOlder);
        case_closed_older=(CaseClosedOlder=='All'? '' : ' AND ClosedDate < LAST_N_DAYS:'+CaseClosedOlder);
        Query+=Case_Status+case_Origin+case_created_older+case_closed_older+' limit '+RecordSize;
           
     c = Database.query(Query);
        
    }
    
    


    // method call on bulk restore 
    public PageReference RestoreCases() {
        
        list<emailMessage> emailRestore = new list<EmailMessage>();
        list<case> arch_update=new List<Case>();
        List<Attachment> ATTFILES=new List<Attachment>();
        map <Integer,List<id>> IndexAttachmentMap =new Map<Integer,List<id>>();
        map<Id,List<id>> EmailIDAttachmentMap=new map<Id,List<id>>();
        List<String> atids = new List<String>();
        List<Case> lcases=new List<Case>();
        integer i=0;
        Query='SELECT AccountId,AssetId,CaseNumber,'+
            'ClosedDate,ContactEmail,ContactFax,ContactId,ContactMobile,ContactPhone,CreatedById,CreatedDate,'+
            'Days_Since_Last_Update__c,Description,EngineeringReqNumber__c,Id,IsArchived__c,IsClosed,IsDeleted,'+
            'IsEscalated,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Origin,OwnerId,ParentId,'+
            'PotentialLiability__c,Priority,Product__c,Reason,SLAViolation__c,SourceId,Status,Subject,SuppliedCompany,'+
            'SuppliedEmail,SuppliedName,SuppliedPhone,SystemModstamp,Type FROM Case where IsArchived__c=True';
        Case_Status=(CaseStatus=='closed'? ' AND IsClosed  = true' : ' And status =  \''+CaseStatus+'\'');
        case_Origin=(CaseOrigin=='z'? '' : ' AND origin =  \''+CaseOrigin+'\'');
        case_created_older=(CaseCreatedOlder=='All'? '' : ' AND CreatedDate < LAST_N_DAYS:'+CaseCreatedOlder);
        case_closed_older=(CaseClosedOlder=='All'? '' : ' AND ClosedDate < LAST_N_DAYS:'+CaseClosedOlder);
        Query+=Case_Status+case_Origin+case_created_older+case_closed_older+' limit '+RecordSize;
        system.debug('########################'+Query);
        lcases=Database.query(Query);
    
        map_casemap =  new map<id,case>(lcases);
        system.debug('############$$$$$$$$$$$$$$$$$$'+ map_casemap);
        map_atm = new map<id, attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                             IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                                             SystemModstamp FROM attachment where  ParentId in : map_casemap.keySet() and  Name like '%Parser.txt' ]);
        Map <id,Attachment> AllAttach=new Map<id,Attachment>([Select Id,ParentId,Name,body,ContentType,description,IsPrivate,ownerId From Attachment where ParentID in :map_casemap.keySet()]);
        for(Attachment at:map_atm.values())
        {
            //Reading Parser File and creating a email corresponding to every parser and fetching attachment ids in parser
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
            em.ParentId=lstring[6]; // CaseID can also be used but this will help in bulk so it is used
            em.TextBody=lstring[7];
            em.ToAddress=lstring[9];
            em.Subject=lstring[10];
            emailrestore.add(em); 


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
        insert emailrestore;   //email objects inserted    
        
        for(integer j=0;j<emailrestore.size();j++)
        {
            if(IndexAttachmentMap.get(j)!=NULL)
            {
            EmailIDAttachmentMap.put(emailrestore[j].id, IndexAttachmentMap.get(j)) ;  //saving emailid and corresponding attachments id using map1 
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
    return null; 

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

    public void showRestore()
    //method to show the cases that are going to be archived
    {   arch=true;rest=false;
        b=true; // variable that renders the 
        Query='SELECT AccountId,AssetId,CaseNumber,'+
            'ClosedDate,ContactEmail,ContactFax,ContactId,ContactMobile,ContactPhone,CreatedById,CreatedDate,'+
            'Days_Since_Last_Update__c,Description,EngineeringReqNumber__c,Id,IsArchived__c,IsClosed,IsDeleted,'+
            'IsEscalated,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Origin,OwnerId,ParentId,'+
            'PotentialLiability__c,Priority,Product__c,Reason,SLAViolation__c,SourceId,Status,Subject,SuppliedCompany,'+
            'SuppliedEmail,SuppliedName,SuppliedPhone,SystemModstamp,Type FROM Case where IsArchived__c=True';
        Case_Status=(CaseStatus=='closed'? ' AND IsClosed  = true' : ' AND status =  \''+CaseStatus+'\'');
        case_Origin=(CaseOrigin=='z'? '' : ' AND origin =  \''+CaseOrigin+'\'');
        case_created_older=(CaseCreatedOlder=='All'? '' : ' AND CreatedDate < LAST_N_DAYS:'+CaseCreatedOlder);
        case_closed_older=(CaseClosedOlder=='All'? '' : ' AND ClosedDate < LAST_N_DAYS:'+CaseClosedOlder);
        Query+=Case_Status+case_Origin+case_created_older+case_closed_older+' limit '+RecordSize;
           
     c = Database.query(Query);
        
    }
    public void ScheduleArchivee()
    {
        ScheduleArchive obj= new ScheduleArchive(Query,RecordSize);
        String sch = '0 0 16 * * ?';
        system.schedule('BatchArchive', sch, obj);
    }
    public void ScheduleRestoree()
    {
       ScheduleRestore obj=new ScheduleRestore(Query,RecordSize);
       String sch = '0 0 16 * * ?';
       system.schedule('BatchArchive', sch, obj); 
    }
              
}