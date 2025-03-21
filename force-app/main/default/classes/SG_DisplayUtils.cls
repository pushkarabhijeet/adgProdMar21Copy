/**********************************************************************
* Name:   	SG_DisplayUtils
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	04 MAR 2013
* ======================================================
* ======================================================
* Purpose: The purpose of this class is to help with the diplay of errors, and exceptions, particularly on Visualforce pages                                                            
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	04 MAR 2013     RD			Initial Development           
*   
***********************************************************************/

public class SG_DisplayUtils
{

    public static Boolean canFireTrigger(TriggerOperation type, List<TriggerOperation> allowedTypes, Boolean isRecursive )
    {
        Boolean canFire = false;
        System.debug(LoggingLevel.WARN, '---> canFireTrigger type: ' + type );
        System.debug(LoggingLevel.WARN, '---> canFireTrigger allowedTypes: ' + allowedTypes );
        System.debug(LoggingLevel.WARN, '---> canFireTrigger isRecursive: ' + isRecursive );

        if ( !isRecursive && type != null && allowedTypes != null && allowedTypes.contains(type))
        {
            System.debug(LoggingLevel.WARN, '---> allowed type...');
            canFire = true;
        }

        return canFire;
    }

    /* STRING UTILS */
    public static String defaultIfEmpty(String str, String defaultStr)
    {
        return String.isEmpty(str) ? defaultStr : str;
    }

    public static Boolean equals(String str1, String str2)
    {
        return str1 == null ? str2 == null : str1.equals(str2);
    }

    public static Boolean equalsIgnoreCase(String str1, String str2)
    {
        return str1 == null ? str2 == null : str1.equalsIgnoreCase(str2);
    }

    public static String leftPadZeros(String str, Integer size)
    {
        return leftPad(str, size, '0');
    }

    public static String leftPad(String str, Integer size, String padStr)
    {
        if (str == null)
        {
            return null;
        }
        if (String.isEmpty(padStr))
        {
            padStr = ' ';
        }
        Integer padLen = padStr.length();
        Integer strLen = str.length();
        Integer padCharCount = size - strLen;
        if (padCharCount <= 0)
        {
            return str;
        }
        if (padCharCount == padLen)
        {
            return padStr + str;
        }
        else if (padCharCount < padLen)
        {
            return padStr.substring(0, padCharCount) + str;
        }
        else
        {
            String padding = '';
            for (Integer i = 0; i < padCharCount; i++)
            {
                padding += padStr.substring(Math.mod(i, padLen), Math.mod(i, padLen) + 1);
            }
            return padding + str;
        }
    }

    public static Integer length(String str)
    {
        return str == null ? 0 : str.length();
    }

    public static String rightPad(String str, Integer size, String padStr)
    {
        if (str == null)
        {
            return null;
        }
        if (String.isEmpty(padStr))
        {
            padStr = ' ';
        }
        Integer padLen = padStr.length();
        Integer strLen = str.length();
        Integer padCharCount = size - strLen;
        if (padCharCount <= 0)
        {
            return str; // returns original String when possible
        }

        if (padCharCount == padLen)
        {
            return str + padStr;
        }
        else if (padCharCount < padLen)
        {
            return str + padStr.substring(0, padCharCount);
        }
        else
        {
            String padding = '';
            for (Integer i = 0; i < padCharCount; i++)
            {
                padding += padStr.substring(Math.mod(i, padLen), Math.mod(i, padLen) + 1);
            }
            return str + padding;
        }
    }

    public static String trim(String str)
    {
        return str == null ? null : str.trim();
    }

    public static List<String> trimAll(List<String> aList)
    {
        List<String> returnValue = null;
        if (aList != null)
        {
            returnValue = new List<String>();
            if (aList.size() > 0)
            {
                for (String value : aList)
                {
                    returnValue.add(trim(value));
                }
            }
        }
        return returnValue;
    }

    public static Set<String> trimAll(Set<String> aList)
    {
        Set<String> returnValue = null;
        if (aList != null)
        {
            returnValue = new Set<String>();
            if (aList.size() > 0)
            {
                for (String value : aList)
                {
                    returnValue.add(trim(value));
                }
            }
        }
        return returnValue;
    }

    public static String lowerCase(String str)
    {
        return str == null ? null : str.toLowerCase();
    }

    public static String upperCase(String str)
    {
        return str == null ? null : str.toUpperCase();
    }

    /* DEBUG METHODS */

    public static void debug(Exception exp)
    {
        debug(null, null, exp, null);
    }

    public static void debug(String msg)
    {
        debug(null, null, msg, null);
    }

    public static void debug(String apexClassName, String apexMethodName, Exception exp)
    {
        debug(apexClassName, apexMethodName, exp, null);
    }

    public static void debug(String apexClassName, String apexMethodName, Exception exp, System.Logginglevel logLevel)
    {
        String msg = exceptionToString(apexClassName, exp);
        debug(apexClassName, apexMethodName, msg, logLevel);
    }

    public static void debug(String apexClassName, String apexMethodName, String msg)
    {
        debug(apexClassName, apexMethodName, msg, null);
    }

    public static void debug(String apexClassName, String apexMethodName, String msg, System.Logginglevel logLevel)
    {
        String formattedDebugStr = '@@@SG: ';

        if (apexClassName != null)
        {
            formattedDebugStr += apexClassName + ': ';
        }

        if (apexMethodName != null)
        {
            formattedDebugStr += apexMethodName + ': ';
        }

        formattedDebugStr += msg;

        // TODO only output if apexClassName is in a Custom Setting
        if (logLevel != null)
        {
            System.debug(logLevel, formattedDebugStr);
        }
        else
        {
            System.debug(formattedDebugStr);
        }
    }

