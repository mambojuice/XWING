#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=installer.ico
#AutoIt3Wrapper_Outfile=bin\XWING.exe
#AutoIt3Wrapper_Res_Fileversion=0.9.0.22
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#comments-start ----------------------------------------------------------------------------

	XWING - XML Wizard and INstallation GUI

	AutoIt Version: 3.3.10.2
	Author:         Chris Thayer


	LICENSE:
	Copyright 2017, Chris Thayer

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	A copy of the GNU General Public License is included in the
	LICENSE file along with this program.


	ATTRIBUTIONS:
	Installer icon by Lokas
	http://www.softicons.com/toolbar-icons/realistic-icons-by-lokas-software/install-icon


#comments-end ----------------------------------------------------------------------------

; BEGIN MAIN EXECUTABLE ===========================================================================

; Required libraries
#include <AutoItConstants.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <GUIConstants.au3>
#include <ComboConstants.au3>
#include <String.au3>
#include <Array.au3>


; Global variables (and their default values where applicable)
Global $sTitle = @ScriptName
Global $iWidth = 640
Global $iHeight = 480
Global $oXML
Global $sGraphic
Global $sLogFile = @TempDir & "\" & StringLeft(@ScriptName, StringLen(@ScriptName) - 4) & "_" & @YEAR & @MON & @MDAY & ".log"
Global $bSilent = False


; Constants for GUI building
Global Const $CHARWIDTH = 8 ; Assumed character width when generating fields
Global Const $CHARHEIGHT = 18 ; Assumed character height when generating fields
Global Const $FIELDHEIGHT = 20 ; Height for generated input fields (textboxes, drop-downs)
Global Const $FIELDSPACING = 20 ; Vertical space between fields

; Arrays
Dim $aFields[6][3] ; Maximum of 6 fields per screen
; Each aFields row contains: [1] - variable, [2] - control, [3] - type

; Initialize
XWINGInit()

; Loop through screens
ShowScreens("before")

; Execute
RunCommands()

; Finish
ShowScreens("after")
WriteLog("")
WriteLog("Done! XWING is quitting...")

; END MAIN EXECUTABLE ===========================================================================
; That was easy, right?



