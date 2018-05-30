global class BatchArchive implements Database.Batchable<sObject>{
        public String Query;
        string aid='';
        map<id,case> map_casemap;
        map<id, EmailMessage> map_email;         
        map<id, attachment> map_atm;
        list<EmailMessage> ldel_email = new list<EmailMessage>();
        list<attachment> lattach = new list<attachment>();  // list to add attachments
        list<attachment> lemailpdf = new list<attachment>();  // list to insert emails
        list<attachment> lparser=new list<attachment>();
        

        //constructor to pass Query for extracting specific cases 
        global BatchArchive( String Query)
        {
                   this.Query=Query;
        }
       
        // Start Method executing that query
        global Database.QueryLocator start(Database.BatchableContext BC)
        {
        return Database.getQueryLocator(Query);
        }
      
        // Execute Logic
        global void execute(Database.BatchableContext BC, List<Case> lcases)
        {
              
            map_casemap =  new map<id,case>(lcases);
            map_email = new map<id, EmailMessage>([SELECT ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,Counter__c,FromAddress,FromName,
                                              Hasattachment,Headers,HtmlBody,Id,Incoming,IsDeleted,IsExternallyVisible,
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

            //deleting tasks everytime to keep the size constant
        list<task> t = [SELECT Id,TaskSubtype,WhatId,WhoId FROM Task WHERE TaskSubtype = 'email' AND WhatId in: map_casemap.keySet()];
        delete t;
        if(t.size()>0)
        database.emptyRecycleBin(t);
        List<Case> b=new List<Case>();
        // the case field IsArchived is made true here so that it is not archived again
        For(Case v:map_casemap.values())
        {
            v.IsArchived__c=true;
            b.add(v);
        }
        update b;    //updating IsArchived CHeckBOx for every case         
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