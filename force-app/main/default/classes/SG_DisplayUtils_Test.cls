/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SG_DisplayUtils_Test 
{

    static testmethod void testDefaultIfEmpty(){
        //test: global static String defaultIfEmpty(String str, String defaultStr) {
        assertDefaultIfEmpty(null, 'NULL', 'NULL');
        assertDefaultIfEmpty('', 'NULL', 'NULL');
        assertDefaultIfEmpty('bat', 'NULL', 'bat');
    }    
    
    static void assertDefaultIfEmpty(String str, String defaultStr, String expected){
        String actual = SG_DisplayUtils.defaultIfEmpty(str,defaultStr);
        System.assert(actual==expected, 'SG_DisplayUtils.defaultIfEmpty(\'' + str + '\',\'' + defaultStr + '\') returned \'' 
            + actual + '\'; expected \'' + expected + '\'');
    }
    
	static testmethod void testEquals(){
        //test: global static Boolean equals(String str1, String str2) {
        assertEquals(null,     null,     true);
        assertEquals(null,     'abc',     false);
        assertEquals('abc', null,     false);
        assertEquals('abc', 'abc',     true);
        assertEquals('abc', 'ABC',     false);
    }    
    
    static void assertEquals(String str1, String str2, Boolean expected){
        Boolean actual = SG_DisplayUtils.equals(str1,str2); 
        System.assert(actual==expected, 'SG_DisplayUtils.equals(\'' + str1 + '\',\'' + str2 + '\') returned ' + actual);
    }

    static testmethod void testEqualsIgnoreCase(){
        //test: global static Boolean equalsIgnoreCase(String str1, String str2) {
        assertEqualsIgnoreCase(null,     null,     true);
        assertEqualsIgnoreCase(null,     'abc',     false);
        assertEqualsIgnoreCase('abc',     null,     false);
        assertEqualsIgnoreCase('abc',     'abc',     true);
        assertEqualsIgnoreCase('abc',     'ABC',     true);
    }    
    
    static void assertEqualsIgnoreCase(String str1, String str2, Boolean expected){
        Boolean actual = SG_DisplayUtils.equalsIgnoreCase(str1,str2);
        System.assert(actual==expected, 'SG_DisplayUtils.equalsIgnoreCase(\'' + str1 + '\',\'' + str2 + '\') returned ' + actual);
    }
        
    static testmethod void testLength(){
        assertLength(null,         0);
        assertLength('',        0);
        assertLength(' ',        1);
        assertLength('bob',        3);
        assertLength('  bob  ',    7);
    }    
    
    static void assertLength(String str, Integer expected){
        Integer actual = SG_DisplayUtils.length(str);
        System.assert(actual==expected, 'SG_DisplayUtils.length(\'' + str + '\') returned ' + actual);
    }        

    static testmethod void testTrim(){
        assertTrim(null, null);
        assertTrim('', '');
        assertTrim('a', 'a');
        assertTrim('\n', '');
        assertTrim('   ', '');
        List<String> strList = new List<String>{'foo ','bar '};
        Set<String> strSet = new Set<String>{'foo ','bar '};
        SG_DisplayUtils.trimAll(strList);
        SG_DisplayUtils.trimAll(strSet);
    }
    
    static void assertTrim(String str, String expected){
        String actual = SG_DisplayUtils.trim(str);
        System.assert(actual==expected, 'SG_DisplayUtils.trim(\'' + str + '\') returned [' + actual + '], expected [' + expected + ']');
    }
        
    static testmethod void testLeftPadThreeArgs(){
        //test: global static String leftPad(String str, Integer size, String padStr) {
        assertLeftPadThreeArgs(null,     -1, null,     null);
        assertLeftPadThreeArgs('',         3,     'z',     'zzz'); 
        assertLeftPadThreeArgs('bat',     3,     'yz',     'bat');
        assertLeftPadThreeArgs('bat',     5,     'yz',     'yzbat');
        assertLeftPadThreeArgs('bat',     8,     'yz',     'yzyzybat');
        assertLeftPadThreeArgs('bat',     1,     'yz',     'bat');
        assertLeftPadThreeArgs('bat',     -1, 'yz',     'bat');
        assertLeftPadThreeArgs('bat',     5,     null,     '  bat');
        assertLeftPadThreeArgs('bat',     5,     '',     '  bat');
        SG_DisplayUtils.leftPadZeros('bat',5);
    }    

    static void assertLeftPadThreeArgs(String str, Integer size, String padStr, String expected){
        String actual = SG_DisplayUtils.leftPad(str,size,padStr);
        System.assert(actual==expected, 'SG_DisplayUtils.leftPad(\'' + str + '\',' 
            + size + ',\'' + padStr + '\') returned \'' + actual + '\'; expected \'' + expected + '\'');
    }
    
    static testmethod void testRightPadThreeArgs(){
        //test: global static String rightPad(String str, Integer size, String padStr) {
        assertRightPadThreeArgs(null,     -1, null,     null);
        assertRightPadThreeArgs('',     3,     '',     '   ');
        assertRightPadThreeArgs('',     3,     'z',     'zzz');
        assertRightPadThreeArgs('bat',     3,     'z',     'bat');
        assertRightPadThreeArgs('bat',     5,     'z',     'batzz');
        assertRightPadThreeArgs('bat',     1,     'z',     'bat');
        assertRightPadThreeArgs('bat',     -1,    'z',     'bat');
        assertRightPadThreeArgs('bat',     6,    'abcd', 'batabc');        
    }    
    
    static void assertRightPadThreeArgs(String str, Integer size, String padStr, String expected){
        String actual = SG_DisplayUtils.rightPad(str,size,padStr);
        System.assert(actual==expected, 'SG_DisplayUtils.rightPad(\'' + str + '\',' 
            + size + ',\'' + padStr + '\') returned \'' + actual + '\'; expected \'' + expected + '\'');
    }
    
    static testmethod void testLowerCase(){
        assertLowerCase(null, null);
        assertLowerCase('ABC', 'abc');
        assertLowerCase('abc', 'abc');
        assertLowerCase('aBc', 'abc');
    }    
    
    static void assertLowerCase(String str, String expected){
        String actual = SG_DisplayUtils.lowerCase(str);
        System.assert(actual==expected, 'SG_DisplayUtils.lowerCase(\'' + str + '\') returned ' + actual);
    }
    
    static testmethod void testUpperCase(){
        assertUpperCase(null, null);
        assertUpperCase('ABC', 'ABC');
        assertUpperCase('abc', 'ABC');
        assertUpperCase('aBc', 'ABC');
    }    
    
    static void assertUpperCase(String str, String expected){
        String actual = SG_DisplayUtils.upperCase(str);
        System.assert(actual==expected, 'SG_DisplayUtils.upperCase(\'' + str + '\') returned ' + actual);
    }        
    
    static testMethod void runThroughErrorMessage() 
    {
        SG_DisplayUtils.addError('Fake Error Message');
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean found = false;
        for(ApexPages.Message msg:msgs)
        {
            if(msg.getDetail().contains('Fake Error Message')) found = true;
        }
        System.assert(found,msgs);
    }
    
    static testMethod void runThroughInfoMessage()
    {       
        SG_DisplayUtils.addInfo('Fake Info Message');
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean found = false;
        for(ApexPages.Message msg:msgs)
        {
            if(msg.getDetail().contains('Fake Info Message')) found = true;
        }
        System.assert(found,msgs);
    }   
        
    static testMethod void runThroughAllMethods()
    {        
        
        //SG_DisplayUtils.debug('SG_DisplayUtils_Test', 'runThroughAllMethods', 'variableName', 'fake message');
        //Nothing to assert!
        
        //SG_DisplayUtils.debug('SG_DisplayUtils_Test', 'fake message');
        //Nothing to assert!
        
        SG_DisplayUtils.debug('SG_DisplayUtils_Test', 'runThroughAllMethods', 'msg');
        //Nothing to assert!
        
        SG_DisplayUtils.debug('SG_DisplayUtils_Test', 'runThroughAllMethods', new SG_DisplayUtils.DisplayUtilsException('test method exception'));
        
        Database.Saveresult result = Database.update(new Account(id='001e000000E08Wf'), false);
                        
        String formattedError = SG_DisplayUtils.errorToString(result.getErrors()[0]);
        System.assert(formattedError.contains('Error with status code'),formattedError);
                
        SG_DisplayUtils.exceptionToString('SG_DisplayUtils_Test', new SG_DisplayUtils.DisplayUtilsException('test method exception'));
        
        SG_DisplayUtils.getFormattedErrorMessage('ErrorMessage, FIELD_CUSTOM_VALIDATION_EXCEPTION, Test : Test', true);
                       
        SG_DisplayUtils.getFormattedErrorMessage('ErrorMessage');
        
        SG_DisplayUTils.stripStatusCode('ErrorMessage', null);
        SG_DisplayUTils.stripStatusCode('ErrorMessage', 'FIELD_CUSTOM_VALIDATION_EXCEPTION');        
    }
    
    	private static testmethod void testAddInfo(){
		//test: global static void addInfo(String message){
		SG_DisplayUtils.assertNoInfoMessagesExist();
		SG_DisplayUtils.addInfo('test');
		SG_DisplayUtils.assertInfoMessagesExist();
	}

	private static testmethod void testAddWarning(){
		//test: global static void addWarning(String message){
		SG_DisplayUtils.assertNoWarningMessagesExist();
		SG_DisplayUtils.addWarning('test');
		SG_DisplayUtils.assertWarningMessagesExist();
	}

	private static testmethod void testAddError(){
		//test: global static void adddError(String message){
		SG_DisplayUtils.assertNoErrorMessagesExist();
		SG_DisplayUtils.addError('test');
		SG_DisplayUtils.assertErrorMessagesExist();
	}

	private static testmethod void testAddFatal(){
		//test: global static void addFatal(String message){
		SG_DisplayUtils.assertNoFatalMessagesExist();
		SG_DisplayUtils.addFatal('test');
		SG_DisplayUtils.assertFatalMessagesExist();
	}

	private static testmethod void testRedirect(){
		//test: global static PageReference redirect(String url){
		PageReference ref = SG_DisplayUtils.redirect( '/abc123' );
		System.assertNotEquals( null, ref );
		System.assertEquals( '/abc123', ref.getUrl() );
		System.assertEquals( true, ref.getRedirect() );
	}
	
	private static testmethod void testParam(){
		//test: global static String param(String param){
		SG_DisplayUtils.putParam( 'test1', 'value1' );
		//ApexPages.currentPage().getParameters().put( 'test1', 'value1' );
		System.assertEquals( 'value1', SG_DisplayUtils.getParam( 'test1' ) );
	}
	
	private static testmethod void testMultipleParam(){
		//test: global static String param(String param){
		ApexPages.currentPage().getParameters().put('test1','value1');
		ApexPages.currentPage().getParameters().put('test2','value2');
		ApexPages.currentPage().getParameters().put('test3',null);
		ApexPages.currentPage().getParameters().put('test4','');
		ApexPages.currentPage().getParameters().put('test5','  ');
		Map<String,String> retValue = SG_DisplayUtils.getParameters();
		System.assertNotEquals(null,retValue);
		System.assertEquals(5,retValue.size());
		System.assert(retValue.containsKey('test1'));
		System.assert(retValue.containsKey('test2'));
		System.assert(retValue.containsKey('test3'));
		System.assert(retValue.containsKey('test4'));
		System.assert(retValue.containsKey('test5'));
	}

	private static testmethod void testGetErrorMessages(){
		//test: global static ApexPages.Message[] getErrorMessages(){
		System.assertEquals(true,SG_DisplayUtils.getErrorMessages().isEmpty());
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals(false,SG_DisplayUtils.getErrorMessages().isEmpty());
		SG_DisplayUtils.addError('testa'); 
		System.assertEquals(false,SG_DisplayUtils.getErrorMessages().isEmpty());
	}
	
	private static testmethod void testGetErrorMessagesOnly(){
		//test: global static ApexPages.Message[] getErrorMessagesOnly(){
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals(true,SG_DisplayUtils.getErrorMessagesOnly().isEmpty());
		SG_DisplayUtils.addError('testa'); 
		System.assertEquals(false,SG_DisplayUtils.getErrorMessagesOnly().isEmpty());
	}
	
	private static testmethod void testMessagesToStringNoArg(){
		//test: global static String messagesToString(){
		System.assertEquals('{empty}',
			SG_DisplayUtils.messagesToString());
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals('{ApexPages.Message[0]: (summary=testb,componentLabel=null,severity=INFO,detail=testb)}',
			SG_DisplayUtils.messagesToString());
	}
	
	private static testmethod void testMessagesToStringOneArg(){
		//test: global static String messagesToString(ApexPages.Message[] messages){
		System.assertEquals('null',SG_DisplayUtils.messagesToString(null));
		SG_DisplayUtils.addError('testb'); 
		SG_DisplayUtils.addError('testc'); 
		System.assertEquals('{ApexPages.Message[0]: (summary=testb,componentLabel=null,severity=ERROR,detail=testb); ApexPages.Message[1]: (summary=testc,componentLabel=null,severity=ERROR,detail=testc)}',
			SG_DisplayUtils.messagesToString(SG_DisplayUtils.getErrorMessages()));
	}
	
	private static testmethod void testGetMessagesAtLevelScenario1(){
		//test: global static ApexPages.Message[] getMessagesAtLevel(ApexPages.Severity level,Boolean includeParents){
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals(true,SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR,false).isEmpty());
		SG_DisplayUtils.addError('testa'); 
		System.assertEquals(false,SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR,false).isEmpty());
	}

	private static testmethod void testGetMessagesAtLevelScenario2(){
		//test: global static ApexPages.Message[] getMessagesAtLevel(ApexPages.Severity level,Boolean includeParents){
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals(true,SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR,false).isEmpty());
	}

	private static testmethod void testGetMessagesAtLevelScenario3(){
		//test: global static ApexPages.Message[] getMessagesAtLevel(ApexPages.Severity level,Boolean includeParents){
		SG_DisplayUtils.addInfo('testb'); 
		System.assertEquals(false,SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR,true).isEmpty());
	}

	private static testmethod void testIsMessageAtLevelOrHigher(){
		//test: global static Boolean isMessageAtLevelOrHigher(ApexPages.Message message, ApexPages.Severity level){
		assertIsMessageAtLevelOrHigher(null,null,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,null,false);
		assertIsMessageAtLevelOrHigher(null,ApexPages.severity.INFO,false);

		SG_DisplayUtils.assertNoConfirmMessagesExist();

		assertIsMessageAtLevelOrHigher(ApexPages.severity.CONFIRM,ApexPages.severity.CONFIRM,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.CONFIRM,ApexPages.severity.INFO,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.CONFIRM,ApexPages.severity.WARNING,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.CONFIRM,ApexPages.severity.ERROR,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.CONFIRM,ApexPages.severity.FATAL,true);

		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,ApexPages.severity.CONFIRM,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,ApexPages.severity.INFO,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,ApexPages.severity.WARNING,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,ApexPages.severity.ERROR,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.INFO,ApexPages.severity.FATAL,true);

		assertIsMessageAtLevelOrHigher(ApexPages.severity.WARNING,ApexPages.severity.CONFIRM,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.WARNING,ApexPages.severity.INFO,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.WARNING,ApexPages.severity.WARNING,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.WARNING,ApexPages.severity.ERROR,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.WARNING,ApexPages.severity.FATAL,true);

		assertIsMessageAtLevelOrHigher(ApexPages.severity.ERROR,ApexPages.severity.CONFIRM,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.ERROR,ApexPages.severity.INFO,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.ERROR,ApexPages.severity.WARNING,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.ERROR,ApexPages.severity.ERROR,true);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.ERROR,ApexPages.severity.FATAL,true);

		assertIsMessageAtLevelOrHigher(ApexPages.severity.FATAL,ApexPages.severity.CONFIRM,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.FATAL,ApexPages.severity.INFO,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.FATAL,ApexPages.severity.WARNING,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.FATAL,ApexPages.severity.ERROR,false);
		assertIsMessageAtLevelOrHigher(ApexPages.severity.FATAL,ApexPages.severity.FATAL,true);

		ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Test' ) );
		SG_DisplayUtils.assertConfirmMessagesExist();
	}

	private static void assertIsMessageAtLevelOrHigher(ApexPages.Severity messageLevel, ApexPages.Severity level, Boolean expected){
		Boolean actual = SG_DisplayUtils.isMessageAtLevelOrHigher((messageLevel==null ? null : new ApexPages.message(messageLevel,'test')),level);
		System.assert(actual==expected,'SG_DisplayUtils.isMessageAtLevelOrHigher(' + (messageLevel == null ? 'null' : ''+messageLevel) + ',' + level + ') returned ' + actual);
	}
	
	private static testmethod void testHasErrorMessages(){
		//test: global static Boolean hasErrorMessages(){
		System.assertEquals(false,SG_DisplayUtils.hasErrorMessages());
		SG_DisplayUtils.addError('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessages());
		SG_DisplayUtils.addInfo('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessages());
		SG_DisplayUtils.addFatal('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessages());
	}
	
	private static testmethod void testHasErrorMessagesOnly(){
		//test: global static Boolean hasErrorMessagesOnly()
		System.assertEquals(false,SG_DisplayUtils.hasErrorMessagesOnly());
		SG_DisplayUtils.addError('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessagesOnly());
		SG_DisplayUtils.addInfo('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessagesOnly());
		SG_DisplayUtils.addFatal('x');
		System.assertEquals(true,SG_DisplayUtils.hasErrorMessagesOnly());
	}

static testMethod void testStrings()
{
        /* Test hasChanged */
        Account a = new Account( name='foo');
        Account b;
        System.assertEquals( true, SG_DisplayUtils.hasChanged( a, b, 'name'));
        b = new Account( name='foo');
        System.assertEquals( false, SG_DisplayUtils.hasChanged( a, b, 'name'));

        /* Test parseStringIntoSet() */
        String incomingString = '1, 2, 3';
        String separator = ', ';
        Set<String> stringSet = SG_DisplayUtils.parseIncomingStringIntoSet(incomingString, separator);
        System.assertEquals( 3, stringSet.size() );

        /* Test formattedIdList */
        Id firstId = UserInfo.getUserId();
        Id secondId = UserInfo.getProfileId();
        Set<Id> idSet = new Set<Id>();
        idSet.add( firstId );
        idSet.add( secondId );
        String formattedStr = SG_DisplayUtils.getFormattedIdList( idSet );
        System.assertEquals( 2, SG_DisplayUtils.parseIncomingStringIntoSet(formattedStr, ',').size() );

        Set<String> formatStringSet = new Set<String>{'1', '2', '3'};
        String formattedStringStr = SG_DisplayUtils.getFormattedStringList(formatStringSet);
        System.assertEquals( 3, SG_DisplayUtils.parseIncomingStringIntoSet( formattedStringStr, ',').size() );
}
}