    public static void debugLimit()
    {
        System.debug(
                '\n' + '@@@SG: ##################################################################'
                        + '\n' + '@@@SG: Limits:'
                        + '\n' + '@@@SG: ##################################################################'
                        + '\n' + '@@@SG: AggregateQueries: ' + Limits.getAggregateQueries() + ' of ' + Limits.getLimitAggregateQueries()
                        + '\n' + '@@@SG: Callouts: ' + Limits.getCallouts() + ' of ' + Limits.getLimitCallouts()
                        + '\n' + '@@@SG: DMLRows: ' + Limits.getDMLRows() + ' of ' + Limits.getLimitDMLRows()
                        + '\n' + '@@@SG: DMLStatements: ' + Limits.getDMLStatements() + ' of ' + Limits.getLimitDMLStatements()
                        + '\n' + '@@@SG: EmailInvocations: ' + Limits.getEmailInvocations() + ' of ' + Limits.getLimitEmailInvocations()
                        + '\n' + '@@@SG: FindSimilarCalls: ' + Limits.getFindSimilarCalls() + ' of ' + Limits.getLimitFindSimilarCalls()
                        + '\n' + '@@@SG: FutureCalls: ' + Limits.getFutureCalls() + ' of ' + Limits.getLimitFutureCalls()
                        + '\n' + '@@@SG: HeapSize: ' + Limits.getHeapSize() + ' of ' + Limits.getLimitHeapSize()
                        + '\n' + '@@@SG: Queries: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries()
                        + '\n' + '@@@SG: QueryRows: ' + Limits.getQueryRows() + ' of ' + Limits.getLimitQueryRows()
                        + '\n' + '@@@SG: RunAs: ' + Limits.getRunAs() + ' of ' + Limits.getLimitRunAs()
                        + '\n' + '@@@SG: SavepointRollbacks: ' + Limits.getSavepointRollbacks() + ' of ' + Limits.getLimitSavepointRollbacks()
                        + '\n' + '@@@SG: Savepoints: ' + Limits.getSavepoints() + ' of ' + Limits.getLimitSavepoints()
                        + '\n' + '@@@SG: SoslQueries: ' + Limits.getSoslQueries() + ' of ' + Limits.getLimitSoslQueries()
                        + '\n'
        );
    }

    /* VISUALFORCE PAGE METHODS */
/**
 * Adds an ERROR severity message to an Apex Page, but makes sure Validation Rules are pretty.
 * results = Database.update(blah,false);
 *
 * SG_DisplayUtils.addError(SG_DisplayUtils.errorToPrettyString(results.Errors()[0]) + '. Please call your Sys Admin');
 * try{ update blah; } catch (Exception exp) { SG_DisplayUtils.addError(exp.getMessage()); }
 */

    public static void addError(String msg)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'addError', msg);
        if (msg != null)
        {
            msg = getFormattedErrorMessage(msg, false);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, msg));
        }
    }

    /**
    * Adds an INFO severity message to an Apex Page, but makes sure Validation Rules are pretty.
    */
    public static void addInfo(String msg)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'addStatus', msg);

        if (msg != null)
        {
            msg = getFormattedErrorMessage(msg, false);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, msg));
        }
    }

    /**
    * Adds an WARNING severity message to an Apex Page, but makes sure Validation Rules are pretty.
    */
    public static void addWarning(String msg)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'addStatus', msg);

        if (msg != null)
        {
            msg = getFormattedErrorMessage(msg, false);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, msg));
        }
    }

    /**
    * Adds an CONFIRM severity message to an Apex Page, but makes sure Validation Rules are pretty.
    */
    public static void addConfirm(String msg)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'addStatus', msg);

        if (msg != null)
        {
            msg = getFormattedErrorMessage(msg, false);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, msg));
        }
    }

    /**
    * Adds an FATAL severity message to an Apex Page, but makes sure Validation Rules are pretty.
    */
    public static void addFatal(String msg)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'addStatus', msg);

        if (msg != null)
        {
            msg = getFormattedErrorMessage(msg, false);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, msg));
        }
    }


/**
 * Returns a String which is a well formated exception. 
 *  Example "Exception of type DMLException occured on line 23. Exception message: You do not have permission to insert."
 * @param apexClassName	The name of the Apex class where the exception was thrown.
 * @param exp    The exception that was thrown
 */
    public static String exceptionToString(String apexClassName, Exception exp)
    {
        if (exp == null) return null;

        String formattedException = 'Exception of type ' + exp.getTypeName();
        if (apexClassName != null)
        {
            formattedException += ' occured in class ' + apexClassName;
        }

        formattedException += ' on line ' + exp.getLineNumber() + '. Exception message: ' + exp.getMessage();

        formattedException += '\n';

        formattedException += exp.getStackTraceString();

        //SG_DisplayUtils.debug('SG_DisplayUtils','exceptionToString','formattedException',formattedException);
        return formattedException;
    }

/**
 * @param theError    The Error to be formated
 */
    public static String errorToString(Database.Error theError)
    {
        if (theError == null) return null;
        // It appears we don't have to rely on a static list
        return 'Error with status code ' + theError.getStatusCode() + ' occured. Error message: ' + errorToPrettyString(theError);
    }

    public static String errorToPrettyString(Database.Error theError)
    {
        if (theError == null) return null;

        String errorMsg = stripStatusCode(theError.getMessage(), statusCodeToName.get(theError.getStatusCode()));

        // It appears we don't have to rely on a static list
        return errorMsg.replaceAll('&quot;', '"');
    }


/**
 * @param errorMessage	The error message from an exception OR Database.Error, strips out the text of
 * the statusCode (for example: 'FIELD_CUSTOM_VALIDATION_EXCEPTION') which isn't pretty.
 */
    public static String getFormattedErrorMessage(String errorMessage)
    {
        return getFormattedErrorMessage(errorMessage, false);
    }

