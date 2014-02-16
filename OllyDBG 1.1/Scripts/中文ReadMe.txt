///////////////////////////////////////////////
//	ollyscript Plugin v0.6全部命令中文解释
//	我只写了命令的中文大概意思，没有全文翻释.
//	汉化:loveboom[DFCG]
//	Email:bmd2chen@tom.com
///////////////////////////////////////////////

-------------------------------
OllyScript plugin v0.6 by SHaG
-------------------------------

1. About OllyScript
2. Status
2.1 What's new in v0.6?
3. Documentation
3.1 Language
3.2 Labels
3.3 Comments
3.4 Menus
4. Contact me
5. License
6. Thanks!

------------------------------

1. About OllyScript
-------------------
OllyScript is a plugin for OllyDbg, which is, in my opinion, 
the best application-mode debugger out there. One of the best 
features of this debugger is the plugin architecture which allows 
users to extend its functionality. OllyScript is a plugin 
meant to let you automate OllyDbg by writing scripts in an 
assembly-like language. Many tasks involve a lot of repetitive 
work just to get to some point in the debugged application. By 
using my plugin you can write a script once and for all. 

------------------------------

2. Status (24 February 2004)
----------------------------
Another release of OllyScript... I think this plugin is getting to the
point when I no longer have any improvement ideas... So either I start
getting suggestions or there will be no new versions... Remember:
shag@apsvans.com or SHaG on EFnet=)

2.1 What's new?
---------------
The internal architecture of the plugin totally redone and object-oriented 
(its not perfect OO, but bear with it). Because of this rewrite, bugs are
likely to appear. Please report them to me ASAP!
Bugs with script processing are fixed, parts of code are redone etc.

+ New commands: 
	BPCND, BC, BPMC, JA, JB, JAE, JBE, AI, AO, TI, TO
+ Conditional breakpoints
+ Breakpoint clearing (even memory)
+ Tracing and animation
+ More jumps
+ Stepping through script supported
# BP behaviour fixed (it now SETS breakpoint, instead of TOGGLEING it).
# Bugs in script processing fixed (thanks s0nkite).
# LOG now logs things like strings that are referenced by the address,
  referenced function addresses etc. Try it, its cool!
# "Thanks" section of readme updated. =)
------------------------------

3. Documentation
----------------
Two example scripts (tElock098.osc and UPX.osc) are available with this release. 
The scripts will when run immediately find the OEP packed executable. 

3.1 Language
------------
The scripting language of OllyScript is an assembly-like language.

In the document below, src and dest can be (unless stated otherwise):
 - Constant in the form of a hex number withot prefixes and suffixes (i.e. 00FF, not 0x00FF or 00FFh)
 - Variable previously declared by VAR
 - A 32-bit register (one of EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP, EIP). Non 32-bit registers are not supported at
   the moment, but you can use SHL/SHR and AND to get their values.
 - A memory reference in square brackets (i.e. [401000] points to the memory at address 401000, [ecx] points to the memory at address ecx).
 
The following commands are available at the moment:

ADD dest, src
-------------
Adds src to dest and stores result in dest
相当于汇编中的ADD
Example: 
	add x, 0F
	add eax, x
	add [401000], 5

AI
--
相当于CTRL+F7
Executes "Animate into" in OllyDbg
Example:
	ai

AND dest, src
-------------
相当于汇编中的AND
ANDs src and dest and stores result in dest
Example: 
	and x, 0F
	and eax, x
	and [401000], 5

ASM addr, command
-----------------
在ADDR处进行汇编，相当于SICE中的A
Assemble a command at some address
Example:
	asm eip, "mov eax, ecx"

AO
--
相当于CTRL+F8
Executes "Animate over" in OllyDbg
Example:
	ao

BC addr
-------
清除断点
Clear unconditional breakpoint at addr.
Example:
	bc 401000
	bc x
	bc eip

BP addr
--------
设置断点
Set unconditional breakpoint at addr.
Example:
	bp 401000
	bp x
	bp eip

BPCND addr, cond
----------------
设置条件断点
Set breakpoint on address addr with condition cond.
Example:
	bpcnd 401000, "ECX==1"
	
