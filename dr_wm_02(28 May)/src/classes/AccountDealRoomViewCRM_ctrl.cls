/*********************************************************************************
** Module Name : AccountDealRoomViewCRM ...updated data
** Description : This is for showing the section of dealrooms in an Account Detail Page
** Throws : NA
** Calls : NA
** Test Class : TestAccountDealRoomView_ctrl nnn
** Organization : Navatar Group
** Revision History:-
** Version Date(YYYY-MM-DD)       Author      Description of Action
** 1.0     2015-06-08             Vanita      It will fetch the Deals 
** 1.3     2017-02-06             Shaharyar   To Restrict Deal On Account Detail Page With Respect To UserPermission 
*********************************************************************************/
public with sharing class AccountDealRoomViewCRM_ctrl{
    
    public string sessionID {get;set;}    
    public string accountID {get;set;}
    public string serverUrl {get;set;}
    //public string orgID {get;set;}
    public string namespace {get;set;}
    public string[] stringDealArray {get;set;}
    public JsonParserDeal jsonWrapperDeal {get;set;}
    private Integer counter=1;  //keeps track of the 
    private Integer page_size=10; //sets the page size or number of rows    
    //public Integer changePageNo{get;set;}
    public Integer dealListSize {get;set;}
    public string displayMessage {get;set;}
    public boolean HasAccess {get;set;}
    public string MnADealID {get;set;}
    public string path {get;set;}
    public  string drAdminStr{get;set;}
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
    
    public PageReference OpenDealDetailPage() {
        try{
            path = 'https://'+serverUrl.split('\\.')[1]+'.salesforce.com/'+MnADealID; 
            string url = 'https://'+serverUrl.split('\\.')[1]+'.salesforce.com/'+MnADealID; 
            PageReference pg=new PageReference(url); 
            pg.setredirect(true);            
            return pg;
        }
        catch(Exception ex){                
            apexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()); 
            ApexPages.addMessage(myMsg);
            return null; 
        }
    } 
     
    public void LoadGrid(){
        try{ 
        List<User> objUser = [Select Contact.AccountId,Contact.M_A_Admin__c,contact.DR_Admin_New__c,contact.DR_Access__c from User Where Id=:UserInfo.getUserId()]; 
        
        stringDealArray = new string[]{};
        
        if(!objUser.isEmpty()){
            string accID = '%' + accountID + '%'; 
            
            /*DR 1.3-To Restrict The Target Account-Shaharyar*/ 
            list<string> drAdminNewLst= new list<string>();
            drAdminNewStr= objUser[0].contact.DR_Admin_New__c;
            string drAccess= objUser[0].contact.DR_Access__c;
            Boolean isMNAAdmin= objUser[0].contact.M_A_Admin__c;            
            if(drAdminNewStr != '' &&  String.isNotBlank(drAdminNewStr)){
                if(drAdminNewStr.contains(';')){
                    drAdminNewLst= drAdminNewStr.split(';');
                }               
            }
            set<string> drAdminNew= new set<string>(drAdminNewLst);
           
            /*Code End-DR 1.3*/ 
            Set<Deal__c> dealSet= new Set<Deal__c>();
            dealSet= new Set<Deal__c>([Select Id, Name, Account__c, Contact_Name__c, Contact_Phone__c, Contact_Email__c, Description__c, BOX_Target_Folder_IDs__c, BOX_Folder_ID__c, BOX_Folder_Name__c, Identifier__c From Deal__c Where BOX_Folder_ID__c!= null AND Account__c =: objUser.get(0).contact.AccountId AND Identifier__c != null ]);
                                  
                if(!dealSet.isEmpty()){
                    Set<string> mnaDealIds = new Set<string>();                   
                    string dealsID = '';
                    Set<Deal__c> newDealSet = new Set<Deal__c>();
                    for(Deal__c dealObj: dealSet){ 
                        if(dealObj.BOX_Target_Folder_IDs__c!= null && dealObj.BOX_Target_Folder_IDs__c!= '' && dealObj.BOX_Target_Folder_IDs__c.contains(accountID)){                                                  
                            newDealSet.add(dealObj);                                
                        }                                              
                    } 
                    
                    if(!newDealSet.isEmpty()){                       
                        for(Deal__c dealObj: newDealSet){ 
                            /*DR1.3[2/22/2017]-Changes If User Have The Access To The Deal Only Then It Will Be Displayed On The Account Detail page-Shaharyar*/ 
                            if(isMNAAdmin || drAdminNewStr=='all' || drAccess=='all'){           
                                mnaDealIds.add('\''+dealObj.Identifier__c.substring(18,36)+'\'');  
                                                        
                                if(dealsID== null||dealsID== ''){
                                    dealsID= '\''+dealObj.Identifier__c.substring(18,36)+'\'';   
                                   
                                                          
                                }    
                                else{
                                    dealsID= dealsID +','+ '\''+dealObj.Identifier__c.substring(18,36)+'\'';
                                }
                            }
                            
                            else{
                            //DR 1.3[02/22/2017] Checks To Allow Only User(those have Access) To See The Deal Name In Account Detail Page-Shaharyar 
                                if((drAdminNewStr!='' && drAdminNewStr!= null) && String.isBlank(drAccess)){                                
                                    String mnaDealId= dealObj.Identifier__c.substring(18,36);
                                    
                                    if(drAdminNew.contains(mnaDealId)){
                                        if(dealsID== null||dealsID== ''){
                                            dealsID= '\''+dealObj.Identifier__c.substring(18,36)+'\'';  
                                           
                                        }    
                                        else{
                                            dealsID= dealsID +','+ '\''+dealObj.Identifier__c.substring(18,36)+'\'';
                                            
                                        }
                                    }
                                    
                                }
                                else{
                                    String mnaDealId= dealObj.Identifier__c.substring(18,36); 
                                    
                                    if(drAdminNew.contains(mnaDealId) || drAccess.contains(dealObj.id)){ 
                                        if(dealsID== null||dealsID== ''){
                                            dealsID= '\''+dealObj.Identifier__c.substring(18,36)+'\''; 
                                        }    
                                        else{
                                            dealsID= dealsID +','+ '\''+dealObj.Identifier__c.substring(18,36)+'\'';
                                        }                                       
                                    }
                                }
                                    
                            }       
                            //DR-1.3[02/22/2017]->Newly added Functionality ended(Shaharyar)
                        }                         
                        
                        if(string.isNotBlank(dealsID)){
                            System.debug('_____156____'+dealsID);
                            final PageReference theUrl = new PageReference('https://'+serverUrl.split('\\.')[1]+'.salesforce.com/services/data/v20.0/query/');  
                            string stringQuery='';
                            stringQuery = 'select Id,Name,RecordType.Name from '+namespace+'Deal__c where id In ('+dealsID+')'; //Old query before update                              
                            theUrl.getParameters().put('q',stringQuery);
                            HttpRequest request = new HttpRequest();
                            Http http = new Http();
                            request.setEndpoint(theUrl.getUrl());
                            request.setMethod('GET');
                            request.setHeader('Authorization', 'OAuth ' + sessionID);
                            request.setHeader('Content-Type','application/json');
                                                 
                            HttpResponse response = new HttpResponse();
                            Integer StatusCode ;
                            string Status = '';
                            string ress = '';
                            if(Test.isRunningTest()){
                                ress ='{"totalSize":9,"done":true,"records":[{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ESCINAA5"},"Id":"a051a00000ESCINAA5","Name":"Deal_testing_2nd","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETDhAAAX"},"Id":"a051a00000ETDhAAAX","Name":"Deal_manage_folder_25Nov","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSSuAAP"},"Id":"a051a00000ETSSuAAP","Name":"Deal_brahma d_24-Nov-2015","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSqFAAX"},"Id":"a051a00000ETSqFAAX","Name":"Brahmaditya_1234 mange","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSqZAAX"},"Id":"a051a00000ETSqZAAX","Name":"tst_deal manage","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSqjAAH"},"Id":"a051a00000ETSqjAAH","Name":"13_deal_manageFolder","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSr8AAH"},"Id":"a051a00000ETSr8AAH","Name":"Raj research deal","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETStVAAX"},"Id":"a051a00000ETStVAAX","Name":"Deal_brahma dt_24-Nov-2015","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}},{"attributes":{"type":"nav_mna_dev__Deal__c","url":"/services/data/v20.0/sobjects/nav_mna_dev__Deal__c/a051a00000ETSuGAAX"},"Id":"a051a00000ETSuGAAX","Name":"Brahmaditya_ManageFplder","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v20.0/sobjects/RecordType/0121a000000TzR8AAK"},"Name":"Sell-side Deal"}}]}';
                                StatusCode = 200;
                                Status = 'OK';                                              
                            }
                            else{
                                response = http.send(request);
                                StatusCode = response.getStatusCode();
                                Status = response.getStatus();
                                ress = response.getBody();
                            }    
                            if(StatusCode == 200 && Status == 'OK'){        
                                jsonWrapperDeal = new JsonParserDeal();    
                                jsonWrapperDeal = (JsonParserDeal)JSON.deserialize(ress, JsonParserDeal.class);
                                dealListSize = jsonWrapperDeal.totalsize;
                                if(dealListSize>0){ 
                                    // chane by swati to remove query from for loop use map to get identifier from deal
                                    map<String,String>mapdealidentifier = new map<String,String>();
                                    for(Deal__c dealobj1 : [Select Name ,Identifier__c from Deal__c where Identifier__c != null AND Account__c =: objUser.get(0).contact.AccountId ]){
                                         String likeIdentifier1 = dealObj1.Identifier__c.substring(18,36);
                                         System.debug('_______190likeidentifier1dealids___'+likeIdentifier1);
                                         mapdealidentifier.put(likeIdentifier1,dealObj1.Name);
                                        
                                    }
                                      
                                    for(Integer index = 0; index < dealListSize;index++){
                                        string dealRoomName = jsonWrapperDeal.records[index].Name;
                                        string dealName = jsonWrapperDeal.records[index].Name;
                                        string dealNameofMna = dealName.replace('"','&#34;').replace(',','&#44;').replace('<','&#60;').replace('>','&gt;').replace('\'','&#39;');
                                        string dealTypeName = jsonWrapperDeal.records[index].RecordType.Name==null||jsonWrapperDeal.records[index].RecordType.Name==''?'NA':jsonWrapperDeal.records[index].RecordType.Name; 
                                         string likeIdentifier = jsonWrapperDeal.records[index].Id;
                                         string dealNameOfDR = mapdealidentifier.get(likeIdentifier).replace('"','&#34;').replace(',','&#44;').replace('<','&#60;').replace('>','&gt;').replace('\'','&#39;');
                                        string dealLinkMnA ='https://'+serverUrl.split('\\.')[1]+'.salesforce.com/'+jsonWrapperDeal.records[index].Id;  
                                        string dealRoomNameDR = '<span title=\''+dealNameOfDR+'\'>' + dealNameOfDR + '</span>';
                                        string dealNameofMnaLink  = '<a href=\''+dealLinkMnA+'\'  target=\'_blank\' title=\''+dealNameofMna+'\'>' + dealNameofMna + '</a>';
                                        stringDealArray.add('[ "'+ dealRoomNameDR+'","'+ dealNameofMnaLink +'","'+ dealTypeName +'"]'); 
                                        HasAccess = true; 
                                    }
                                }
                               
                                else{
                                    HasAccess = false;
                                    displayMessage = 'No Deal Room has been built for this Account.';                           
                                }
                            } 
                        }
                        else{
                            System.debug('_____220____'+dealsID);
                         // stringDealArray.add('["<span style=\'width:240px; color: #ff0000 !important;font-weight:bold;\'>No data to display.</span>", "", ""]');//Shaharyar---To show Message In the grid
                           //commented by swati to hide no data to display message in account detail page dr1.3
                          HasAccess = true; 
                        } 
                    }
                    else{
                        HasAccess = false;
                        displayMessage = 'No Deal Room has been built for this Account.';
                    }
                }
                else{
                    HasAccess = false;
                    displayMessage = 'No Deal Room has been built for this Account.';                   
                }
            }
        }
        catch(Exception ex){            
            apexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()); 
            ApexPages.addMessage(myMsg);   
        }
    }
    
    public class JsonParserDeal{
        public Boolean done{get;set;}
        public list<records> records{get;set;}
        public Integer totalSize{get;set;}
    }
    public class RecordType{
        public String Name{get;set;}
        public attributes attributes{get;set;}
    }
    public class records{
        public String Name{get;set;}
        public String Id{get;set;}
        public attributes attributes{get;set;}
        public RecordType RecordType{get;set;}
    }
    public class attributes{
        public String type{get;set;}
        public String url{get;set;}
    }
}