/**
 * @param errorMessage	The error message from an exception OR Database.Error, strips out the text of
 * the statusCode (for example: 'FIELD_CUSTOM_VALIDATION_EXCEPTION') which isn't pretty.
 */
    public static String getFormattedErrorMessage(String errorMessage, Boolean allStatusCodes)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'getFormattedErrorMessage', errorMessage);

        String formattedErrorMsg;
        if (!allStatusCodes)
        {
            formattedErrorMsg = stripStatusCode(errorMessage, 'FIELD_CUSTOM_VALIDATION_EXCEPTION');
        }
        else
        {
            for (String statusCode : statusCodeToName.values())
            {
                formattedErrorMsg = stripStatusCode(errorMessage, statusCode);
                if (errorMessage.indexOf(statusCode) > -1) break; // After one status code is found, just break
            }
        }

        SG_DisplayUtils.debug('SG_DisplayUtils', 'getFormattedErrorMessage', formattedErrorMsg);
        return formattedErrorMsg;
    }

    public static String stripStatusCode(String errorMessage, String statusCode)
    {
        SG_DisplayUtils.debug('SG_DisplayUtils', 'stripStatusCode', errorMessage);
        SG_DisplayUtils.debug('SG_DisplayUtils', 'stripStatusCode', statusCode);

        if (statusCode == null)
        {
            statusCode = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
        }
        String statusCodeLocator = statusCode + ', ';

        String formattedErrorMsg = errorMessage;

        if (errorMessage != null && errorMessage.indexOf(statusCodeLocator) > -1)
        {
            formattedErrorMsg = errorMessage.substring(errorMessage.indexOf(statusCodeLocator) + 35, errorMessage.indexOf(':', errorMessage.indexOf(statusCodeLocator)));
            formattedErrorMsg = String.escapeSingleQuotes(formattedErrorMsg);
            formattedErrorMsg = formattedErrorMsg.replace('&quot;', '\'');
            formattedErrorMsg = formattedErrorMsg.replace('&lt;', '<');
        }
        SG_DisplayUtils.debug('SG_DisplayUtils', 'stripStatusCode', formattedErrorMsg);
        return formattedErrorMsg;
    }

    // Only used for testMethods
    public class DisplayUtilsException extends Exception
    {
    }

        public static Set<String> parseIncomingStringIntoSet( String incomingString )
	{
		return parseIncomingStringIntoSet( incomingString, ',' );
	}

	public static Set<String> parseIncomingStringIntoSet( String incomingString, String separator )
	{
		Set<String> stringSet = new Set<String>();
		List<String> stringList = new List<String>();

		if ( incomingString != null )
		{
			stringList = incomingString.split( separator );
			System.debug('stringList: ' + stringList);
			for ( String s : stringList )
			{
				System.debug('adding string to Set: ' + s);
				stringSet.add( s.trim() );
			}
		}

		return stringSet;
	}

	public static String getFormattedIdList( Set<Id> incomingIds )
	{
		String formattedStr = null;
		if ( incomingIds != null )
		{
			formattedStr = '';
			String sep = '';
			for ( Id id : incomingIds )
			{
				formattedStr = formattedStr + sep + '\'' + id + '\'';
				sep = ', ';
			}
		}
		return formattedStr;
	}


	public static String getFormattedStringList( Set<String> incomingStrs )
	{
		String formattedStr = null;
		if ( incomingStrs != null )
		{
			formattedStr = '';
			String sep = '';
			for ( String str : incomingStrs )
			{
				formattedStr = formattedStr + sep + '\'' + str + '\'';
				sep = ', ';
			}
		}
		return formattedStr;
	}

	public static String getDayOfWeekFromDate( Date d )
	{
		String day;
		if( d != null )
		{
			DateTime dt = Datetime.newInstance( d.year(), d.month(), d.day() );
			day = getDayOfWeekFromDateTime( dt );
		}
		return day;
	}

	public static String getDayOfWeekFromDateTime( DateTime dt )
	{
		String day;
		if ( dt != null )
		{
			day = dt.format('EEEE');
		}

		return day;
	}

	public static Boolean hasChanged(SObject oldRecord, SObject newRecord, String fieldName)
	{
		if ( oldRecord == null || newRecord == null )
		{
			return true;
		}

		Object oldVal = oldRecord.get(fieldName);
		Object newVal = newRecord.get(fieldName);
		return (oldVal != newVal);
	}