; =============
; XWINGInit
;
; Description:
;	Sets up XWING and grabs settings from GENERAL section
;
; Parameters:
;	None
;
; Returns:
;	Nothing
; =============
Func XWINGInit()

	; Install graphic to temp
	; Can be overridden in the XML file
	; Must be 60x60 bitmap
	FileInstall("installer_graphic.bmp", @TempDir & "\installer_graphic.bmp", 1)

	; Default to using executable/script name for XML name
	$sXMLFile = StringLeft(@ScriptName, StringLen(@ScriptName) - 4) & ".xml"

	; Check if command line options were passed
	If $cmdLine[0] > 0 Then
		; Loop through command line options
		For $x = 1 To $cmdLine[0]
			; Check for silent switch
			If StringLower($cmdLine[$x]) = "/silent" Then
				$bSilent = True
			Else
				; If not silent switch, then our argument is an XML file to read
				$sXMLFile = $cmdLine[$x]
			EndIf
		Next
	EndIf

	; Verify our file is real
	If Not FileExists($sXMLFile) Then
		AbortWithError("Unable to locate XML file!")
	EndIf

	; Create XML object
	$oXML = ObjCreate("Microsoft.XMLDOM")
	$oXML.async = False

	If Not $oXML.Load($sXMLFile) Then
		; Unable to load XML for some reason
		$sMsg = "Invalid XML!" & @CRLF
		$sMsg = $sMsg & " " & @CRLF
		$sMsg = $sMsg & "Message: " & $oXML.parseError.reason & @CRLF
		$sMsg = $sMsg & "Line: " & $oXML.parseError.line & @CRLF
		$sMsg = $sMsg & "Character: " & $oXML.parseError.linePos & @CRLF
		$sMsg = $sMsg & "Error string: " & $oXML.parseError.srcText
		AbortWithError($sMsg)
	EndIf

	; Get general settings for this XWING session
	; TO DO - Use default values if not defined in XML
	$oGeneral = $oXML.selectSingleNode("/wizard/general")
	If $oGeneral.getAttribute("log") Then $sLogFile = Parse($oGeneral.getAttribute("log"))
	If $oGeneral.getAttribute("title") Then $sTitle = Parse($oGeneral.getAttribute("title"))
	If $oGeneral.getAttribute("width") Then $iWidth = Parse($oGeneral.getAttribute("width"))
	If $oGeneral.getAttribute("height") Then $iHeight = Parse($oGeneral.getAttribute("height"))
	If $oGeneral.getAttribute("graphic") Then
		$sGraphic = Parse($oGeneral.getAttribute("graphic"))
	Else
		$sGraphic = @TempDir & "\installer_graphic.bmp"
	EndIf

	; Dump all init info to log
	WriteLog("===============================================")
	WriteLog("XWING is taking off!")
	WriteLog("")
	WriteLog("Session info:")
	WriteLog("Computer name:  " & @ComputerName)
	WriteLog("User name:      " & @UserName)
	WriteLog("OS version:     " & @OSVersion)
	WriteLog("XWING path:     " & @ScriptFullPath)
	WriteLog("")
	WriteLog("General XWING info:")
	WriteLog("Command line args: " & $cmdLine[0])
	WriteLog("XML file:          " & $sXMLFile)
	WriteLog("Log file:          " & $sLogFile)
	WriteLog("")
	WriteLog("GUI Info:")
	WriteLog("Title:          " & $sTitle)
	WriteLog("Window width:   " & $iWidth)
	WriteLog("Window height:  " & $iHeight)

EndFunc   ;==>XWINGInit




