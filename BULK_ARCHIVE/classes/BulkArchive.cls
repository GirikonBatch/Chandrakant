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
    map<id , case> map_case_arc;
    public list<Case> c{get;set;}
    map<id, EmailMessage> map_mail;         
    map<id, attachment> map_attm;
    
     string attach_ids='';
     list<EmailMessage> mail_del = new list<EmailMessage>();
    list<attachment> att_insert = new list<attachment>();
    list<attachment> mail_insert = new list<attachment>();
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
        mail_del.clear();
        att_insert.clear();
        mail_insert.clear();
        
        Query='SELECT AccountId,AssetId,CaseNumber,CFACE__Archived_Count__c,CFACE__Archive_Date__c,CFACE__Is_Archived__c,'+
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
        
         list<case> case_arc=Database.query(Query);
        
        
         map_case_arc =  new map<id,case>(case_arc);
        
        
        
        map_mail = new map<id, EmailMessage>([SELECT ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,Counter__c,FromAddress,FromName,
                                              HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,
                                              LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,
                                              ReplyToEmailMessageId,Status,Subject,SystemModstamp,TextBody,ThreadIdentifier,ToAddress,
                                              ValidatedFromAddress FROM EmailMessage where ParentId in : map_case_arc.keySet() ]) ;
        
        map_attm = new  map<id, attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                             IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                                             SystemModstamp FROM Attachment where ParentId in : map_mail.keySet()]);
        
        
        for(attachment att : map_attm.values()){
                    
                      attachment atch = new attachment();
                    
                    EmailMessage ec =  map_mail.get(att.ParentId);
                    
                    atch.Body = att.Body;
                    atch.ContentType = att.ContentType;
                    atch.Description = att.Description;
                    atch.IsPrivate =  att.IsPrivate;
                    atch.Name  =  ec.Counter__c+'_'+ec.Subject+'__Attachment_'+ att.Name;
                    atch.OwnerId = att.OwnerId;
                    atch.ParentId = ec.ParentId ;
                    
                    //system.debug('##############'+ atch);
                     att_insert.add(atch);
      
                  }
        
        if(att_insert.size()>0)
          insert att_insert;    
        
        for( EmailMessage caseMial : map_mail.values() ){
                     
                     attach_ids = '';  
                     for(attachment a:att_insert ){
                         string s = a.Name;
                                 if(s.startsWith(caseMial.Counter__c+'_'+caseMial.Subject+'__Attachment_')){
                                    attach_ids = attach_ids+a.Id+';' ;
                                 } 
                        }
                         
                             attachment atch = new attachment();

                                 atch.ParentId =  caseMial.ParentId;
                                 atch.Name = caseMial.Counter__c+'_'+caseMial.Subject+'_Email.pdf';
                                 atch.Body = blob.toPDF(caseMial.FromName+'<br/>'+caseMial.FromAddress+'<br/>'+caseMial.CcAddress +'<br/>' +caseMial.CcAddress+'<br/>'+caseMial.Subject+'<br/>' +caseMial.TextBody +'<br/>'  );
                                        
                                        mail_insert.add(atch);
                         
                             attachment atchtxt = new attachment();

                                    atchtxt.ParentId = caseMial.ParentId;
                                    atchtxt.Name = caseMial.Counter__c+'_'+caseMial.Subject+'_Parser.txt';
                                    atchtxt.Body =  blob.valueOf('#%#BccAddress='+caseMial.BccAddress+'#%#CcAddress='+caseMial.CcAddress+
                                                           '#%#FromAddress='+caseMial.FromAddress+'#%#FromName='+caseMial.FromName+
                                                            '#%#Headers='+caseMial.Headers+'#%#Incoming='+caseMial.Incoming+'#%#MessageDate='+
                                                            caseMial.MessageDate+'#%#ParentId='+caseMial.ParentId+'#%#TextBody='+caseMial.TextBody+'#%#Status='+caseMial.Status+'#%#ToAddress='+
                                                            caseMial.ToAddress+'#%#Subject='+caseMial.Subject+'#%#Attachment=;'+attach_ids);
                                        mail_insert.add(atchtxt);
                                
                                
                                       mail_del.add(caseMial);
           
                  }
            
        
            insert mail_insert;      
                delete mail_del;  
                if(mail_del.size()>0)
                database.emptyRecycleBin(mail_del);
        
                 list<task> t = [SELECT Id,TaskSubtype,WhatId,WhoId FROM Task WHERE TaskSubtype = 'email' AND WhatId in: map_case_arc.keySet()];
                    delete t;
                    if(t.size()>0)
                    database.emptyRecycleBin(t);
        List<Case> b=new List<Case>();
        For(Case v:map_case_arc.values())
        {
            v.IsArchived__c=true;
            b.add(v);
        }
        
update b;            
    }
    
     public void show()
    {   b=true;
        Query='SELECT AccountId,AssetId,CaseNumber,CFACE__Archived_Count__c,CFACE__Archive_Date__c,CFACE__Is_Archived__c,'+
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
                
}