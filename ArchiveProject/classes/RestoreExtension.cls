public class RestoreExtension{

public String CaseID;
public List<EmailMessage> emailRestore=new List<EmailMEssage>();//email list to restore
public RestoreExtension( ApexPages.StandardController controller){
CaseID=apexpages.currentpage().getparameters().get('id');
}

public PageReference DontRestore()
{

PageReference pg=new PageReference('/'+CaseID);
return pg;
}






public PageReference OnRestore(){
List<String> atids = new List<String>();
Map<integer,List<id>> EmailAttachementMap=new Map<integer,List<id>>();
integer i=0;
for(Attachment at:[Select Id,ParentId,Name,body From Attachment where name like 'Parser%' and ParentID=:CaseID])
 {


    //Reading PArser File and creating a email corresponding to every parser and fetching attachment ids in parser
    String bodyContent = at.body.toString(); //bodyContent is body of parser file
    String[] lstring = bodycontent.split('#%#');
    //system.debug('############################'+ lstring);

    EmailMessage em=new EmailMessage();
    em.BccAddress=lstring[1];
    em.CcAddress=lstring[2];
    em.FromAddress=lstring[3];
    em.FromName=lstring[4];
    em.Headers=lstring[5];
    em.ParentId=CaseID;
    em.ToAddress=lstring[10];
    em.Subject=lstring[11];
    emailrestore.add(em);
    
    if(lstring.size()==13)
    {
    system.debug('###########IFLOOOPTESTED&&&&&&&&&&&');
    atids = lstring[12].split(';'); //atids contains  attachment ids stored in parser file
    }
    // Storing list of ids
    if(atids.size()>0)
    {
    system.debug('##########ATTACHMENTIDS##########'+atids);
    List<id> AttachmentsID=new List<id>(); // this will contain attachment ids to be inserted       
        For(integer j=0;j<atids.size();j++)
        {    Attachment b=new Attachment();
             b = [SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
               IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,SystemModstamp FROM Attachment WHERE id=:atids[j]];
            AttachmentsID.add(b.id);
            System.debug('######################### '+ b);
        } 
               EmailAttachementMap.put(i++,AttachmentsID);
               SYstem.debug('#############'+ AttachmentsID +'   '+ i);

    }
}

insert emailrestore;



    
    
        Map<id,List<id>> EmailAttachementMap1=new Map<id,List<id>>();
        
        
        for(integer j=0;j<emailrestore.size();j++){
        EmailAttachementMap1.put(emailrestore[j].id, EmailAttachementMap.get(j)) ;  
        EmailAttachementMap.remove(j);
        }
        //for loop close
        
        System.debug('++++++++++++++++++++++++'+EmailAttachementMap1);
        List<Attachment> atmList=new List<Attachment>();
        List<Attachment> atmLis=new List<Attachment>();
         for(id p_id : EmailAttachementMap1.keySet() )   // traversing list of inserted email ids in map
         {     
              
             if(EmailAttachementMap1.get(p_id) != NULL){
                 for(attachment attm : [select Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                            IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,
                                            ParentId,SystemModstamp from attachment where id in : EmailAttachementMap1.get(p_id)])
            {
                    
                    attachment atch = new attachment();
                    atch.Body = attm.Body;
                    atch.ContentType = attm.ContentType;
                    atch.Description = attm.Description;
                    atch.IsPrivate =  attm.IsPrivate;
                    atch.Name  = attm.Name.substringAfterLast('_') ;
                    atch.OwnerId = attm.OwnerId;
                    atch.ParentId =p_id;
                    atmList.add(atch);  
                    atmLis.add(attm);                    
               }
             }  
        }//For loop close
       
       insert atmList; //inser
       //delete atmLis;
       del();

    PageReference pg=new PageReference('/'+CaseID);
    return pg;
}
void del()
    {
        List<Attachment> ParserfilesDelete=new List<Attachment>();
        List<Attachment> EmailfilesDelete=new List<Attachment>();
         ParserfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'Parser%.txt' and ParentId=:CaseID];
         EmailfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'EM%.pdf' and ParentId=:CaseID];
        //Delete ParserfilesDelete;
        //Delete EmailfilesDelete;
    }

}