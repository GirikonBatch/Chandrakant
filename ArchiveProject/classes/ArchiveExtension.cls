public class ArchiveExtension{
public string CaseID{get;set;} // CaseID stores the case id that is to be archived  to be processed
List<EmailMessage> delemail = new List<EmailMessage>(); // list of emails to be archived
List<Attachment> lattach = new List<Attachment>();// list to add attachments
List<Attachment> lemailpdf = new List<Attachment>(); // list to contain PDF for archived emails
List<Attachment> lparser = new List<attachment>();  //list to contain parser
public String aid='';//string to store attachment id for every email
public map <id,EmailMessage> emailMap ;
public map <id,Attachment> attmMap=new map<id,Attachment>();


public ArchiveExtension(ApexPages.StandardController controller)
{
CaseID=apexpages.currentpage().getparameters().get('id');
}

// Function call on click of no button
public PageReference DontArchive()
{    
PageReference pg=new PageReference('/'+CaseID);
return pg;
}

//Function call on click of yes button
public PageReference OnArchive()
{
emailMap=new map<id,EmailMessage>([select ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,
         HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,
         LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,
         ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress,ValidatedFromAddress,Counter__c 
         FROM EmailMessage where ParentId=:CaseID]);
attmMap=new map<id,Attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                SystemModstamp FROM Attachment where ParentId in : emailMap.keySet()]);
for(Attachment at : attmMap.values())
                    {
                    attachment atch = new attachment();
                    
                    EmailMessage em =  emailMap.get(at.ParentId); // relevant from bulk perspective 
                    // otherwise simply use CaseID
                    
                    atch.Body = at.Body;
                    atch.ContentType = at.ContentType;
                    atch.Description = at.Description;
                    atch.IsPrivate =  at.IsPrivate;
                    atch.Name  =  'ATT'+'_' +em.Counter__c +'_'+ at.Name;
                    atch.ParentId = em.ParentId ;// would be very useful in bulk case
                    lattach.add(atch);
      
                    }

                    if(lattach.size()>0)
                    insert lattach; 
for( EmailMessage em : emailMap.values())
{
                     
                     aid= '';  
                     for(attachment a:lattach )
                     {
                        string s = a.Name;
                        if(s.startsWith('ATT'+ '_'+ em.Counter__c))
                        {
                            aid = aid+a.Id+';' ;
                        } 
                     }
                     //creating pdf file for email   
                     attachment at = new attachment();

                     at.ParentId =  em.ParentId;
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
                                                '#%#'+em.Incoming+//11th
                                                '#%#'+aid);//12th size is 13
                     lparser.add(parse);// adding parser files to list for insertion          
                     delemail.add(em);// adding email objects to list for deletion
           
                  }
            

    insert lemailpdf;
    insert lparser;
    //delete delemial;
    list<task> t = [SELECT Id,TaskSubtype,WhatId,WhoId FROM Task WHERE TaskSubtype = 'email' AND WhatId =:CaseID];
            delete t;
            if(t.size()>0)
            database.emptyRecycleBin(t);
    Case c=new Case(id=CaseID);
    c.IsArchived__c=true;
    update c;
    PageReference pg=new PageReference('/'+ CaseID);
    return pg; 
}


}

