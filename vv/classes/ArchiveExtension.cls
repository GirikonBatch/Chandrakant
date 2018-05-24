public class ArchiveExtension{
public string CaseID{get;set;} // CaseID stores the case id that is to be archived  to be processed
List<EmailMessage> lemail = new List<EmailMessage>(); // list of emails to be archived
List<Attachment> lattach = new List<Attachment>();
List<Attachment> lemailpdf = new List<Attachment>(); // list to contain PDF for archived emails
List<Attachment> lparser = new List<attachment>();  //list to contain parser
public String aid='';//string to store attachment id for every email
public List<Integer> lint=new LISt<Integer>();
public List<EmailMessage> emailRestore=new List<EmailMEssage>();//email list to restore


public ArchiveExtension(ApexPages.StandardController controller){
CaseID=apexpages.currentpage().getparameters().get('id');
}

// Function call on click of no button
public PageReference DontArchive()
{
    System.debug('888888gfgfghgfh8gfdjghjghjghgfdgdfgfd8888888888');
PageReference pg=new PageReference('/'+CaseID);
return pg;
}

//Function call on click of yes button
public PageReference OnArchive()
{

for( EmailMessage em :[select ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress,ValidatedFromAddress,Counter__c FROM EmailMessage where ParentId=:CaseID])
{
lemail.add(em); //list of emails to be deleted
// Converting every email into a new attachment of type pdf
String pdfContent = 'Name:'+ em.FromAddress + '<br>'+'Subject:'+em.subject + '<br>' + 'Body:'+em.textBody;
Attachment attachmentPDF = new Attachment();
attachmentPdf.parentId = CaseID;
attachmentPdf.name = 'EM'+em.Counter__c+'.pdf';
attachmentPdf.body = blob.toPDF(pdfContent);
lemailpdf.add(attachmentPdf);//adding every pdf_Attachment to a list for insertion later on

//converting  attachments of every email to case attachments by chnging their parent id

    for(attachment a:[select id,name,parentID,body from attachment where parentid=:em.id])
    {     
    Attachment att=new Attachment();
    att.body=a.body;
    att.parentId=CaseID;
    att.name=em.Counter__c + '_' + a.name ;
    lattach.add(att);
    }
   }
insert lattach;
    
    //creating a email info parser file for retreiving email back
    for(EmailMessage em:lemail)
    {
        for(Attachment a:[select id,name,parentID,body from attachment where parentid=:CaseID and name like :(em.Counter__c+'%')])
        {
        aid=a.id+';'; //storing attachment id of every mail into single string and storing in parser file
        }   
    Attachment at = new Attachment();
    at.parentId = CaseID;
    at.name ='Parser'+em.Counter__c + '.txt';
    at.body = blob.valueOf ('#%#'+em.BccAddress+
                            '#%#'+em.CcAddress+
                            '#%#'+em.FromAddress+
                            '#%#'+em.FromName+
                            '#%#'+em.Headers+
                            '#%#'+em.Incoming+
                            '#%#'+em.MessageDate+
                            '#%#'+CaseID+
                            '#%#'+em.Status+
                            '#%#'+em.ToAddress+
                            '#%#'+em.Subject+
                            '#%#'+aid); // it stores attachment id string in parser file
    lparser.add(at);
    System.debug('############'+aid);
    aid=''; //clearing the string for another email attachment ids
    }

insert lemailpdf; // inserting email pdfs
//delete lemail;
insert lparser; // inserting parser txt files

PageReference pg=new PageReference('/'+ CaseID);
return pg;
}

}