; =============
; ShowScreens
;
; Description:
;	Displays all screens defined in the XML file
;
; Parameters:
;	Stage (string)
;		Which stage of screens to show
;
; Returns:
;	Nothing
; =============
Func ShowScreens($stage)

	If $bSilent Then
		WriteLog("")
		WriteLog("Running silently, skipping screens.")
	Else
		WriteLog("")
		WriteLog("Processing screens [Stage: " & $stage & "]")

		$oScreens = $oXML.selectNodes("/wizard/screens[@stage='" & $stage & "']/screen")

		If IsObj($oScreens) Then
			$iScreens = $oScreens.Length

			WriteLog("")
			WriteLog($iScreens & " screen(s) to show")

			$iCount = 0
			For $oScreen In $oScreens
				$iCount += 1
				$sID = $oScreen.getAttribute("id")

				WriteLog("")
				WriteLog("Generating screen '" & $sID & "'")

				; Create the form object
				$oForm = GUICreate($sTitle, $iWidth, $iHeight)

				; Group for bottom buttons. Exceeds window by +2 to hide all borders except top
				$grpFooter = GUICtrlCreateGroup("", -2, $iHeight - 57, $iWidth + 4, 59)

				; Cancel button (appears on all screens)
				$btnCancel = GUICtrlCreateButton("&Cancel", 10, $iHeight - 40, 80, 30)

				; Back button (appears on all screens except first)
				If ($iCount <> 1) Then
					$btnBack = GUICtrlCreateButton("< &Back", $iWidth - 180, $iHeight - 40, 80, 30)
				EndIf

				; Finish button (appears on last screen)
				$btnNext = GUICtrlCreateButton("&Next >", $iWidth - 90, $iHeight - 40, 80, 30)
				GUICtrlSetState($btnNext, $GUI_ENABLE)

				; Header elements
				$gHeaderBG = GUICtrlCreateGraphic(0, 0, $iWidth, 60)
				GUICtrlSetBkColor($gHeaderBG, 0xFFFFFF)
				$grpHeader = GUICtrlCreateGroup("", -2, -15, $iWidth + 4, 77)
				$gInstallerGraphic = GUICtrlCreatePic($sGraphic, $iWidth - 60, 0, 59, 59)

				$lblTitle = GUICtrlCreateLabel("Title", 10, 10, $iWidth - 72, 30)
				GUICtrlSetBkColor($lblTitle, 0xFFFFFF)
				GUICtrlSetFont($lblTitle, 18, 600, 0, "Calibri")

				$lblSubtitle = GUICtrlCreateLabel("Subtitle", 10, 40, $iWidth - 72, 15)
				GUICtrlSetBkColor($lblSubtitle, 0xFFFFFF)
				GUICtrlSetFont($lblSubtitle, 10, 400, 0, "Calibri")
				GUISetState(@SW_SHOW, $oForm)

				; Populate form with elements from XML
				GUICtrlSetData($lblTitle, Parse($oScreen.getAttribute("title")))
				GUICtrlSetData($lblSubtitle, Parse($oScreen.getAttribute("subtitle")))

				; Generate fields
				$aFields = ClearFields() ; Set to clean array

				; aFields structure:
				;	[0] = Variable that field will set
				;	[1] = The GUI object handle
				;	[2] = The object type
				;   [3] = The object label

				$iTop = 90 ; Starting position
				$iCount = 0
				For $oField In $oXML.selectNodes("/wizard/screens/screen[@id='" & $sID & "']/field")
					$sType = Parse(StringLower($oField.getattribute("type")))

					Select
						Case $sType = "label"
							$sLabelText = Parse($oField.getAttribute("text"))

							; Calculate label height based on number of characters of text OR line breaks in string
							If StringInStr($sLabelText, Chr(13)) Then
								StringReplace($sLabelText, Chr(13), Chr(13))
								$iLineCount = @extended ; Get number of lines
								$iLabelHeight = $iLineCount * $CHARHEIGHT
							Else
								$iLabelHeight = (StringLen($sLabelText) * $CHARWIDTH) / ($iWidth - 60) * $CHARHEIGHT
							EndIf
							If $iLabelHeight < $CHARHEIGHT Then $iLabelHeight = $CHARHEIGHT ; One line minimum

							GUICtrlCreateLabel($sLabelText, 30, $iTop, ($iWidth - 60), $iLabelHeight)

							; Save field info to array
							$aFields[$iCount][0] = ""
							$aFields[$iCount][1] = ""
							$aFields[$iCount][2] = $sType
							$aFields[$iCount][3] = ""

							$iTop += $iLabelHeight + $FIELDSPACING


						Case $sType = "input"
							$sVar = $oField.getAttribute("var")
							$sLabelText = Parse($oField.getAttribute("label"))

							GUICtrlCreateLabel($sLabelText, 30, $iTop + 2, ($iWidth / 3) - 60, $CHARHEIGHT)

							; Save field info to array
							$aFields[$iCount][0] = $sVar
							$aFields[$iCount][1] = GUICtrlCreateInput("", ($iWidth / 3) - 30, $iTop, ($iWidth / 3 * 2) - 30, $FIELDHEIGHT)
							$aFields[$iCount][2] = $sType
							$aFields[$iCount][3] = $sLabelText

							GUICtrlSetData(-1, GetVarValue($sVar))

							$iTop += $FIELDHEIGHT + $FIELDSPACING

						Case $sType = "dropdown"
							$sVar = $oField.getAttribute("var")

							; Get all values for dropdown
							$sValues = ""
							For $oNode In $oField.selectNodes("option")
								$sValues = $sValues & $oNode.text & "|"
							Next
							StringTrimRight($sValues, 1) ; Remove trailing pipe

							$sLabelText = Parse($oField.getAttribute("label"))
							GUICtrlCreateLabel($sLabelText, 30, $iTop + 2, ($iWidth / 3) - 60, $CHARHEIGHT)

							; Save field info to array
							$aFields[$iCount][0] = $sVar
							$aFields[$iCount][1] = GUICtrlCreateCombo("", ($iWidth / 3) - 30, $iTop, ($iWidth / 3 * 2) - 30, $FIELDHEIGHT, BitOR($CBS_SORT, $CBS_DROPDOWNLIST))
							$aFields[$iCount][2] = $sType
							$aFields[$iCount][3] = $sLabelText

							GUICtrlSetData(-1, $sValues)

							$iTop += $FIELDHEIGHT + $FIELDSPACING

						Case $sType = "radio"
							$sVar = $oField.getAttribute("var")

							; Get number of radio values
							$iRadioCount = $oField.selectNodes("option").length()
							Dim $aRadio[$iRadioCount]

							$sLabelText = Parse($oField.getAttribute("label"))
							GUICtrlCreateLabel($sLabelText, 30, $iTop + 2, ($iWidth / 3) - 60, $FIELDHEIGHT)

							$iRadioCount = 0
							For $oOption In $oField.selectNodes("option")
								$aRadio[$iRadioCount] = GUICtrlCreateRadio(Parse($oOption.text), ($iWidth / 3) - 30, $iTop, ($iWidth / 3 * 2) - 30, $FIELDHEIGHT)
								$iTop += $FIELDHEIGHT
								$iRadioCount += 1
							Next

							; Save field info to array
							$aFields[$iCount][0] = $sVar
							$aFields[$iCount][1] = $aRadio ; Array of radio buttons
							$aFields[$iCount][2] = $sType
							$aFields[$iCount][3] = $sLabelText

							$iTop += $FIELDSPACING
					EndSelect

					; Increment count for aFields index
					$iCount += 1

				Next

				WriteLog("Waiting for user input...")

				; Input handling...
				$bWait = True
				While $bWait
					$oMsg = GUIGetMsg()

					Select
						Case $oMsg = $GUI_EVENT_CLOSE ; Window closed
							PromptCancel()
						Case $oMsg = $btnCancel ; Cancel button
							PromptCancel()
						Case $oMsg = $btnNext ; Next button
							If ValidateScreen($aFields) Then
								GUICtrlSetState($btnNext, $GUI_DISABLE)
								SaveScreenValues($aFields)
								$bWait = False
								GUISetState(@SW_HIDE, $oForm)
							EndIf
					EndSelect
				WEnd
			Next
		EndIf
	EndIf