BPMC
----
清除内存断点
Clear memory breakpoint.
Example:
	bpmc

BPHWC addr
----------
删除硬件断点
Delete hardware breakpoint at a specified address
Example:
	bphwc 401000
	
BPHWS addr, mode
----------------
设置硬件断点
Set hardware breakpoint. Mode can be "r" - read, "w" - write or "x" - execute.
Example:
	bphws 401000, "x"

BPRM addr, size
---------------
设置内存读断点
Set memory breakpoint on read. Size is size of memory in bytes.
Example:
	bprm 401000, FF

BPWM addr, size
---------------
设置内存写断点
Set memory breakpoint on write. Size is size of memory in bytes.
Example:
	bpwm 401000, FF

CMP dest, src
-------------
比较两个值，和汇编中一样
Compares dest to src. Works like it's ASM counterpart.
Example: 
	cmp y, x
	cmp eip, 401000

CMT addr, text
--------------
在ADDR处写上注释
Inserts a comment at the specified address
Example:
	cmt eip, "This is the entry point"

EOB label
---------
中断后执行label
Transfer execution to some label on next breakpoint.
Example:
	eob SOME_LABEL

EOE label
---------
异常后执行label
Transfer execution to some label on next exception.
Example:
	eoe SOME_LABEL '注这里原作者写错了，原来写的是eob some_label

ESTI
----
相当于SHIFT+F7
Executes SHIFT-F7 in OllyDbg.
Example:
	esti

ESTO
----
相当于SHIFT+F9
Executes SHIFT-F9 in OllyDbg.
Example:
	esto

FINDOP addr, what
-----------------
在addr位置找到what，和CTRL+B有点类似,找到后结果保存在$RESULT中,如果$RESULT为0代表没有找到.
Searches code starting at addr for an instruction that begins with the specified bytes. 
When found sets the reserved $RESULT variable. $RESULT == 0 if nothing found.
Example:
	findop 401000, #61# // find next POPAD

GPA proc, lib
-------------
得到API函数的地址,这个函数非常有用，用于下API断点.结果也是放在$RESULT中，如果没有得到API的值$RESULT==0，找到后可以下bp $RESULT
Gets the address of the specified procedure in the specified library.
When found sets the reserved $RESULT variable. $RESULT == 0 if nothing found.
Useful for setting breakpoints on APIs.
Example:
	gpa "MessageBoxA", "user32.dll" // After this $RESULT is the address of MessageBoxA and you can do "bp $RESULT".

GMI addr, info
得到addr模块信息，info可以为MODULEBASE,MODULESIZE或codebase,codesize
结果也保存在$RESULT中
--------------
Gets information about a module to which the specified address belongs.
"info" can be MODULEBASE, MODULESIZE, CODEBASE or CODESIZE (if you want other info in the future versions plz tell me).
Sets the reserved $RESULT variable (0 if data not found).
Example:
	GMI eip, CODEBASE // After this $RESULT is the address to the codebase of the module to which eip belongs

JA label
--------
相当于汇编中的JA
Use this after cmp. Works like it's asm counterpart.
Example:
	ja SOME_LABEL

JAE label
相当于汇编中的JAE
---------
Use this after cmp. Works like it's asm counterpart.
Example:
	jae SOME_LABEL

JB label
--------
相当于汇编中的JB
Use this after cmp. Works like it's asm counterpart.
Example:
	jb SOME_LABEL

JBE label
---------
相当于汇编中的JBE
Use this after cmp. Works like it's asm counterpart.
Example:
	jbe SOME_LABEL

JE label
--------
相当于汇编中的JE
Use this after cmp. Works like it's asm counterpart.
Example:
	je SOME_LABEL

JMP label
---------
相当于汇编中的JMP
Unconditionally jump to a label.
Example:
	jmp SOME_LABEL

JNE label
---------
相当于汇编中的JNE
Use this after cmp. Works like it's asm counterpart.
Example:
	jne SOME_LABEL

LBL addr, text
--------------
在ADDR处插入标签
Inserts a label at the specified address
Example:
	lbl eip, "NiceJump"