//From Apex-Lang Page Utils
    public static PageReference redirect(String url)
    {
        PageReference pageRef = new PageReference(url);
        pageRef.setRedirect(true);
        return pageRef;
    }

    public static String getParam(String param)
    {
        return ApexPages.currentPage().getParameters().get(param);
    }

    public static Map<String, String> getParameters()
    {
        return ApexPages.currentPage().getParameters();
    }

    public static String putParam(String param, String value)
    {
        ApexPages.currentPage().getParameters().put(param, value);
        return value;
    }

    public static ApexPages.Message[] getMessagesAtLevel(ApexPages.Severity level, Boolean includeParents)
    {
        final ApexPages.Message[] allMessages = ApexPages.getMessages();
        final List<ApexPages.Message> filtered = new List<ApexPages.Message>();
        if (allMessages != null && allMessages.size() > 0)
        {
            for (ApexPages.Message message : allMessages)
            {
                if (message.getSeverity() == level || (includeParents && isMessageAtLevelOrHigher(message, level)))
                {
                    filtered.add(message);
                }
            }
        }
        return filtered;
    }

    public static ApexPages.Message[] getErrorMessages()
    {
        return SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR, true);
    }

    public static Boolean hasErrorMessages()
    {
        final ApexPages.Message[] errorMessages = getErrorMessages();
        return errorMessages != null && errorMessages.size() > 0;
    }

    public static ApexPages.Message[] getErrorMessagesOnly()
    {
        return SG_DisplayUtils.getMessagesAtLevel(ApexPages.Severity.ERROR, false);
    }

    public static Boolean hasErrorMessagesOnly()
    {
        final ApexPages.Message[] errorMessagesOnly = getErrorMessagesOnly();
        return errorMessagesOnly != null && errorMessagesOnly.size() > 0;
    }

    public static String messagesToString()
    {
        return messagesToString(ApexPages.getMessages());
    }

    public static String messagesToString(ApexPages.Message[] messages)
    {
        if (messages == null)
        {
            return 'null';
        }
        if (messages.size() <= 0)
        {
            return '{empty}';
        }
        String returnString = '';
        for (Integer i = 0; i < messages.size(); i++)
        {
            if (i != 0)
            {
                returnString += '; ';
            }
            returnString += 'ApexPages.Message[';
            returnString += i;
            returnString += ']: (summary=';
            returnString += messages[i].getSummary();
            returnString += ',componentLabel=';
            returnString += messages[i].getComponentLabel();
            returnString += ',severity=';
            returnString += messages[i].getSeverity();
            returnString += ',detail=';
            returnString += messages[i].getDetail();
            returnString += ')';
        }
        return '{' + returnString + '}';
    }

    public static Boolean isMessageAtLevelOrHigher(ApexPages.Message message, ApexPages.Severity level)
    {
        if (level == null || message == null)
        {
            return false;
        }
        ApexPages.Severity msgLevel = message.getSeverity();
        while (true)
        {
            if (level == msgLevel)
            {
                return true;
            }
            if (msgLevel == ApexPages.Severity.CONFIRM)
            {
                msgLevel = ApexPages.Severity.WARNING;
            }
            else if (msgLevel == ApexPages.Severity.INFO)
            {
                msgLevel = ApexPages.Severity.WARNING;
            }
            else if (msgLevel == ApexPages.Severity.WARNING)
            {
                msgLevel = ApexPages.Severity.ERROR;
            }
            else if (msgLevel == ApexPages.Severity.ERROR)
            {
                msgLevel = ApexPages.Severity.FATAL;
            }
            else
            {
                break;
            }
        }
        return false;
    }

    public static void assertConfirmMessagesExist()
    {
        assertMessagesAtLevelExist(ApexPages.Severity.CONFIRM, true);
    }
    public static void assertInfoMessagesExist()
    {
        assertMessagesAtLevelExist(ApexPages.Severity.INFO, true);
    }
    public static void assertWarningMessagesExist()
    {
        assertMessagesAtLevelExist(ApexPages.Severity.WARNING, true);
    }
    public static void assertErrorMessagesExist()
    {
        assertMessagesAtLevelExist(ApexPages.Severity.ERROR, true);
    }
    public static void assertFatalMessagesExist()
    {
        assertMessagesAtLevelExist(ApexPages.Severity.FATAL, true);
    }

    public static void assertNoConfirmMessagesExist()
    {
        assertNoMessagesAtLevelExist(ApexPages.Severity.CONFIRM, true);
    }
    public static void assertNoInfoMessagesExist()
    {
        assertNoMessagesAtLevelExist(ApexPages.Severity.INFO, true);
    }
    public static void assertNoWarningMessagesExist()
    {
        assertNoMessagesAtLevelExist(ApexPages.Severity.WARNING, true);
    }
    public static void assertNoErrorMessagesExist()
    {
        assertNoMessagesAtLevelExist(ApexPages.Severity.ERROR, true);
    }
    public static void assertNoFatalMessagesExist()
    {
        assertNoMessagesAtLevelExist(ApexPages.Severity.FATAL, true);
    }

    public static void assertMessagesAtLevelExist(ApexPages.Severity level, Boolean includeHigher)
    {
        final ApexPages.Message[] messages = SG_DisplayUtils.getMessagesAtLevel(level, includeHigher);
        System.assert(messages != null && messages.size() > 0, 'No errors exist');
    }

    public static void assertNoMessagesAtLevelExist(ApexPages.Severity level, Boolean includeHigher)
    {
        final ApexPages.Message[] messages = SG_DisplayUtils.getMessagesAtLevel(level, includeHigher);
        System.assert(messages == null || messages.size() <= 0, SG_DisplayUtils.messagesToString(messages));
    }

