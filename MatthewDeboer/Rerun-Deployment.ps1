#Orignal code from Mdedeboer

-JobScript {
    Param ($strCompName, $AdvID, $AdvName, $PackID)
    $strScheduledID = $null
    $strMessage = ''
    $strQuery = "Select * from CCM_Scheduler_ScheduledMessage where ScheduledMessageID like '" + $AdvID + "%'"
    $objSMSSchID = Get-WmiObject -Query $strQuery -Namespace root\ccm\policy\machine\actualconfig -computername $strCompName
    foreach ($instance in $objSMSSchID) { $strScheduleID = $instance.ScheduledMessageID }  #There will only be one instance...unless the client is really broken
    if (!($strScheduleID))
    {
	    $strMessage = $strMessage + 'Failed to identify scheduled id' + '; '
    }
    else
    {
	    Try
	    {
		    #Set advertisment to rerun always
		    $objWMI = gwmi -Query "Select * from ccm_softwaredistribution where adv_advertisementID like '${AdvID}%'" -namespace 'root\ccm\policy\machine\actualconfig' -ComputerName $strCompName
		    $objWMI.ADV_RepeatRunBehavior = 'RerunAlways'
		    [void]$objWMI.Put()
	    }
	    Catch [Exception]{
		    $strMessage = $strMessage + "Failed to set rerun behavior" + '; '
	    }
	    #Trigger Scheduled Message
	    Try
	    {
	    $WMIPath = "\\" + $strCompName + "\root\ccm:SMS_Client"
		    $SMSwmi = [wmiclass] $WMIPath
		    [Void]$SMSwmi.TriggerSchedule($strScheduleID)
	    }
	    Catch [Exception]{
		    $strMessage = $strMessage + "Failed to trigger scheduled message" + '; '
	    }
							
	    #Trigger Machine Policy Refresh
	    Try
	    {
		    $WMIPath = "\\" + $strCompName + "\root\ccm:SMS_Client"
		    $SMSwmi = [wmiclass]$WMIPath
		    [Void]$SMSwmi.TriggerSchedule('{00000000-0000-0000-0000-000000000021}')
	    }
	    Catch [Exception]{
		    $strMessage = 'Triggered rerun, but failed to tigger policy refresh' + '; '
	    }
	    if ($strMessage -eq '')
	    {
		    $strMessage = 'Successfully triggered rerun'
	    }
    }
    return $strMessage
}