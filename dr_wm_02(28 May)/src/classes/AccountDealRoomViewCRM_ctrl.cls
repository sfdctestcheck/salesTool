/*********************************************************************************
** Module Name : AccountDealRoomViewCRM ...updated data

*********************************************************************************/
public with sharing class AccountDealRoomViewCRM_ctrl{
    
    public string sessionID {get;set;}    
    public string accountID {get;set;}
    public string serverUrl {get;set;}
    public string namespace {get;set;}
    public  string drAdminNewStr{get;set;}
    public  string mnaOrgId{get;set;}
    
    public AccountDealRoomViewCRM_ctrl(){
        try{
            string paramString= ApexPages.currentPage().getParameters().get('SessionID');
             System.debug('Session Id---------'+paramString);              
            List<string>  stringUrlParameters = paramString.split('_@_');
          
            if(stringUrlParameters.size()>0)
            {
                accountID = stringUrlParameters[2];
                serverUrl = stringUrlParameters[1];
                namespace = stringUrlParameters[4];
                mnaOrgId =  stringUrlParameters[3];   
            }
            sessionID = stringUrlParameters[0];   //session id from the querystring
            LoadGrid();
        }
        catch(Exception ex){                
            apexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()); 
            ApexPages.addMessage(myMsg);   
        }
    }
    
   
}