/* This is all of the Status Codes as of Winter'13, however it appears that toString() of a StatusCode results in a printer friendly string! */
/* This is for the pretty formatting, which uses a LOT of script statements, so not sure it's worth it */
    public static final Map<StatusCode, String> statusCodeToName = new Map<StatusCode, String>
    {
            StatusCode.ALL_OR_NONE_OPERATION_ROLLED_BACK => 'ALL_OR_NONE_OPERATION_ROLLED_BACK',
            StatusCode.ALREADY_IN_PROCESS => 'ALREADY_IN_PROCESS',
            StatusCode.ASSIGNEE_TYPE_REQUIRED => 'ASSIGNEE_TYPE_REQUIRED',
            StatusCode.BAD_CUSTOM_ENTITY_PARENT_DOMAIN => 'BAD_CUSTOM_ENTITY_PARENT_DOMAIN',
            StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED => 'BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED',
            StatusCode.CANNOT_CASCADE_PRODUCT_ACTIVE => 'CANNOT_CASCADE_PRODUCT_ACTIVE',
            StatusCode.CANNOT_CHANGE_FIELD_TYPE_OF_APEX_REFERENCED_FIELD => 'CANNOT_CHANGE_FIELD_TYPE_OF_APEX_REFERENCED_FIELD',
            StatusCode.CANNOT_CHANGE_FIELD_TYPE_OF_REFERENCED_FIELD => 'CANNOT_CHANGE_FIELD_TYPE_OF_REFERENCED_FIELD',
            StatusCode.CANNOT_CREATE_ANOTHER_MANAGED_PACKAGE => 'CANNOT_CREATE_ANOTHER_MANAGED_PACKAGE',
            StatusCode.CANNOT_DEACTIVATE_DIVISION => 'CANNOT_DEACTIVATE_DIVISION',
            StatusCode.CANNOT_DELETE_LAST_DATED_CONVERSION_RATE => 'CANNOT_DELETE_LAST_DATED_CONVERSION_RATE',
            StatusCode.CANNOT_DELETE_MANAGED_OBJECT => 'CANNOT_DELETE_MANAGED_OBJECT',
            StatusCode.CANNOT_DISABLE_LAST_ADMIN => 'CANNOT_DISABLE_LAST_ADMIN',
            StatusCode.CANNOT_ENABLE_IP_RESTRICT_REQUESTS => 'CANNOT_ENABLE_IP_RESTRICT_REQUESTS',
            StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY => 'CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY',
            StatusCode.CANNOT_MODIFY_MANAGED_OBJECT => 'CANNOT_MODIFY_MANAGED_OBJECT',
            StatusCode.CANNOT_RENAME_APEX_REFERENCED_FIELD => 'CANNOT_RENAME_APEX_REFERENCED_FIELD',
            StatusCode.CANNOT_RENAME_APEX_REFERENCED_OBJECT => 'CANNOT_RENAME_APEX_REFERENCED_OBJECT',
            StatusCode.CANNOT_RENAME_REFERENCED_FIELD => 'CANNOT_RENAME_REFERENCED_FIELD',
            StatusCode.CANNOT_RENAME_REFERENCED_OBJECT => 'CANNOT_RENAME_REFERENCED_OBJECT',
            StatusCode.CANNOT_REPARENT_RECORD => 'CANNOT_REPARENT_RECORD',
            StatusCode.CANNOT_UPDATE_CONVERTED_LEAD => 'CANNOT_UPDATE_CONVERTED_LEAD',
            StatusCode.CANT_DISABLE_CORP_CURRENCY => 'CANT_DISABLE_CORP_CURRENCY',
            StatusCode.CANT_UNSET_CORP_CURRENCY => 'CANT_UNSET_CORP_CURRENCY',
            StatusCode.CHILD_SHARE_FAILS_PARENT => 'CHILD_SHARE_FAILS_PARENT',
            StatusCode.CIRCULAR_DEPENDENCY => 'CIRCULAR_DEPENDENCY',
            StatusCode.COMMUNITY_NOT_ACCESSIBLE => 'COMMUNITY_NOT_ACCESSIBLE',
            StatusCode.CUSTOM_CLOB_FIELD_LIMIT_EXCEEDED => 'CUSTOM_CLOB_FIELD_LIMIT_EXCEEDED',
            StatusCode.CUSTOM_ENTITY_OR_FIELD_LIMIT => 'CUSTOM_ENTITY_OR_FIELD_LIMIT',
            StatusCode.CUSTOM_FIELD_INDEX_LIMIT_EXCEEDED => 'CUSTOM_FIELD_INDEX_LIMIT_EXCEEDED',
            StatusCode.CUSTOM_INDEX_EXISTS => 'CUSTOM_INDEX_EXISTS',
            StatusCode.CUSTOM_LINK_LIMIT_EXCEEDED => 'CUSTOM_LINK_LIMIT_EXCEEDED',
            StatusCode.CUSTOM_TAB_LIMIT_EXCEEDED => 'CUSTOM_TAB_LIMIT_EXCEEDED',
            StatusCode.DELETE_FAILED => 'DELETE_FAILED',
            StatusCode.DELETE_OPERATION_TOO_LARGE => 'DELETE_OPERATION_TOO_LARGE',
            StatusCode.DELETE_REQUIRED_ON_CASCADE => 'DELETE_REQUIRED_ON_CASCADE',
            StatusCode.DEPENDENCY_EXISTS => 'DEPENDENCY_EXISTS',
            StatusCode.DUPLICATE_CASE_SOLUTION => 'DUPLICATE_CASE_SOLUTION',
            StatusCode.DUPLICATE_COMM_NICKNAME => 'DUPLICATE_COMM_NICKNAME',
            StatusCode.DUPLICATE_CUSTOM_ENTITY_DEFINITION => 'DUPLICATE_CUSTOM_ENTITY_DEFINITION',
            StatusCode.DUPLICATE_CUSTOM_TAB_MOTIF => 'DUPLICATE_CUSTOM_TAB_MOTIF',
            StatusCode.DUPLICATE_DEVELOPER_NAME => 'DUPLICATE_DEVELOPER_NAME',
            StatusCode.DUPLICATE_EXTERNAL_ID => 'DUPLICATE_EXTERNAL_ID',
            StatusCode.DUPLICATE_MASTER_LABEL => 'DUPLICATE_MASTER_LABEL',
            StatusCode.DUPLICATE_SENDER_DISPLAY_NAME => 'DUPLICATE_SENDER_DISPLAY_NAME',
            StatusCode.DUPLICATE_USERNAME => 'DUPLICATE_USERNAME',
            StatusCode.DUPLICATE_VALUE => 'DUPLICATE_VALUE',
            StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR => 'EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR',
            StatusCode.EMPTY_SCONTROL_FILE_NAME => 'EMPTY_SCONTROL_FILE_NAME',
            StatusCode.ENTITY_FAILED_IFLASTMODIFIED_ON_UPDATE => 'ENTITY_FAILED_IFLASTMODIFIED_ON_UPDATE',
            StatusCode.ENTITY_IS_ARCHIVED => 'ENTITY_IS_ARCHIVED',
            StatusCode.ENTITY_IS_DELETED => 'ENTITY_IS_DELETED',
            StatusCode.ENTITY_IS_LOCKED => 'ENTITY_IS_LOCKED',
            StatusCode.ENVIRONMENT_HUB_MEMBERSHIP_CONFLICT => 'ENVIRONMENT_HUB_MEMBERSHIP_CONFLICT',
            StatusCode.ERROR_IN_MAILER => 'ERROR_IN_MAILER',
            StatusCode.FAILED_ACTIVATION => 'FAILED_ACTIVATION',
            StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION => 'FIELD_CUSTOM_VALIDATION_EXCEPTION',
            StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION => 'FIELD_FILTER_VALIDATION_EXCEPTION',
            StatusCode.FIELD_INTEGRITY_EXCEPTION => 'FIELD_INTEGRITY_EXCEPTION',
            StatusCode.FILTERED_LOOKUP_LIMIT_EXCEEDED => 'FILTERED_LOOKUP_LIMIT_EXCEEDED',
            StatusCode.HTML_FILE_UPLOAD_NOT_ALLOWED => 'HTML_FILE_UPLOAD_NOT_ALLOWED',
            StatusCode.IMAGE_TOO_LARGE => 'IMAGE_TOO_LARGE',
            StatusCode.INACTIVE_OWNER_OR_USER => 'INACTIVE_OWNER_OR_USER',
            StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY => 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY',
            StatusCode.INSUFFICIENT_ACCESS_OR_READONLY => 'INSUFFICIENT_ACCESS_OR_READONLY',
            StatusCode.INVALID_ACCESS_LEVEL => 'INVALID_ACCESS_LEVEL',
            StatusCode.INVALID_ARGUMENT_TYPE => 'INVALID_ARGUMENT_TYPE',
            StatusCode.INVALID_ASSIGNEE_TYPE => 'INVALID_ASSIGNEE_TYPE',
            StatusCode.INVALID_ASSIGNMENT_RULE => 'INVALID_ASSIGNMENT_RULE',
            StatusCode.INVALID_BATCH_OPERATION => 'INVALID_BATCH_OPERATION',
            StatusCode.INVALID_CONTENT_TYPE => 'INVALID_CONTENT_TYPE',
            StatusCode.INVALID_CREDIT_CARD_INFO => 'INVALID_CREDIT_CARD_INFO',
            StatusCode.INVALID_CROSS_REFERENCE_KEY => 'INVALID_CROSS_REFERENCE_KEY',
            StatusCode.INVALID_CROSS_REFERENCE_TYPE_FOR_FIELD => 'INVALID_CROSS_REFERENCE_TYPE_FOR_FIELD',
            StatusCode.INVALID_CURRENCY_CONV_RATE => 'INVALID_CURRENCY_CONV_RATE',
            StatusCode.INVALID_CURRENCY_CORP_RATE => 'INVALID_CURRENCY_CORP_RATE',
            StatusCode.INVALID_CURRENCY_ISO => 'INVALID_CURRENCY_ISO',
            StatusCode.INVALID_DATA_CATEGORY_GROUP_REFERENCE => 'INVALID_DATA_CATEGORY_GROUP_REFERENCE',
            StatusCode.INVALID_DATA_URI => 'INVALID_DATA_URI',
            StatusCode.INVALID_EMAIL_ADDRESS => 'INVALID_EMAIL_ADDRESS',
            StatusCode.INVALID_EMPTY_KEY_OWNER => 'INVALID_EMPTY_KEY_OWNER',
            StatusCode.INVALID_FIELD => 'INVALID_FIELD',
            StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE => 'INVALID_FIELD_FOR_INSERT_UPDATE',
            StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE => 'INVALID_FIELD_WHEN_USING_TEMPLATE',
            StatusCode.INVALID_FILTER_ACTION => 'INVALID_FILTER_ACTION',
            StatusCode.INVALID_GOOGLE_DOCS_URL => 'INVALID_GOOGLE_DOCS_URL',
            StatusCode.INVALID_ID_FIELD => 'INVALID_ID_FIELD',
            StatusCode.INVALID_INET_ADDRESS => 'INVALID_INET_ADDRESS',
            StatusCode.INVALID_LINEITEM_CLONE_STATE => 'INVALID_LINEITEM_CLONE_STATE',
            StatusCode.INVALID_MASTER_OR_TRANSLATED_SOLUTION => 'INVALID_MASTER_OR_TRANSLATED_SOLUTION',
            StatusCode.INVALID_MESSAGE_ID_REFERENCE => 'INVALID_MESSAGE_ID_REFERENCE',
            StatusCode.INVALID_OPERATION => 'INVALID_OPERATION',
            StatusCode.INVALID_OPERATOR => 'INVALID_OPERATOR',
            StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST => 'INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST',
            StatusCode.INVALID_PACKAGE_VERSION => 'INVALID_PACKAGE_VERSION',
            StatusCode.INVALID_PARTNER_NETWORK_STATUS => 'INVALID_PARTNER_NETWORK_STATUS',
            StatusCode.INVALID_PERSON_ACCOUNT_OPERATION => 'INVALID_PERSON_ACCOUNT_OPERATION',
            StatusCode.INVALID_QUERY_LOCATOR => 'INVALID_QUERY_LOCATOR',
            StatusCode.INVALID_READ_ONLY_USER_DML => 'INVALID_READ_ONLY_USER_DML',
            StatusCode.INVALID_SAVE_AS_ACTIVITY_FLAG => 'INVALID_SAVE_AS_ACTIVITY_FLAG',
            StatusCode.INVALID_SESSION_ID => 'INVALID_SESSION_ID',
            StatusCode.INVALID_SETUP_OWNER => 'INVALID_SETUP_OWNER',
            StatusCode.INVALID_STATUS => 'INVALID_STATUS',
            StatusCode.INVALID_TYPE => 'INVALID_TYPE',
            StatusCode.INVALID_TYPE_FOR_OPERATION => 'INVALID_TYPE_FOR_OPERATION',
            StatusCode.INVALID_TYPE_ON_FIELD_IN_RECORD => 'INVALID_TYPE_ON_FIELD_IN_RECORD',
            StatusCode.IP_RANGE_LIMIT_EXCEEDED => 'IP_RANGE_LIMIT_EXCEEDED',
            StatusCode.LICENSE_LIMIT_EXCEEDED => 'LICENSE_LIMIT_EXCEEDED',
            StatusCode.LIGHT_PORTAL_USER_EXCEPTION => 'LIGHT_PORTAL_USER_EXCEPTION',
            StatusCode.LIMIT_EXCEEDED => 'LIMIT_EXCEEDED',
            StatusCode.MALFORMED_ID => 'MALFORMED_ID',
            StatusCode.MANAGER_NOT_DEFINED => 'MANAGER_NOT_DEFINED',
            StatusCode.MASSMAIL_RETRY_LIMIT_EXCEEDED => 'MASSMAIL_RETRY_LIMIT_EXCEEDED',
            StatusCode.MASS_MAIL_LIMIT_EXCEEDED => 'MASS_MAIL_LIMIT_EXCEEDED',
            StatusCode.MAXIMUM_CCEMAILS_EXCEEDED => 'MAXIMUM_CCEMAILS_EXCEEDED',
            StatusCode.MAXIMUM_DASHBOARD_COMPONENTS_EXCEEDED => 'MAXIMUM_DASHBOARD_COMPONENTS_EXCEEDED',
            StatusCode.MAXIMUM_HIERARCHY_LEVELS_REACHED => 'MAXIMUM_HIERARCHY_LEVELS_REACHED',
            StatusCode.MAXIMUM_SIZE_OF_ATTACHMENT => 'MAXIMUM_SIZE_OF_ATTACHMENT',
            StatusCode.MAXIMUM_SIZE_OF_DOCUMENT => 'MAXIMUM_SIZE_OF_DOCUMENT',
            StatusCode.MAX_ACTIONS_PER_RULE_EXCEEDED => 'MAX_ACTIONS_PER_RULE_EXCEEDED',
            StatusCode.MAX_ACTIVE_RULES_EXCEEDED => 'MAX_ACTIVE_RULES_EXCEEDED',
            StatusCode.MAX_APPROVAL_STEPS_EXCEEDED => 'MAX_APPROVAL_STEPS_EXCEEDED',
            StatusCode.MAX_FORMULAS_PER_RULE_EXCEEDED => 'MAX_FORMULAS_PER_RULE_EXCEEDED',
            StatusCode.MAX_RULES_EXCEEDED => 'MAX_RULES_EXCEEDED',
            StatusCode.MAX_RULE_ENTRIES_EXCEEDED => 'MAX_RULE_ENTRIES_EXCEEDED',
            StatusCode.MAX_TASK_DESCRIPTION_EXCEEEDED => 'MAX_TASK_DESCRIPTION_EXCEEEDED',
            StatusCode.MAX_TM_RULES_EXCEEDED => 'MAX_TM_RULES_EXCEEDED',
            StatusCode.MAX_TM_RULE_ITEMS_EXCEEDED => 'MAX_TM_RULE_ITEMS_EXCEEDED',
            StatusCode.MERGE_FAILED => 'MERGE_FAILED',
            StatusCode.MISSING_ARGUMENT => 'MISSING_ARGUMENT',
            StatusCode.MIXED_DML_OPERATION => 'MIXED_DML_OPERATION',
            StatusCode.NONUNIQUE_SHIPPING_ADDRESS => 'NONUNIQUE_SHIPPING_ADDRESS',
            StatusCode.NO_APPLICABLE_PROCESS => 'NO_APPLICABLE_PROCESS',
            StatusCode.NO_ATTACHMENT_PERMISSION => 'NO_ATTACHMENT_PERMISSION',
            StatusCode.NO_INACTIVE_DIVISION_MEMBERS => 'NO_INACTIVE_DIVISION_MEMBERS',
            StatusCode.NO_MASS_MAIL_PERMISSION => 'NO_MASS_MAIL_PERMISSION',
            StatusCode.NUMBER_OUTSIDE_VALID_RANGE => 'NUMBER_OUTSIDE_VALID_RANGE',
            StatusCode.NUM_HISTORY_FIELDS_BY_SOBJECT_EXCEEDED => 'NUM_HISTORY_FIELDS_BY_SOBJECT_EXCEEDED',
            StatusCode.OPTED_OUT_OF_MASS_MAIL => 'OPTED_OUT_OF_MASS_MAIL',
            StatusCode.OP_WITH_INVALID_USER_TYPE_EXCEPTION => 'OP_WITH_INVALID_USER_TYPE_EXCEPTION',
            StatusCode.PACKAGE_LICENSE_REQUIRED => 'PACKAGE_LICENSE_REQUIRED',
            StatusCode.PORTAL_NO_ACCESS => 'PORTAL_NO_ACCESS',
            StatusCode.PORTAL_USER_ALREADY_EXISTS_FOR_CONTACT => 'PORTAL_USER_ALREADY_EXISTS_FOR_CONTACT',
            StatusCode.PRIVATE_CONTACT_ON_ASSET => 'PRIVATE_CONTACT_ON_ASSET',
            StatusCode.QUERY_TIMEOUT => 'QUERY_TIMEOUT',
            StatusCode.RECORD_IN_USE_BY_WORKFLOW => 'RECORD_IN_USE_BY_WORKFLOW',
            StatusCode.REQUEST_RUNNING_TOO_LONG => 'REQUEST_RUNNING_TOO_LONG',
            StatusCode.REQUIRED_FEATURE_MISSING => 'REQUIRED_FEATURE_MISSING',
            StatusCode.REQUIRED_FIELD_MISSING => 'REQUIRED_FIELD_MISSING',
            StatusCode.SELF_REFERENCE_FROM_TRIGGER => 'SELF_REFERENCE_FROM_TRIGGER',
            StatusCode.SHARE_NEEDED_FOR_CHILD_OWNER => 'SHARE_NEEDED_FOR_CHILD_OWNER',
            StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED => 'SINGLE_EMAIL_LIMIT_EXCEEDED',
            StatusCode.STANDARD_PRICE_NOT_DEFINED => 'STANDARD_PRICE_NOT_DEFINED',
            StatusCode.STORAGE_LIMIT_EXCEEDED => 'STORAGE_LIMIT_EXCEEDED',
            StatusCode.STRING_TOO_LONG => 'STRING_TOO_LONG',
            StatusCode.TABSET_LIMIT_EXCEEDED => 'TABSET_LIMIT_EXCEEDED',
            StatusCode.TEMPLATE_NOT_ACTIVE => 'TEMPLATE_NOT_ACTIVE',
            StatusCode.TERRITORY_REALIGN_IN_PROGRESS => 'TERRITORY_REALIGN_IN_PROGRESS',
            StatusCode.TEXT_DATA_OUTSIDE_SUPPORTED_CHARSET => 'TEXT_DATA_OUTSIDE_SUPPORTED_CHARSET',
            StatusCode.TOO_MANY_APEX_REQUESTS => 'TOO_MANY_APEX_REQUESTS',
            StatusCode.TOO_MANY_ENUM_VALUE => 'TOO_MANY_ENUM_VALUE',
            StatusCode.TRANSFER_REQUIRES_READ => 'TRANSFER_REQUIRES_READ',
            StatusCode.UNABLE_TO_LOCK_ROW => 'UNABLE_TO_LOCK_ROW',
            StatusCode.UNAVAILABLE_RECORDTYPE_EXCEPTION => 'UNAVAILABLE_RECORDTYPE_EXCEPTION',
            StatusCode.UNDELETE_FAILED => 'UNDELETE_FAILED',
            StatusCode.UNKNOWN_EXCEPTION => 'UNKNOWN_EXCEPTION',
            StatusCode.UNSPECIFIED_EMAIL_ADDRESS => 'UNSPECIFIED_EMAIL_ADDRESS',
            StatusCode.UNSUPPORTED_APEX_TRIGGER_OPERATON => 'UNSUPPORTED_APEX_TRIGGER_OPERATON',
            StatusCode.UNVERIFIED_SENDER_ADDRESS => 'UNVERIFIED_SENDER_ADDRESS',
            StatusCode.USER_OWNS_PORTAL_ACCOUNT_EXCEPTION => 'USER_OWNS_PORTAL_ACCOUNT_EXCEPTION',
            StatusCode.USER_WITH_APEX_SHARES_EXCEPTION => 'USER_WITH_APEX_SHARES_EXCEPTION',
            StatusCode.WEBLINK_SIZE_LIMIT_EXCEEDED => 'WEBLINK_SIZE_LIMIT_EXCEEDED',
            StatusCode.WRONG_CONTROLLER_TYPE => 'WRONG_CONTROLLER_TYPE'
    };

}