EndFunc   ;==>ShowScreens




; =============
; AbortWithError
;
; Description:
;	Aborts XWING with error code from last command (or 1 if internal error/not defined)
;	Logs error message
;
; Parameters:
;	Message (string)
;
; Returns:
;	Nothing
; =============
Func AbortWithError($Message, $errorCode = 1)
	If Not $bSilent Then
		MsgBox(16, "Error", "(" & $errorCode & ") " & $Message)
	EndIf

	WriteLog($Message)
	Exit ($errorCode)
EndFunc   ;==>AbortWithError




; =============
; WriteLog
;
; Description:
;	Writes to log file and/or console
;
; Parameters:
;	Message (string)
;
; Returns:
;	Nothing
; =============
Func WriteLog($Message)
	ConsoleWrite($Message & @CRLF)

	If ($sLogFile <> "") Then
		$sTimestamp = @YEAR & "." & @MON & "." & @MDAY & " - " & @HOUR & ":" & @MIN & ":" & @SEC
		FileWriteLine($sLogFile, $sTimestamp & "  " & $Message)
	EndIf
EndFunc   ;==>WriteLog




; =============
; PromptCancel
;
; Description:
;	Yes/No prompt when user clicks Cancel or Close
;
; Parameters:
;	None
;
; Returns:
;	Nothing
; =============
Func PromptCancel()
	$oMsgBox = MsgBox(36, "Confirm", "Are you sure you want to cancel the wizard?")

	If $oMsgBox = 6 Then ; 6 means "Yes"
		WriteLog("")
		WriteLog("User closed the wizard!")
		WriteLog("Exiting with code 1")
		WriteLog("===============================================")
		Exit 1
	EndIf