LOG src
-------
记录SRC到log window
Logs src to OllyDbg log window.
If src is a constant string the string is logged as it is.
If src is a variable or register its logged with its name.
Example:
	log "Hello world" // The string "Hello world" is logged
	var x
	mov x, 10
	log x // The string "x = 00000010" is logged.

MOV dest, src
-------------
相当于汇编中的MOV
Move src to dest.
Src can be a long hex string in the format #<some hex numbers>#, for example #1234#.
Remember that the number of digits in the hex string must be even, i.e. 2, 4, 6, 8 etc.
Example: 
	mov x, 0F
	mov y, "Hello world"
	mov eax, ecx
	mov [ecx], #00DEAD00BEEF00#

MSG message
-----------
相当于MESSAGEBOX,提示信息
Display a message box with specified message
Example:
	MSG "Script paused"

OR dest, src
-------------
相当于汇编中的OR
ORs src and dest and stores result in dest
Example: 
	or x, 0F
	or eax, x
	or [401000], 5

PAUSE
-----
暂停脚本的执行
Pauses script execution. Script can be resumed from plugin menu.
Example:
	pause

RET
---
退出脚本
Exits script.
Example:
	ret

RTR
---
相当于CTRL+F9
Executes "Run to return" in OllyDbg
Example:
	rtr

RTU
---
相当于ALT+F9
Executes "Run to user code" in OllyDbg
Example:
	rtu

RUN
---
相当于F9
Executes F9 in OllyDbg
Example:
	run

SHL dest, src
-------------
相当于汇编中的SHL左移
Shifts dest to the left src times and stores the result in dest.
Example:
	mov x, 00000010
	shl x, 8 // x is now 00001000

SHR dest, src
-------------
相当于汇编中的SHR，右移
Shifts dest to the right src times and stores the result in dest.
Example:
	mov x, 00001000
	shr x, 8 // x is now 00000010

STI
---
OLLY中的F7
Execute F7 in OllyDbg.
Example:
	sti

STO
---
相当于F8
Execute F8 in OllyDbg.
Example:
	sto

SUB dest, src
-------------
两个数相减结果保存在dest中，相当于汇编中的SUB
Substracts src from dest and stores result in dest
Example: 
	sub x, 0F
	sub eax, x
	sub [401000], 5

TI
--
相当于CTRL+F11，跟踪步进
Executes "Trace into" in OllyDbg
Example:
	ti

TO
--
相当于CTRL+F12,跟踪步过
Executes "Trace over" in OllyDbg
Example:
	to

VAR
---
定义变量
Declare a variable to be used in the script. 
Must be done before the variable is used.
Example: 
	var x

XOR dest, src
-------------
相当于汇编中的XOR
XORs src and dest and stores result in dest
Example: 
	xor x, 0F
	xor eax, x
	xor [401000], 5


3.2 Labels
----------
Labels are defined bu using the label name followed by a colon.
Example:
	SOME_LABEL:


3.3 Comments
------------
Comments can be put anywhere and have to start with "//". Block
comments must start with "/*" on a new line and and with "*/"
also on a new line.


3.4 Menus
---------
The main OllyScript menu consists of the following items:
- Run script...: lets the user select a script file and starts it
- Abort: aborts a running script
- Pause: pauses a running script
- Resume: resumes a paused script
- Step: execute one script line
- About: shows information about this plugin



------------------------------

4. Contact me
-------------
To contact me you can post your question in the forum or go on IRC 
and message SHaG on EFnet. 

------------------------------

5. License
----------
Soon I'm going to armadildo this plugin and charge an awful lot of money
for it! :P Seriously, you are free to use this plugin and the source code however 
you see fit. However please name me in your documentation/about box and if 
the project you need my code for is on a larger scale please also notify 
me - I am curious.

------------------------------

6. Thanks!
----------
I'd like to thank:
- A. Focht and sgdt on OllyDbg users' board for helping me with many explanations and ideas.
- s0nkite for reporting bugs
- britedream, lownoise, FEUERRADER (privet =)) and R@dier for writing such nice scripts!
- And of course Olly, the man who wrote the magnificent debugger!

------------------------------