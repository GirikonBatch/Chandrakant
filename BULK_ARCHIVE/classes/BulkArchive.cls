public class BulkArchive{

    
    
    public String CaseStatus{get;set;}
    public String CaseReason{get;set;}
    public String CaseOrigin{get;set;}
    public String CaseCreatedOlder{get;set;}
    public Integer RecordSize{get;set;}
    public String CaseClosedOlder{get; set;}
    public String Query;
    public String Case_Status;
    public String Case_Reason;
    public String Case_Origin;
    public String Case_Created_Older;
    public String Case_Closed_Older;
    public boolean b{get;set;}
    map<id,case> map_casemap;
    map<id, EmailMessage> map_email;         
    map<id, attachment> map_atm;
    public list<Case> c{get;set;}
    
    string aid='';
    list<EmailMessage> email_del = new list<EmailMessage>();
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
        email_del.clear();
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
                        email_del.add(em);
           
                }
            
        
            insert lemailpdf;      
            //delete email_del;  
            if(email_del.size()>0)
            database.emptyRecycleBin(email_del);

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
    {   b=true; // variable that renders the 
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
     System.debug('+++++++++++++++++++++++++asdf'+Query);       
     c = Database.query(Query);
        
    }
    
    
    public PageReference RestoreCases() {

        return null;
    }

    
    
    
    
              
}