EndFunc   ;==>PromptCancel




; =============
; ValidateScreen
;
; Description:
;	Make sure we have valid inputs for all fields on a screen
;
; Parameters:
;	FieldArray (array)
;
; Returns:
;	True if valid, False if invalid
; =============
Func ValidateScreen($FieldArray)
	$bScreenOk = True

	For $x = 0 To 5
		$sVar = $FieldArray[$x][0]
		$oControl = $FieldArray[$x][1]
		$sType = $FieldArray[$x][2]
		$sLabelText = $FieldArray[$x][3]

		Select
			; Make sure a radio button was selected
			Case $sType = "radio"
				$bSelected = False
				For $oRadio In $oControl ; Loop through all radio buttons
					If (GUICtrlRead($oRadio) = 1) Then ; 1 means selected
						$bSelected = True
					EndIf
				Next

				If $bSelected = False Then
					MsgBox(16, "Invalid Selection", "Please make a selection for '" & $sLabelText & "'")
					$bScreenOk = False
				EndIf

		EndSelect
	Next

	Return $bScreenOk
EndFunc   ;==>ValidateScreen



; =============
; SaveScreenValues
;
; Description:
;	Save values of fields to the appropriate variables in our working XML
;
; Parameters:
;	FieldArray (array)
;
; Returns:
;	Nothing
; =============
Func SaveScreenValues($FieldArray)
	For $x = 0 To 5
		$sVar = $FieldArray[$x][0]
		$oControl = $FieldArray[$x][1]
		$sType = $FieldArray[$x][2]

		Select
			; Save value from input or dropdown
			Case $sType = "input" Or $sType = "dropdown"
				SetVarValue($sVar, GUICtrlRead($oControl))

				; Save value from radio control
			Case $sType = "radio"
				For $oRadio In $oControl ; Loop through all radio buttons
					If (GUICtrlRead($oRadio) = 1) Then ; 1 means selected
						WriteLog("RADIO " & GUICtrlRead($oRadio) & " SELECTED")
						SetVarValue($sVar, GUICtrlRead($oRadio, 1)) ; Use value of selected radio button (value stored in advanced control information)
					EndIf
				Next
		EndSelect
	Next
EndFunc   ;==>SaveScreenValues





