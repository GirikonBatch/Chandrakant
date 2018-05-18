public class ArchiveExtension{
public string CaseID{get;set;} // Case ID  to be processed
List<EmailMessage> lemail = new List<EmailMessage>(); // list of emails to be archived
List<Attachment> lattach = new List<Attachment>();
List<Attachment> lemailpdf = new List<Attachment>(); // list to contain PDF for archived emails
List<Attachment> lparser = new List<attachment>();  //list to contain parser
public String aid='';//string to store attachment id for every email
public List<String> lstring = new List<String>();
public ArchiveExtension(ApexPages.StandardController controller){}



// Function call on click of no button
public PageReference DontArchive()
{
CaseID=apexpages.currentpage().getparameters().get('id');
PageReference pg=new PageReference('/'+CaseID);
return pg;
}
public PageReference OnArchive()
{

CaseID=apexpages.currentpage().getparameters().get('id');

for( EmailMessage em :[select ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress,ValidatedFromAddress,Counter__c FROM EmailMessage where ParentId=:CaseID])
{
lemail.add(em);

// Converting every email into a new attachment of type pdf
String pdfContent = 'Name:'+ em.FromAddress + '<br>'+'Subject:'+em.subject + '<br>' + 'Body:'+em.textBody;
Attachment attachmentPDF = new Attachment();
attachmentPdf.parentId = CaseID;
attachmentPdf.name = 'EM'+em.Counter__c+'.pdf';
attachmentPdf.body = blob.toPDF(pdfContent);
lemailpdf.add(attachmentPdf);


//converting email attachments of every email to case attachments by chnging their parent id

    for(attachment a:[select id,name,parentID,body from attachment where parentid in :lemail])
    {
    Attachment att=new Attachment();
    att.body=a.body;
    att.parentId=CaseID;
    att.name=em.Counter__c + a.name ;
    lattach.add(att);
    aid+=a.id+';';
    }
    
    
    //creating a email info parser file for retreiving email back
    Attachment at = new Attachment();
    at.parentId = CaseID;
    at.name='Parser'+em.Counter__c+'.txt';
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
                            '#%#'+aid);
    lparser.add(at);

    
    
}
insert lattach;
insert lemailpdf;
//delete lemail;
insert lparser;

PageReference pg=new PageReference('/'+ CaseID);
return pg;
}







public PageReference DontRestore()
{
CaseID=apexpages.currentpage().getparameters().get('id');
PageReference pg=new PageReference('/'+CaseID);
return pg;
}






public PageReference OnRestore(){
CaseID=apexpages.currentpage().getparameters().get('id');

Attachment att = new Attachment(id='00P7F0000042R7y');//hardcoded for checking
if(att.name=='Parser0065.txt')
{
String bodyContent = att.body.toString();
System.debug('Chanra#######################'+bodyContent);
for(String s:bodycontent.split('#%#'))
{
    lstring.add(s);
}
String bcc =lstring[0];
String CC =lstring[1];
String FromAddress=lstring[2];
String FromName=lstring[3];
String Headers=lstring[4];
String Incoming=lstring[5];
String MessageDate=lstring[6];
String ParentId=lstring[7];
String Status=lstring[8];
String ToAddress=lstring[9];
String Subject=lstring[10];
String attachments=lstring[11];

}
EmailMessage em=new EmailMessage();





return (new PageReference('/'+CaseID));
}



}//end of class
