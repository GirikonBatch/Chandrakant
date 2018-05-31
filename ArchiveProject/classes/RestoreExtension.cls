public class RestoreExtension{

public String CaseID;
public RestoreExtension( ApexPages.StandardController controller){
CaseID=apexpages.currentpage().getparameters().get('id');
}

public PageReference DontRestore() //function call on click of no button
{
PageReference pg=new PageReference('/'+CaseID);
return pg;
}

public PageReference OnRestore(){  //function call on click of yes button
List<EmailMessage> emailRestore=new List<EmailMEssage>();//email list to restore
List<String> atids = new List<String>();
Map<integer,List<id>> IndexAttachmentMap=new Map<integer,List<id>>();
Map<id,List<id>> EmailIDAttachmentMap=new Map<id,List<id>>();

List<Attachment> ATTFILES = new List<Attachment>();
integer i=0;
ATTFILES=[Select Id,ParentId,Name,body From Attachment where name like '%Parser.txt' and ParentID=:CaseID]; //use ParentID in:ListCaseID  in bulk
Map <id,Attachment> AllAttach=new Map<id,Attachment>([Select Id,ParentId,Name,body,ContentType,description,IsPrivate,ownerId From Attachment where ParentID=:CaseID]);

for(Attachment at:ATTFILES)
 {
    //Reading Parser File and creating a email corresponding to every parser and fetching attachment ids in parser
    String bodyContent = at.body.toString(); //bodyContent is body of parser file
    String[] lstring = bodycontent.split('#%#');
    //system.debug('############################'+ lstring);
    EmailMessage em=new EmailMessage();
    em.BccAddress=lstring[1];
    em.CcAddress=lstring[2];
    em.FromAddress=lstring[3];
    System.debug('############################From Address'+lstring[3]);
    em.FromName=lstring[4];
    em.Headers=lstring[5];
    em.ParentId=lstring[6]; // CaseID can also be used but this will help in bulk so it is used
    em.TextBody=lstring[7];
    em.ToAddress=lstring[9];
    em.Subject=lstring[10];
    em.Incoming=Boolean.valueOf(lstring[11]);
    emailrestore.add(em); // adding email object to list for insertion outside for loop
    
    if(lstring.size()==13)  //check if attachment ids are there or not 
    {
    atids.clear();
    atids = lstring[12].split(';'); //atids contains  attachment ids stored in parser file
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
    if(IndexAttachmentMap.get(j)!=NULL){
    EmailIDAttachmentMap.put(emailrestore[j].id, IndexAttachmentMap.get(j)) ;  //saving emailid and corresponding attachments id using map1 
    //IndexAttachmentMap.remove(j);
    }
}
        
        
    //System.debug('++++++++++++++++++++++++'+EmailIDAttachmentMap);
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

    PageReference pg=new PageReference('/'+CaseID);
    return pg;
}
void del()
    {
        List<Attachment> ParserfilesDelete=new List<Attachment>();
        List<Attachment> EmailfilesDelete=new List<Attachment>();
         ParserfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like '%Parser.txt' and ParentId=:CaseID];
         EmailfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'EM%.pdf' and ParentId=:CaseID];
        //Delete ParserfilesDelete;
        //Delete EmailfilesDelete;
    }

}