; =============
; RunCommands
;
; Description:
;	Run all commands within the <command> node.
;
; Parameters:
;	None
;
; Returns:
;	None
; =============
Func RunCommands()

	WriteLog("")
	WriteLog("Running commands...")

	$oCommands = $oXML.selectNodes("/wizard/commands/command")

	If IsObj($oCommands) Then
		; Build the GUI
		$oForm = GUICreate($sTitle, $iWidth, $iHeight)

		; Header elements
		$grpHeader = GUICtrlCreateGroup("", -2, -15, $iWidth + 4, 76)
		$gHeaderBG = GUICtrlCreateGraphic(-0, 0, $iWidth, 60)
		GUICtrlSetBkColor($gHeaderBG, 0xFFFFFF)
		$gInstallerGraphic = GUICtrlCreatePic($sGraphic, $iWidth - 60, 0, 59, 59)

		$lblTitle = GUICtrlCreateLabel("Installing", 10, 10, $iWidth - 75, 30)
		GUICtrlSetBkColor($lblTitle, 0xFFFFFF)
		GUICtrlSetFont($lblTitle, 18, 600, 0, "Calibri")

		$lblSubtitle = GUICtrlCreateLabel("Please wait while the installation runs. This may take several minutes...", 10, 40, $iWidth - 75, 15)
		GUICtrlSetBkColor($lblSubtitle, 0xFFFFFF)
		GUICtrlSetFont($lblSubtitle, 10, 400, 0, "Calibri")

		; Progress bar and label
		$lblCommandTitle = GUICtrlCreateLabel("", 10, $iHeight / 2, $iWidth - 20, 30)
		$oProgressBar = GUICtrlCreateProgress(10, ($iHeight / 2) + 30, $iWidth - 20, 40)

		; Show the screen
		GUISetState(@SW_SHOW, $oForm)

		; Process commands
		$iCommands = $oCommands.length

		WriteLog("There are " & $iCommands & " commands to run")

		$iCount = 0
		For $oCommand In $oCommands
			; Update progress bar
			GUICtrlSetData($oProgressBar, (($iCount + 1) / $iCommands) * 100)

			; Read ID, mode, and title
			$sID = $oCommand.getAttribute("id")
			$sMode = StringLower($oCommand.getAttribute("mode"))
			$sCommandTitle = ""
			If $oCommand.getAttribute("title") Then $sCommandTitle = Parse($oCommand.getAttribute("title"))

			; Update screen with command title
			GUICtrlSetData($lblCommandTitle, $sCommandTitle)

			WriteLog("")
			WriteLog("Running command ID '" & $sID & "' (" & $sMode & ")")

			Select
				; Command mode is 'save'
				Case $sMode = "save"

					; Get path to save XML
					$sPath = Parse($oCommand.getAttribute("path"))
					DumpXML($sPath)
					WriteLog("XML saved to '" & $sPath & "'")


					; Command mode is 'execute'
				Case $sMode = "execute"

					; Get command path and arguments
					$sPath = Parse($oCommand.getAttribute("path"))
					$sArgs = Parse($oCommand.getAttribute("parameters"))
					$oErrorMsg = $oCommand.selectSingleNode("errormsg")

					If Not FileExists($sPath) Then
						AbortWithError("Unable to locate required file for command '" & $sID & "'")
					EndIf

					$sCmd = $sPath & " " & $sArgs

					;Get working dir, set to XWING dir by default
					$sWorkingDir = @ScriptDir
					If $oCommand.getAttribute("workingdir") Then $sWorkingDir = Parse($oCommand.getAttribute("workingdir"))

					; Log some info
					WriteLog("  Executing command: " & $sCmd)
					WriteLog("  Working directory: " & $sWorkingDir)

					; Hide window?
					$oHide = @SW_HIDE
					If $oCommand.getAttribute("hide") = False Then $oHide = @SW_SHOW

					; Run the command
					$ret = RunWait($sCmd, $sWorkingDir, $oHide)

					WriteLog("  Command exited with code " & $ret)

					If $ret <> 0 Then

						; Get valid exit codes if defined
						If $oCommand.getAttribute("exitcodes") Then
							$sExitCodes = Parse($oCommand.exitcodes)
							$aExitCodes = StringSplit($sExitCodes, ",")


							;Exit with error if returned code is not in list of valid codes
							If _ArraySearch($aExitCodes, $ret) = -1 Then
								If IsObj($oErrorMsg) Then
									$sErrorMsg = Parse($oErrorMsg.text)
								Else
									$sErrorMsg = "Command " & $sID & " did not return a valid exit code!"
								EndIf
								AbortWithError($sErrorMsg, $ret)
							EndIf
						Else
							;No additional exit codes specified, exit with error
							If IsObj($oErrorMsg) Then
								$sErrorMsg = Parse($oErrorMsg.text)
							Else
								$sErrorMsg = "Command " & $sID & " did not return a valid exit code!"
							EndIf
							AbortWithError($sErrorMsg, $ret)
						EndIf
					EndIf

					$iCount += 1
			EndSelect
		Next

		; Hide progress screen when done
		GUISetState(@SW_HIDE, $oForm)

	EndIf
EndFunc   ;==>RunCommands





