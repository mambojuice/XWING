# XWING - XML Wizard and INstallation GUI

## Contents
[Summary](#summary)  
[Invoking XWING](#invoking-xwing)  
[Definition File](#definition-file)  
[Definition File Components](#definition-file-components)  
[Variables and Functions](#variables-and-functions)


## Summary

XWING is a tool for displaying a friendly user wizard based on an XML definition file.

## Invoking XWING

```
XWing.exe [Path to XML file]
```

Regardless of command line parameters, XWING will default to logging in the TEMP folder unless otherwise specified in your definition file.

### No parameters
If no parameters are passed, XWing will automatically look for an XML file with the same name as the executable. If an XML file is not found, an error is displayed and XWing will quit.

This makes it easy to bundle XWing as part of a package. If the executable is renamed to "setup.exe" and the XML is saved in the same directory as "setup.xml", users can simply double-click on setup.exe to launch your wizard.

### Path to XML file
If you do not wish to package your XML along with the XWING executable, or if you are launching a definition file from another location, the path can be provided. The full path should be contained in quotes if there are any spaces in the file or folder names.

## Definition File
There are four major components (XML nodes) to any definition file:
* General
* Screens ("before" stage)
* Commands
* Screens ("after" stage)

All nodes are encapsulated within the master "wizard" node.

The definition file is processed in the following stages:
1. Load information defined in the "general" node
2. Display screens defined in the "before" stage
3. Execute commands
4. Display screens defined in the "after" stage

### Examples
Here's an example of a very minimal definition file:
```xml
<wizard>
	<general title="My first definition file"/>
	<screens stage="before">
		<screen id="first" title="Screen 1" subtitle="This is the first screen">
			<field type="label" text="Welcome to my simple wizard!"/>
			<field type="label" text="Please click Next to continue..."/>
		</screen>
	</screens>

	<commands>
		<command id="batch_test" title="Executing batch file" mode="execute" path="pingtest.cmd"/>
	</commands>

	<screens stage="after">
		<screen id="last" title="Done!">
			<field type="label" text="Who's awesome? You're awesome!"/>
		</screen>
	</screens>
</wizard>
```

And here's a more advanced example:
```xml
<wizard>
	<general title="[[title]]" width="640" height="480" log="XWING_advanced.log" />

	<variables>
		<var name="field1" value="Type something here!"/>
		<var name="field2"/>
		<var name="field3"/>
		<var name="field4"/>
		<var name="title" value="Advanced XWING Definition File Example"/>
	</variables>

	<functions>
		<func name="math_test" action="math">4 + 3</func>
		<func name="bool_test_1" action="bool">1 = 2</func>
		<func name="bool_test_2" action="bool">"foo" = "foo"</func>
		<func name="c_contents" action="command_output" path="[[env:comspec]]" arguments="/c dir c:\" />
	</functions>

	<screens stage="before">
		<screen id="command_test" title="Contents of C:\">
			<field type="label" text="{{c_contents}}"/>
		</screen>
		<screen id="first" title="Screen 1" subtitle="This is the first screen">
			<field type="label" text="Hey dude, fill in these fields"/>
			<field type="input" label="Input Field" var="field1"/>
			<field type="input" label="Another Field" var="field2"/>
		</screen>
		<screen id="second" title="Screen 2" subtitle="This is the second screen">
			<field type="label" text="Here is an example of some other field types:"/>
			<field type="dropdown" label="Dropdown test" var="field3">
				<option>Value 1</option>
				<option>Value 2</option>
			</field>
			<field type="radio" label="Radio test" var="field4">
				<option>Option 1</option>
				<option>Option 2</option>
			</field>
		</screen>
	</screens>

	<commands>
		<command id="save_xml" title="Save installer info" mode="save" path="C:\XWING_test.xml"/>
		<command id="cleanup_temp" title="Cleanup temp folder" mode="execute" path="[[env:comspec]]" parameters="/c del /q/s [[env:temp]]"/>
		<command id="batch_test" title="Executing batch file" mode="execute" path="pingtest.cmd"/>
		<command id="errormsg_test" title="Delete a file" mode="execute" path="[[env:comspec]]" parameters="/c exit 1">
			<errormsg>Unable to find the file to delete! You should try again</errormsg>
		</command>
		<command id="ping2" title="Ping test 2" mode="execute" path="[[env:comspec]]" parameters="/c ping localhost"/>
	</commands>

	<screens stage="after">
		<screen id="last" title="Done!">
			<field type="label" text="Who's awesome? You're awesome!"/>
		</screen>
	</screens>


</wizard>
```

## Definition file components

### Node: Wizard

Required: Yes

This is the root XML node in which all other objects are contained.

#### Attributes
None

#### Child Nodes
* General
* Variables
* Functions
* Strings
* Commands

 ### Node: General
 
 Required: Yes
 
 This node defines the general settings for your wizard.
 
 #### Attributes
 Name   | Required? | Description          | Default Value
 ------ | --------- | -------------------- | -------------
 title  | Yes       | Title of the wizard  | N/A
 log    | No        | Path to log file     | `%temp%\[definition file name]_[timestamp].log`
 width  | No        | Width of GUI window  | 640
 height | No        | Height of GUI window | 480
 
 #### Child Nodes
 None
 
 ### Node: Variables
 
 Required: No
 
 Store variables here that can be re-used anywhere within the definition file. Individual *variable* elements will be defined as children under the *variables* node.
 
 #### Attributes
 None
 
 #### Child Nodes
 * Variable
 
 ### Node: Variable
 
 Required: No
 
 This node defines a single variable.
 
 Variables are referenced elsewhere in the definition file by using `[[name]]` in place of part or all of a string.
 
 If an undefined variable is referenced, an empty string will be returned.
 
 #### Attributes
 Name  | Required? | Description                                                           | Default Value
 ----- | --------- | --------------------------------------------------------------------- | -------------
 name  | Yes       | Name of the variable                                                  | N/A
 value | No        | Value of the variable. _Not required if setting value in inner text._ | N/A
 
 #### Inner text
 Value of the variable. If both inner text and the "value" attribute are defined, inner text takes precedence.
 
 #### Child Nodes
 * None

### Node: Functions

Required: No
 
 Store functions here that can be re-used anywhere within the definition file. Individual *function* elements will be defined as children of the *functions* node.
 
 #### Attributes
 None
 
 #### Child Nodes
 * Function

 ### Node: Function
 
 Required: No
 
 This node defines a single function.
 
 Function results are referenced elsewhere in the definition file by using `{{name}}` in place of part or all of a string.
 
 If an undefined function is referenced, an empty string will be returned.
 
 #### Attributes
 Name       | Required? | Description                                                                | Default Value
 ---------- | --------- | -------------------------------------------------------------------------- | -------------
 name       | Yes       | Name of the variable                                                       | N/A
 action     | Yes       | Type of function. See [Variables and Functions](#variables-and-functions) below. Additional attributes vary depending on action. | N/A
 
 
 #### Child Nodes
 * None

### Node: Screens

Required: No

This is the root node for defining wizard screens. Generally there will be two Screens elements, one to define screens before commands run, and the second to define screens after commands run.

Individual *screen* elements will be defined as children of the *screens* node.

It is possible to have a non-interactive installer with no screens defined, only commands.

#### Attributes
Name   | Required? | Description                    | Default Value
------ | --------- | ------------------------------ | -------------
stage  | Yes       | Either "before" or "after"     | N/A

#### Child Nodes
* Screen

### Node: Screen

Required: No

This node defines a single screen. Screens are not sorted by id or title, they appear in the order in which they are defined.

#### Attributes
Name     | Required? | Description                    | Default Value
-------- | --------- | ------------------------------ | -------------
id       | Yes       | Unique identified for the screen. Not displayed, only used for identifying in XML and logging. | N/A
title    | No        | Large text at the top of the screen. | (blank)
subtitle | No        | Smaller text just below the title.   | (blank)

#### Child Nodes
* Field

### Node: Field

Required: No

Fields are components that make up the body of a screen. Any field that accepts input will save to a variable.

See [Field Types](#field-types) below for more details on the different options available for each field type.

#### Attributes

#### Child Nodes
* Option (only for certain field types)

### Node: Commands

### Node: Command

## Field types


 ## Variables and functions
 
 ### Function Actions
 
 #### command_output
 
 #### file_read
 
 #### file_write
 
 #### reg_read
 
 #### math
 
 #### strip_extra_space
 
 #### xml_value
 