/*
* Common Exception Methods
* Exception methods are all called by and operate on a particular instance of an exception. The table below describes all instance exception methods. All types of exceptions have the following methods in common:
*
* Name		Arguments		Return Type		Description
*
* getCause 				Exception 		Returns the cause of the exception as an exception object.
* getLineNumber			Integer			Returns the line number from where the exception was thrown.
* getMessage 			String 			Returns the error message that displays for the user.
* getStackTraceString 	String 			Returns the stack trace as a string.
* getTypeName 			String			Returns the type of exception, such as DMLException, ListException, MathException, and so on.
* setMessage String s 	Void 			Sets the error message that displays for the user DMLException and EmailException Methods
*/

/*  ASCII METHODS

    public static final Map<String,Integer> charToAscii = new Map<String,Integer>();
    public static final Map<Integer,String> asciiToChar = new Map<Integer,String>();
        
	static{
        charToAscii.put(null, 0);
        charToAscii.put('\t', 9);
        charToAscii.put('\n', 10);
        charToAscii.put('\f', 12);
        charToAscii.put('\r', 13);
        charToAscii.put(' ', 32);
        charToAscii.put('!', 33);
        charToAscii.put('"', 34);
        charToAscii.put('#', 35);
        charToAscii.put('$', 36);
        charToAscii.put('%', 37);
        charToAscii.put('&', 38);
        charToAscii.put('\'', 39);
        charToAscii.put('(', 40);
        charToAscii.put(')', 41);
        charToAscii.put('*', 42);
        charToAscii.put('+', 43);
        charToAscii.put(',', 44);
        charToAscii.put('-', 45);
        charToAscii.put('.', 46);
        charToAscii.put('/', 47);
        charToAscii.put('0', 48);
        charToAscii.put('1', 49);
        charToAscii.put('2', 50);
        charToAscii.put('3', 51);
        charToAscii.put('4', 52);
        charToAscii.put('5', 53);
        charToAscii.put('6', 54);
        charToAscii.put('7', 55);
        charToAscii.put('8', 56);
        charToAscii.put('9', 57);
        charToAscii.put(':', 58);
        charToAscii.put(';', 59);
        charToAscii.put('<', 60);
        charToAscii.put('=', 61);
        charToAscii.put('>', 62);
        charToAscii.put('?', 63);
        charToAscii.put('@', 64);
        charToAscii.put('A', 65);
        charToAscii.put('B', 66);
        charToAscii.put('C', 67);
        charToAscii.put('D', 68);
        charToAscii.put('E', 69);
        charToAscii.put('F', 70);
        charToAscii.put('G', 71);
        charToAscii.put('H', 72);
        charToAscii.put('I', 73);
        charToAscii.put('J', 74);
        charToAscii.put('K', 75);
        charToAscii.put('L', 76);
        charToAscii.put('M', 77);
        charToAscii.put('N', 78);
        charToAscii.put('O', 79);
        charToAscii.put('P', 80);
        charToAscii.put('Q', 81);
        charToAscii.put('R', 82);
        charToAscii.put('S', 83);
        charToAscii.put('T', 84);
        charToAscii.put('U', 85);
        charToAscii.put('V', 86);
        charToAscii.put('W', 87);
        charToAscii.put('X', 88);
        charToAscii.put('Y', 89);
        charToAscii.put('Z', 90);
        charToAscii.put('[', 91);
        charToAscii.put('\\', 92);
        charToAscii.put(']', 93);
        charToAscii.put('^', 94);
        charToAscii.put('_', 95);
        charToAscii.put('`', 96);
        charToAscii.put('a', 97);
        charToAscii.put('b', 98);
        charToAscii.put('c', 99);
        charToAscii.put('d', 100);
        charToAscii.put('e', 101);
        charToAscii.put('f', 102);
        charToAscii.put('g', 103);
        charToAscii.put('h', 104);
        charToAscii.put('i', 105);
        charToAscii.put('j', 106);
        charToAscii.put('k', 107);
        charToAscii.put('l', 108);
        charToAscii.put('m', 109);
        charToAscii.put('n', 110);
        charToAscii.put('o', 111);
        charToAscii.put('p', 112);
        charToAscii.put('q', 113);
        charToAscii.put('r', 114);
        charToAscii.put('s', 115);
        charToAscii.put('t', 116);
        charToAscii.put('u', 117);
        charToAscii.put('v', 118);
        charToAscii.put('w', 119);
        charToAscii.put('x', 120);
        charToAscii.put('y', 121);
        charToAscii.put('z', 122);
        charToAscii.put('{', 123);
        charToAscii.put('|', 124);
        charToAscii.put('}', 125);
        charToAscii.put('~', 126);
                
	    for(String key : charToAscii.keySet()){
	        asciiToChar.put(charToAscii.get(key), key);    
	    }
	}
*/