; =============
; GetVarValue
;
; Description:
;	Get the value of a variable defined in an XWING file
;   Order of precidence:
;     1 - Inner text
;     2 - "Value" attribute
;     3 - Empty string
;
; Parameters:
;	VarName (string)
;
; Returns:
;	Value (string)
; =============
Func GetVarValue($VarName)

	$oVar = $oXML.selectSingleNode("/wizard/variables/var[@name='" & $VarName & "']")

	If IsObj($oVar) Then
		If $oVar.text Then ; Order of precidence 1
			$ret = Parse($oVar.text)
		ElseIf $oVar.GetAttribute("value") Then ; Order of precidence 2
			$ret = Parse($oVar.getAttribute("value"))
		Else ; Order of precidence 3
			$ret = ""
		EndIf

		WriteLog("Getting variable value: " & $VarName & " ==> """ & $ret & """")
	Else
		WriteLog("Getting variable value: " & $VarName & " ==> UNDEFINED (returning empty string)")

		$ret = ""
	EndIf

	Return $ret
EndFunc   ;==>GetVarValue





; =============
; SetVarValue
;
; Description:
;	Set the value of a variable defined in an XML file
;
; Parameters:
;	VarName (string)
;	Value (string)
;
; Returns:
;	Nothing
; =============
Func SetVarValue($VarName, $Value)

	WriteLog("Saving variable value: " & $VarName & " ==> """ & $Value & """")

	$oVar = $oXML.selectSingleNode("/wizard/variables/var[@name='" & $VarName & "']")
	If IsObj($oVar) Then
		If $oVar.getAttribute("value") <> "" Then
			$oVar.removeAttribute("value")
		EndIf
		$oVar.text = Parse($Value)
	Else
		WriteLog("WARNING: Trying to save variable '" & $VarName & "' but it is not defined!")
	EndIf

EndFunc   ;==>SetVarValue





; =============
; GetFunctionValue
;
; Description:
;   Run function and return value
;
; Parameters:
;   Function (string) - Name of the function to run
;
; Returns:
;   Value
; =============
Func GetFunctionValue($FunctionName)
	$ret = "" ; Default empty string

	$oFunc = $oXML.selectSingleNode("/wizard/functions/func[@name='" & $FunctionName & "']")

	If IsObj($oFunc) Then
		$sAction = StringLower($oFunc.GetAttribute("action"))

		WriteLog("Running function '" & $FunctionName & "'...")
		WriteLog("  Function mode: " & $sAction)

		Select
			;command_output
			Case $sAction = "command_output"
				$sPath = Parse($oFunc.getAttribute("path"))
				$sArgs = Parse($oFunc.getAttribute("arguments"))
				$sCmd = $sPath & " """ & $sArgs & """"

				$sWorkingDir = @ScriptDir
				If $oFunc.getAttribute("workingdir") Then $sWorkingDir = $oFunc.getAttribute("workingdir")

				WriteLog("    Running command: " & $sCmd)
				WriteLog("    Working directory: " & $sWorkingDir)

				$iPid = Run($sCmd, $sWorkingDir, @SW_HIDE, $STDOUT_CHILD)
				If @error Then
					WriteLog("    Unable to run command!")
				Else
					ProcessWaitClose($iPid)
					$sOutput = StdoutRead($iPid)
				EndIf

				$ret = TrimSpaces($sOutput)

				;file_read
			Case $sAction = "file_read"
				$sFilePath = Parse($oFunc.getAttribute("path"))
				If FileExists($sFilePath) Then
					$fileContents = FileRead($sFilePath)

					$ret = TrimSpaces($fileContents)

				Else
					WriteLog("  File does not exist! Returning empty string.")
					$ret = ""
				EndIf

				;file_write
			Case $sAction = "file_write"
				$sFilePath = Parse($oFunc.getAttribute("path"))
				$sFileContents = Parse($oFunc.text)

				If FileWrite($sFilePath, $sFileContents) Then
					WriteLog("  File '" & $sFilePath & "' written")
				Else
					WriteLog("  WARNING: Unable to write file '" & $sFilePath & "'")
				EndIf

				;math
			Case $sAction = "math"
				$sFunctionExpression = Parse($oFunc.text)
				$ret = Execute($sFunctionExpression)

				;reg_read -- TO DO!!!
			Case $sAction = "reg_read"

				;strip_extra_space
			Case $sAction = "strip_extra_space"
				$sFunctionExpression = Parse($oFunc.text)
				$ret = TrimSpaces($sFunctionExpression)

				;xml_value -- TO DO!!!
			Case $sAction = "xml_value"


			Case Else
				$ret = ""
				WriteLog("  ... Hey, what's '" & $sAction & "'?")
		EndSelect
	EndIf

	Return $ret

EndFunc   ;==>GetFunctionValue





; =============
; ClearFields
;
; Description:
;	Set array of fields to empty array
;
; Parameters:
;	Nothing
;
; Returns:
;	Nothing
; =============
Func ClearFields()
	Dim $array[6][4]
	For $iRow = 0 To 5
		$array[$iRow][0] = ""
		$array[$iRow][1] = ""
		$array[$iRow][2] = ""
		$array[$iRow][3] = ""
	Next
	$array[0][0] = 0

	Return $array
EndFunc   ;==>ClearFields





; =============
; DumpXML
;
; Description:
;	Dump the entire working XML
;
; Parameters:
;	FilePath (string)
;
; Returns:
;	Nothing
; =============
Func DumpXML($FilePath)
	WriteLog("Saving working XML data to '" & $FilePath & "'...")

	$oXML.save($FilePath)
EndFunc   ;==>DumpXML





; =============
; Parse
;
; Description:
;   Parse a string and replace any variables or functions with their values
;	  [[variable]]
;	  {{function}}
;
; Parameters:
;   TextString (string)
;
; Returns:
;   Enumerated string
; ==============
Func Parse($TextString)
	$sParsedString = $TextString

	; Step 1 - Parse environment variables
	$aEnvVariables = _StringBetween($sParsedString, "[[env:", "]]")

	If UBound($aEnvVariables) > 0 Then
		For $var In $aEnvVariables
			$sParsedString = StringReplace($sParsedString, "[[env:" & $var & "]]", EnvGet($var))
		Next
	EndIf


	; Step 2 - Parse variables
	$aVariables = _StringBetween($sParsedString, "[[", "]]")

	If UBound($aVariables) > 0 Then
		For $var In $aVariables
			$sParsedString = StringReplace($sParsedString, "[[" & $var & "]]", GetVarValue($var))
		Next
	EndIf


	; Step 3 - Parse functions
	$aFunctions = _StringBetween($sParsedString, "{{", "}}")

	If UBound($aFunctions) > 0 Then
		For $func In $aFunctions
			$sParsedString = StringReplace($sParsedString, "{{" & $func & "}}", GetFunctionValue($func))
		Next
	EndIf

	Return $sParsedString
EndFunc   ;==>Parse





; =============
; TrimSpaces
;
; Description:
;   Strip trailing and leading spaces and line breaks from a string
;
; Parameters:
;   Text (string)
;
; Returns:
;   Trimmed string
; ==============
Func TrimSpaces($Text)
	$ret = $Text

	; Strip leading space/line break
	$bLoop = True
	While $bLoop
		If (StringIsSpace(StringMid($ret, 1, 1))) Or (StringMid($ret, 1, 1) = Chr(13)) Then
			$ret = StringTrimLeft($ret, 1)
		Else
			$bLoop = False
		EndIf
	WEnd

	; Strip trailing space/line break
	$bLoop = True
	While $bLoop
		If (StringIsSpace(StringMid($ret, StringLen($ret) - 1, 1))) Or (StringMid($ret, StringLen($ret) - 1, 1) = Chr(13)) Then
			$ret = StringTrimRight($ret, 1)
		Else
			$bLoop = False
		EndIf
	WEnd

	Return $ret
EndFunc   ;==>TrimSpaces
