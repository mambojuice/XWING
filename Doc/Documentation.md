# XWING - XML Wizard and INstallation GUI

## Contents
[Summary](#summary)  
[Invoking XWING](#invoking-xwing)  
[Definition File](#definition-file)  
[Definition File Components](#definition-file-components)  
[Variables and Functions](#variables-and-functions)

-----

## Summary

XWING is a tool for displaying a friendly user wizard based on an XML definition file. It can also launch commands using the user-provided input.

-----

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

-----

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

-----

## Definition file components

### Node: Wizard

Required: Yes

This is the root XML node in which all other objects are contained.

#### Attributes
None

#### Child Nodes
* [General](#node-general)
* [Variables](#node-variables)
* [Functions](#node-functions)
* [Strings](#node-strings)
* [Commands](#node-commands)

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

Store variables here that can be re-used anywhere within the definition file. Individual *var* elements will be defined as children under the *variables* node.

#### Attributes
None

#### Child Nodes
* [Var](#node-var)

### Node: Var

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
None

### Node: Functions

Required: No

Store functions here that can be re-used anywhere within the definition file. Individual *function* elements will be defined as children of the *functions* node.

#### Attributes
None

#### Child Nodes
* [Func](#node-func)

### Node: Func

Required: No

This node defines a single function.

Function results are referenced elsewhere in the definition file by using `{{name}}` in place of part or all of a string.

If an undefined function is referenced, an empty string will be returned.

#### Attributes
Name       | Required? | Description                                                                | Default Value
---------- | --------- | -------------------------------------------------------------------------- | -------------
name       | Yes       | Name of the variable                                                       | N/A
action     | Yes       | Valid [function action](#function-actions).                                | N/A

Additional attributes vary depending on the function action specified.

#### Child Nodes
None

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
* [Screen](#node-screen)

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
* [Field](#node-field)

### Node: Field

Required: No

Fields are components that make up the body of a screen. Any field that accepts input will save to a variable.

See [Field Types](#field-types) below for more details on the different options available for each field type.

#### Attributes
Name     | Required? | Description                       | Default Value
-------- | --------- | --------------------------------- | -------------
type     | Yes       | Valid [Field Type](#field-types)  | N/A

Additional attributes apply depending on field type.

#### Child Nodes
* [Option](#field-types) (only for certain field types)

### Node: Commands

Required: No (but what's the point without it?)

This is the root node for commands. Each command will be defined in a [command](#node:-command) child node.

#### Attributes
None

#### Child Nodes
* [Command](#node-command)

### Node: Command

Required: No

Each command node defines an individual command to execute. Commands are not sorted by id or title, they are executed in the order in which they are defined.

#### Attributes
Name     | Required? | Description                       | Default Value
-------- | --------- | --------------------------------- | -------------
id       | yes       | Unique identifier for the command. Not displayed, only used for identifying in XML and logging. | N/A
title    | no        | Friendly name of command for displaying the progress. | (blank)
mode     | yes       | Valid [command mode](#command-modes) | N/A

Additional attributes apply depending on command mode.

#### Child Nodes
* [Errormsg](#node-errormsg)

#### Example

```xml
<command id="msi_install" mode="execute" path="msiexec.exe" parameters="/qb /i myproduct.msi"/>
```

### Node: Errormsg

Required: No

If a command returns an error (non-zero exit code) a generic error message listing the command ID and exit code value will be displayed. This error message can be overridden by giving the command node an errormsg child. The message contents is the inner text of the errormsg node.

#### Attributes
None

#### Child Nodes
None

#### Example

```xml
<command id="cleanup_windows_temp" mode="execute" path="[[env:comspec]]" parameters="/c del c:\windows\temp\*.* /q/s">
	<errormsg>Unable to delete files from the Windows TEMP folder. Do you have admin permissions?</errormsg>
</command>
```

-----

## Variables and functions

### Environment Variables
Environment variables can be accessed by adding the "env:" prefix to your variable reference.

For example, to delete all items in the temp folder here is what a command may look like:
```xml
<command id="clean_temp" mode="execute" path="[[env:comspec]] /c del [[env:temp]]\*.* /q/s"/>
```

### Function Actions

#### builtin

#### command_output

Command_output will capture the output of an external command and return the results.

IMPORTANT: Commands are executed as they are referenced, so it is possible to have a function return different values throughout your wizard. This may or may not be your intent!

Additional attributes for command_output:

Name | Required? | Description | Default Value
---- | --------- | ----------- | -------------
path | Yes       | Path to the command to execute | N/A
TBD  |           |             |

#### file_read

File_read will read a plaintext file and save the results.

Additional attributes for file_read:

Name | Required? | Description              | Default Value
---- | --------- | ------------------------ | -------------
path | Yes       | Path to the file to read | N/A

#### reg_read

Reg_read will read the value of a registry key and return the results.

_NOT YET IMPLEMENTED IN CODE_

#### math

Math will evaluate a mathematical function and return the result.

The expression should be contained within the inner text of the <func> node.

#### strip_extra_space

Strip_extra_space will return the string it is passed, minus any leading and trailing spaces.

The expression should be contained within the inner text of the <func> node.

#### xml_value

XML_value will return an XML value from file and a given XPATH.

_NOT YET IMPLEMENTED IN CODE_

## Field types

### label

### input

### dropdown

### radio


## Command modes

### save

Save will save a value to file.

### execute

Execute will execute a file. Any non-zero exit code will be considered a failure unless additional valid exit codes are specified.

Additional attributes for `<command mode="execute">`:

Name       | Required? | Description                  | Default Value
---------- | --------- | ---------------------------- | -------------
path       | Yes       | Path to the executable       | N/A
arguments  | No        | Additional arguments to pass | (blank)
workingdir | No        | Working path where executable will run | Path where XWING is running
