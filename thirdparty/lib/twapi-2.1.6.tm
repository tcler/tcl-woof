# Copyright (c) 2003-2008, Ashok P. Nadkarni
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# - Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.  
# 
# - Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# - The name of the copyright holder and any other contributors may not
# be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
proc copy_dll_from_tm {{path {}}} {
if {$path eq {}} {set path [file join $env(TMP) twapi-2.1.6.dll ]}
set tmp [open $path w]

        set f [open [info script]]
        fconfigure $f -translation binary
        set data [read $f][close $f]
        set ctrlz [string first \u001A $data]
        fconfigure $tmp -translation binary
        puts -nonewline $tmp [string range $data [incr ctrlz] end]
        close $tmp
    
}
#-- from twapi_version.tcl
namespace eval twapi {
variable version 2.1
variable patchlevel 2.1.6
}
#-- from twapi_buildinfo.tcl
namespace eval twapi {
variable dll_base_name twapi
}
set twapi::build_id ed7ca116-51f3-4341-5ee1-8b2f2d57efd8
#-- from twapi.tcl
package require Tcl 8.4
package require registry
if {[string match 4* $::tcl_platform(osVersion)]} {
error "This version of TWAPI is not supported on Windows NT 4.0"
}
namespace eval twapi {
variable nullptr "__null__"
variable scriptdir [file dirname [info script]]
}
if {![info exists twapi::version]} {
source [file join $twapi::scriptdir twapi_version.tcl]
}
proc load_twapi_dll {fallback_dirs} {
if {![info exists ::twapi::dll_base_name]} {
set ::twapi::dll_base_name twapi
}
set tmpdir [pwd]
catch {set tmpdir $::env(TEMP)}; # Use TEMP if available
if {[info exists twapi::temp_dll_dir]} {
set tmpdir $twapi::temp_dll_dir
}
if {[info commands copy_dll_from_tm] == "copy_dll_from_tm"} {
set dest [file join $tmpdir "${::twapi::dll_base_name}-${::twapi::build_id}.dll"]
if {![file exists $dest]} {
file mkdir $tmpdir
copy_dll_from_tm $dest
}
load $dest Twapi
} elseif {[info exists ::starkit::topdir]} {
set dest [file join $tmpdir "${::twapi::dll_base_name}-${::twapi::build_id}.dll"]
if {![file exists $dest]} {
file mkdir $tmpdir
file copy [file join $twapi::scriptdir "${::twapi::dll_base_name}.dll"] $dest
}
load $dest Twapi
} else {
if {[catch {load [file join $twapi::scriptdir "${::twapi::dll_base_name}.dll"]}]} {
set loaded 0
foreach dir $fallback_dirs {
if {[catch {load [file join $dir "${::twapi::dll_base_name}.dll"]}] == 0} {
set loaded 1
break
}
}
if {! $loaded} {
error "Could not load ${::twapi::dll_base_name}.dll"
}
}
}
}
proc ::twapi::load_twapi {} {
if {[catch {
load_twapi_dll [list [file join $twapi::scriptdir ../base/build/release]]
} msg]} {
set ercode $::errorCode
set erinfo $::errorInfo
if {[info exists ::env(SystemRoot)]} {
set dir $::env(SystemRoot)
} elseif {[info exists ::env(WINDIR)]} {
set dir $::env(WINDIR)
} else {
error $msg $erinfo $ercode
}
set dir [file join $dir SYSTEM32]
foreach dll {
KERNEL32.dll ADVAPI32.dll USER32.dll RPCRT4.dll
GDI32.dll PSAPI.DLL NETAPI32.dll pdh.dll WINMM.dll
MPR.dll WS2_32.dll ole32.dll OLEAUT32.dll SHELL32.dll
WINSPOOL.DRV VERSION.dll iphlpapi.dll POWRPROF.dll Secur32.dll
USERENV.dll WTSAPI32.dll SETUPAPI.dll MSVCRT.dll MSVCP60.dll
} {
if {![file exists [file join $dir $dll]]} {
lappend missing $dll
}
}
if {[info exists missing]} {
set msg "$msg The error might be because the file(s) [join $missing {, }] are missing from the Windows SYSTEM32 directory."
}
error $msg $erinfo $ercode
}
}
twapi::load_twapi
proc twapi::add_defines {deflist} {
variable windefs
array set windefs $deflist
}
twapi::add_defines {
VER_NT_WORKSTATION              0x0000001
VER_NT_DOMAIN_CONTROLLER        0x0000002
VER_NT_SERVER                   0x0000003
VER_SERVER_NT                       0x80000000
VER_WORKSTATION_NT                  0x40000000
VER_SUITE_SMALLBUSINESS             0x00000001
VER_SUITE_ENTERPRISE                0x00000002
VER_SUITE_BACKOFFICE                0x00000004
VER_SUITE_COMMUNICATIONS            0x00000008
VER_SUITE_TERMINAL                  0x00000010
VER_SUITE_SMALLBUSINESS_RESTRICTED  0x00000020
VER_SUITE_EMBEDDEDNT                0x00000040
VER_SUITE_DATACENTER                0x00000080
VER_SUITE_SINGLEUSERTS              0x00000100
VER_SUITE_PERSONAL                  0x00000200
VER_SUITE_BLADE                     0x00000400
DELETE                         0x00010000
READ_CONTROL                   0x00020000
WRITE_DAC                      0x00040000
WRITE_OWNER                    0x00080000
SYNCHRONIZE                    0x00100000
STANDARD_RIGHTS_REQUIRED       0x000F0000
STANDARD_RIGHTS_READ           0x00020000
STANDARD_RIGHTS_WRITE          0x00020000
STANDARD_RIGHTS_EXECUTE        0x00020000
STANDARD_RIGHTS_ALL            0x001F0000
SPECIFIC_RIGHTS_ALL            0x0000FFFF
GENERIC_READ                   0x80000000
GENERIC_WRITE                  0x40000000
GENERIC_EXECUTE                0x20000000
GENERIC_ALL                    0x10000000
DESKTOP_READOBJECTS         0x0001
DESKTOP_CREATEWINDOW        0x0002
DESKTOP_CREATEMENU          0x0004
DESKTOP_HOOKCONTROL         0x0008
DESKTOP_JOURNALRECORD       0x0010
DESKTOP_JOURNALPLAYBACK     0x0020
DESKTOP_ENUMERATE           0x0040
DESKTOP_WRITEOBJECTS        0x0080
DESKTOP_SWITCHDESKTOP       0x0100
DF_ALLOWOTHERACCOUNTHOOK    0x0001
WINSTA_ENUMDESKTOPS         0x0001
WINSTA_READATTRIBUTES       0x0002
WINSTA_ACCESSCLIPBOARD      0x0004
WINSTA_CREATEDESKTOP        0x0008
WINSTA_WRITEATTRIBUTES      0x0010
WINSTA_ACCESSGLOBALATOMS    0x0020
WINSTA_EXITWINDOWS          0x0040
WINSTA_ENUMERATE            0x0100
WINSTA_READSCREEN           0x0200
WINSTA_ALL_ACCESS           0x37f
FILE_READ_DATA                 0x00000001
FILE_LIST_DIRECTORY            0x00000001
FILE_WRITE_DATA                0x00000002
FILE_ADD_FILE                  0x00000002
FILE_APPEND_DATA               0x00000004
FILE_ADD_SUBDIRECTORY          0x00000004
FILE_CREATE_PIPE_INSTANCE      0x00000004
FILE_READ_EA                   0x00000008
FILE_WRITE_EA                  0x00000010
FILE_EXECUTE                   0x00000020
FILE_TRAVERSE                  0x00000020
FILE_DELETE_CHILD              0x00000040
FILE_READ_ATTRIBUTES           0x00000080
FILE_WRITE_ATTRIBUTES          0x00000100
FILE_ALL_ACCESS                0x001F01FF
FILE_GENERIC_READ              0x00120089
FILE_GENERIC_WRITE             0x00120116
FILE_GENERIC_EXECUTE           0x001200A0
FILE_SHARE_READ                    0x00000001
FILE_SHARE_WRITE                   0x00000002
FILE_SHARE_DELETE                  0x00000004
FILE_ATTRIBUTE_READONLY             0x00000001
FILE_ATTRIBUTE_HIDDEN               0x00000002
FILE_ATTRIBUTE_SYSTEM               0x00000004
FILE_ATTRIBUTE_DIRECTORY            0x00000010
FILE_ATTRIBUTE_ARCHIVE              0x00000020
FILE_ATTRIBUTE_DEVICE               0x00000040
FILE_ATTRIBUTE_NORMAL               0x00000080
FILE_ATTRIBUTE_TEMPORARY            0x00000100
FILE_ATTRIBUTE_SPARSE_FILE          0x00000200
FILE_ATTRIBUTE_REPARSE_POINT        0x00000400
FILE_ATTRIBUTE_COMPRESSED           0x00000800
FILE_ATTRIBUTE_OFFLINE              0x00001000
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  0x00002000
FILE_ATTRIBUTE_ENCRYPTED            0x00004000
FILE_NOTIFY_CHANGE_FILE_NAME    0x00000001
FILE_NOTIFY_CHANGE_DIR_NAME     0x00000002
FILE_NOTIFY_CHANGE_ATTRIBUTES   0x00000004
FILE_NOTIFY_CHANGE_SIZE         0x00000008
FILE_NOTIFY_CHANGE_LAST_WRITE   0x00000010
FILE_NOTIFY_CHANGE_LAST_ACCESS  0x00000020
FILE_NOTIFY_CHANGE_CREATION     0x00000040
FILE_NOTIFY_CHANGE_SECURITY     0x00000100
FILE_ACTION_ADDED                   0x00000001
FILE_ACTION_REMOVED                 0x00000002
FILE_ACTION_MODIFIED                0x00000003
FILE_ACTION_RENAMED_OLD_NAME        0x00000004
FILE_ACTION_RENAMED_NEW_NAME        0x00000005
FILE_CASE_SENSITIVE_SEARCH      0x00000001
FILE_CASE_PRESERVED_NAMES       0x00000002
FILE_UNICODE_ON_DISK            0x00000004
FILE_PERSISTENT_ACLS            0x00000008
FILE_FILE_COMPRESSION           0x00000010
FILE_VOLUME_QUOTAS              0x00000020
FILE_SUPPORTS_SPARSE_FILES      0x00000040
FILE_SUPPORTS_REPARSE_POINTS    0x00000080
FILE_SUPPORTS_REMOTE_STORAGE    0x00000100
FILE_VOLUME_IS_COMPRESSED       0x00008000
FILE_SUPPORTS_OBJECT_IDS        0x00010000
FILE_SUPPORTS_ENCRYPTION        0x00020000
FILE_NAMED_STREAMS              0x00040000
FILE_READ_ONLY_VOLUME           0x00080000
CREATE_NEW          1
CREATE_ALWAYS       2
OPEN_EXISTING       3
OPEN_ALWAYS         4
TRUNCATE_EXISTING   5
KEY_QUERY_VALUE                0x00000001
KEY_SET_VALUE                  0x00000002
KEY_CREATE_SUB_KEY             0x00000004
KEY_ENUMERATE_SUB_KEYS         0x00000008
KEY_NOTIFY                     0x00000010
KEY_CREATE_LINK                0x00000020
KEY_WOW64_32KEY                0x00000200
KEY_WOW64_64KEY                0x00000100
KEY_WOW64_RES                  0x00000300
KEY_READ                       0x00020019
KEY_WRITE                      0x00020006
KEY_EXECUTE                    0x00020019
KEY_ALL_ACCESS                 0x000F003F
SERVICE_QUERY_CONFIG           0x00000001
SERVICE_CHANGE_CONFIG          0x00000002
SERVICE_QUERY_STATUS           0x00000004
SERVICE_ENUMERATE_DEPENDENTS   0x00000008
SERVICE_START                  0x00000010
SERVICE_STOP                   0x00000020
SERVICE_PAUSE_CONTINUE         0x00000040
SERVICE_INTERROGATE            0x00000080
SERVICE_USER_DEFINED_CONTROL   0x00000100
SERVICE_ALL_ACCESS             0x000F01FF
POLICY_VIEW_LOCAL_INFORMATION   0x00000001
POLICY_VIEW_AUDIT_INFORMATION   0x00000002
POLICY_GET_PRIVATE_INFORMATION  0x00000004
POLICY_TRUST_ADMIN              0x00000008
POLICY_CREATE_ACCOUNT           0x00000010
POLICY_CREATE_SECRET            0x00000020
POLICY_CREATE_PRIVILEGE         0x00000040
POLICY_SET_DEFAULT_QUOTA_LIMITS 0x00000080
POLICY_SET_AUDIT_REQUIREMENTS   0x00000100
POLICY_AUDIT_LOG_ADMIN          0x00000200
POLICY_SERVER_ADMIN             0x00000400
POLICY_LOOKUP_NAMES             0x00000800
POLICY_NOTIFICATION             0x00001000
POLICY_ALL_ACCESS               0X000F0FFF
POLICY_READ                     0X00020006
POLICY_WRITE                    0X000207F8
POLICY_EXECUTE                  0X00020801
PROCESS_TERMINATE              0x00000001
PROCESS_CREATE_THREAD          0x00000002
PROCESS_SET_SESSIONID          0x00000004
PROCESS_VM_OPERATION           0x00000008
PROCESS_VM_READ                0x00000010
PROCESS_VM_WRITE               0x00000020
PROCESS_DUP_HANDLE             0x00000040
PROCESS_CREATE_PROCESS         0x00000080
PROCESS_SET_QUOTA              0x00000100
PROCESS_SET_INFORMATION        0x00000200
PROCESS_QUERY_INFORMATION      0x00000400
PROCESS_SUSPEND_RESUME         0x00000800
PROCESS_ALL_ACCESS             0x001f0fff
THREAD_TERMINATE               0x00000001
THREAD_SUSPEND_RESUME          0x00000002
THREAD_GET_CONTEXT             0x00000008
THREAD_SET_CONTEXT             0x00000010
THREAD_SET_INFORMATION         0x00000020
THREAD_QUERY_INFORMATION       0x00000040
THREAD_SET_THREAD_TOKEN        0x00000080
THREAD_IMPERSONATE             0x00000100
THREAD_DIRECT_IMPERSONATION    0x00000200
THREAD_ALL_ACCESS              0x001f03ff
EVENT_MODIFY_STATE             0x00000002
EVENT_ALL_ACCESS               0x001F0003
SEMAPHORE_MODIFY_STATE         0x00000002
SEMAPHORE_ALL_ACCESS           0x001F0003
MUTANT_QUERY_STATE             0x00000001
MUTANT_ALL_ACCESS              0x001F0001
MUTEX_MODIFY_STATE             0x00000001
MUTEX_ALL_ACCESS               0x001F0001
TIMER_QUERY_STATE              0x00000001
TIMER_MODIFY_STATE             0x00000002
TIMER_ALL_ACCESS               0x001F0003
TOKEN_ASSIGN_PRIMARY           0x00000001
TOKEN_DUPLICATE                0x00000002
TOKEN_IMPERSONATE              0x00000004
TOKEN_QUERY                    0x00000008
TOKEN_QUERY_SOURCE             0x00000010
TOKEN_ADJUST_PRIVILEGES        0x00000020
TOKEN_ADJUST_GROUPS            0x00000040
TOKEN_ADJUST_DEFAULT           0x00000080
TOKEN_ADJUST_SESSIONID         0x00000100
TOKEN_ALL_ACCESS_WINNT         0x000F00FF
TOKEN_ALL_ACCESS_WIN2K         0x000F01FF
TOKEN_READ                     0x00020008
TOKEN_WRITE                    0x000200E0
TOKEN_EXECUTE                  0x00020000
OBJECT_INHERIT_ACE                0x1
CONTAINER_INHERIT_ACE             0x2
NO_PROPAGATE_INHERIT_ACE          0x4
INHERIT_ONLY_ACE                  0x8
INHERITED_ACE                     0x10
VALID_INHERIT_FLAGS               0x1F
ACL_REVISION     2
ACL_REVISION_DS  4
ACCESS_ALLOWED_ACE_TYPE                 0x0
ACCESS_DENIED_ACE_TYPE                  0x1
SYSTEM_AUDIT_ACE_TYPE                   0x2
SYSTEM_ALARM_ACE_TYPE                   0x3
ACCESS_ALLOWED_COMPOUND_ACE_TYPE        0x4
ACCESS_ALLOWED_OBJECT_ACE_TYPE          0x5
ACCESS_DENIED_OBJECT_ACE_TYPE           0x6
SYSTEM_AUDIT_OBJECT_ACE_TYPE            0x7
SYSTEM_ALARM_OBJECT_ACE_TYPE            0x8
ACCESS_ALLOWED_CALLBACK_ACE_TYPE        0x9
ACCESS_DENIED_CALLBACK_ACE_TYPE         0xA
ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE 0xB
ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE  0xC
SYSTEM_AUDIT_CALLBACK_ACE_TYPE          0xD
SYSTEM_ALARM_CALLBACK_ACE_TYPE          0xE
SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE   0xF
SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE   0x10
OWNER_SECURITY_INFORMATION              0x00000001
GROUP_SECURITY_INFORMATION              0x00000002
DACL_SECURITY_INFORMATION               0x00000004
SACL_SECURITY_INFORMATION               0x00000008
PROTECTED_DACL_SECURITY_INFORMATION     0x80000000
PROTECTED_SACL_SECURITY_INFORMATION     0x40000000
UNPROTECTED_DACL_SECURITY_INFORMATION   0x20000000
UNPROTECTED_SACL_SECURITY_INFORMATION   0x10000000
TokenUser                      1
TokenGroups                    2
TokenPrivileges                3
TokenOwner                     4
TokenPrimaryGroup              5
TokenDefaultDacl               6
TokenSource                    7
TokenType                      8
TokenImpersonationLevel        9
TokenStatistics               10
TokenRestrictedSids           11
TokenSessionId                12
TokenGroupsAndPrivileges      13
TokenSessionReference         14
TokenSandBoxInert             15
SE_GROUP_MANDATORY              0x00000001
SE_GROUP_ENABLED_BY_DEFAULT     0x00000002
SE_GROUP_ENABLED                0x00000004
SE_GROUP_OWNER                  0x00000008
SE_GROUP_USE_FOR_DENY_ONLY      0x00000010
SE_GROUP_LOGON_ID               0xC0000000
SE_GROUP_RESOURCE               0x20000000
SE_PRIVILEGE_ENABLED_BY_DEFAULT 0x00000001
SE_PRIVILEGE_ENABLED            0x00000002
SE_PRIVILEGE_USED_FOR_ACCESS    0x80000000
SC_MANAGER_CONNECT             0x00000001
SC_MANAGER_CREATE_SERVICE      0x00000002
SC_MANAGER_ENUMERATE_SERVICE   0x00000004
SC_MANAGER_LOCK                0x00000008
SC_MANAGER_QUERY_LOCK_STATUS   0x00000010
SC_MANAGER_MODIFY_BOOT_CONFIG  0x00000020
SC_MANAGER_ALL_ACCESS          0x000F003F
SERVICE_NO_CHANGE              0xffffffff
SERVICE_KERNEL_DRIVER          0x00000001
SERVICE_FILE_SYSTEM_DRIVER     0x00000002
SERVICE_ADAPTER                0x00000004
SERVICE_RECOGNIZER_DRIVER      0x00000008
SERVICE_WIN32_OWN_PROCESS      0x00000010
SERVICE_WIN32_SHARE_PROCESS    0x00000020
SERVICE_INTERACTIVE_PROCESS    0x00000100
SERVICE_BOOT_START             0x00000000
SERVICE_SYSTEM_START           0x00000001
SERVICE_AUTO_START             0x00000002
SERVICE_DEMAND_START           0x00000003
SERVICE_DISABLED               0x00000004
SERVICE_ERROR_IGNORE           0x00000000
SERVICE_ERROR_NORMAL           0x00000001
SERVICE_ERROR_SEVERE           0x00000002
SERVICE_ERROR_CRITICAL         0x00000003
SERVICE_CONTROL_STOP                   0x00000001
SERVICE_CONTROL_PAUSE                  0x00000002
SERVICE_CONTROL_CONTINUE               0x00000003
SERVICE_CONTROL_INTERROGATE            0x00000004
SERVICE_CONTROL_SHUTDOWN               0x00000005
SERVICE_CONTROL_PARAMCHANGE            0x00000006
SERVICE_CONTROL_NETBINDADD             0x00000007
SERVICE_CONTROL_NETBINDREMOVE          0x00000008
SERVICE_CONTROL_NETBINDENABLE          0x00000009
SERVICE_CONTROL_NETBINDDISABLE         0x0000000A
SERVICE_CONTROL_DEVICEEVENT            0x0000000B
SERVICE_CONTROL_HARDWAREPROFILECHANGE  0x0000000C
SERVICE_CONTROL_POWEREVENT             0x0000000D
SERVICE_CONTROL_SESSIONCHANGE          0x0000000E
SERVICE_ACTIVE                 0x00000001
SERVICE_INACTIVE               0x00000002
SERVICE_STATE_ALL              0x00000003
SERVICE_STOPPED                        0x00000001
SERVICE_START_PENDING                  0x00000002
SERVICE_STOP_PENDING                   0x00000003
SERVICE_RUNNING                        0x00000004
SERVICE_CONTINUE_PENDING               0x00000005
SERVICE_PAUSE_PENDING                  0x00000006
SERVICE_PAUSED                         0x00000007
GA_PARENT       1
GA_ROOT         2
GA_ROOTOWNER    3
GW_HWNDFIRST        0
GW_HWNDLAST         1
GW_HWNDNEXT         2
GW_HWNDPREV         3
GW_OWNER            4
GW_CHILD            5
GW_ENABLEDPOPUP     6
GWL_WNDPROC         -4
GWL_HINSTANCE       -6
GWL_HWNDPARENT      -8
GWL_STYLE           -16
GWL_EXSTYLE         -20
GWL_USERDATA        -21
GWL_ID              -12
SW_HIDE             0
SW_SHOWNORMAL       1
SW_NORMAL           1
SW_SHOWMINIMIZED    2
SW_SHOWMAXIMIZED    3
SW_MAXIMIZE         3
SW_SHOWNOACTIVATE   4
SW_SHOW             5
SW_MINIMIZE         6
SW_SHOWMINNOACTIVE  7
SW_SHOWNA           8
SW_RESTORE          9
SW_SHOWDEFAULT      10
SW_FORCEMINIMIZE    11
WS_OVERLAPPED       0x00000000
WS_TILED            0x00000000
WS_POPUP            0x80000000
WS_CHILD            0x40000000
WS_MINIMIZE         0x20000000
WS_ICONIC           0x20000000
WS_VISIBLE          0x10000000
WS_DISABLED         0x08000000
WS_CLIPSIBLINGS     0x04000000
WS_CLIPCHILDREN     0x02000000
WS_MAXIMIZE         0x01000000
WS_BORDER           0x00800000
WS_DLGFRAME         0x00400000
WS_CAPTION          0x00C00000
WS_VSCROLL          0x00200000
WS_HSCROLL          0x00100000
WS_SYSMENU          0x00080000
WS_THICKFRAME       0x00040000
WS_SIZEBOX          0x00040000
WS_GROUP            0x00020000
WS_TABSTOP          0x00010000
WS_MINIMIZEBOX      0x00020000
WS_MAXIMIZEBOX      0x00010000
WS_EX_DLGMODALFRAME     0x00000001
WS_EX_NOPARENTNOTIFY    0x00000004
WS_EX_TOPMOST           0x00000008
WS_EX_ACCEPTFILES       0x00000010
WS_EX_TRANSPARENT       0x00000020
WS_EX_MDICHILD          0x00000040
WS_EX_TOOLWINDOW        0x00000080
WS_EX_WINDOWEDGE        0x00000100
WS_EX_CLIENTEDGE        0x00000200
WS_EX_CONTEXTHELP       0x00000400
WS_EX_RIGHT             0x00001000
WS_EX_LEFT              0x00000000
WS_EX_RTLREADING        0x00002000
WS_EX_LTRREADING        0x00000000
WS_EX_LEFTSCROLLBAR     0x00004000
WS_EX_RIGHTSCROLLBAR    0x00000000
WS_EX_CONTROLPARENT     0x00010000
WS_EX_STATICEDGE        0x00020000
WS_EX_APPWINDOW         0x00040000
CS_VREDRAW          0x0001
CS_HREDRAW          0x0002
CS_DBLCLKS          0x0008
CS_OWNDC            0x0020
CS_CLASSDC          0x0040
CS_PARENTDC         0x0080
CS_NOCLOSE          0x0200
CS_SAVEBITS         0x0800
CS_BYTEALIGNCLIENT  0x1000
CS_BYTEALIGNWINDOW  0x2000
CS_GLOBALCLASS      0x4000
SWP_NOSIZE          0x0001
SWP_NOMOVE          0x0002
SWP_NOZORDER        0x0004
SWP_NOREDRAW        0x0008
SWP_NOACTIVATE      0x0010
SWP_FRAMECHANGED    0x0020
SWP_DRAWFRAME       0x0020
SWP_SHOWWINDOW      0x0040
SWP_HIDEWINDOW      0x0080
SWP_NOCOPYBITS      0x0100
SWP_NOOWNERZORDER   0x0200
SWP_NOREPOSITION    0x0200
SWP_NOSENDCHANGING  0x0400
SWP_DEFERERASE      0x2000
SWP_ASYNCWINDOWPOS  0x4000
SMTO_NORMAL         0x0000
SMTO_BLOCK          0x0001
SMTO_ABORTIFHUNG    0x0002
HWND_TOP         0
HWND_BOTTOM      1
HWND_TOPMOST    -1
HWND_NOTOPMOST  -2
WM_NULL                         0x0000
WM_CREATE                       0x0001
WM_DESTROY                      0x0002
WM_MOVE                         0x0003
WM_SIZE                         0x0005
WM_ACTIVATE                     0x0006
WM_SETFOCUS                     0x0007
WM_KILLFOCUS                    0x0008
WM_ENABLE                       0x000A
WM_SETREDRAW                    0x000B
WM_SETTEXT                      0x000C
WM_GETTEXT                      0x000D
WM_GETTEXTLENGTH                0x000E
WM_PAINT                        0x000F
WM_CLOSE                        0x0010
WM_QUERYENDSESSION              0x0011
WM_QUERYOPEN                    0x0013
WM_ENDSESSION                   0x0016
WM_QUIT                         0x0012
WM_ERASEBKGND                   0x0014
WM_SYSCOLORCHANGE               0x0015
WM_SHOWWINDOW                   0x0018
WM_WININICHANGE                 0x001A
WM_SETTINGCHANGE                WM_WININICHANGE
WM_DEVMODECHANGE                0x001B
WM_ACTIVATEAPP                  0x001C
WM_FONTCHANGE                   0x001D
WM_TIMECHANGE                   0x001E
WM_CANCELMODE                   0x001F
WM_SETCURSOR                    0x0020
WM_MOUSEACTIVATE                0x0021
WM_CHILDACTIVATE                0x0022
WM_QUEUESYNC                    0x0023
WM_GETMINMAXINFO                0x0024
PERF_DETAIL_NOVICE          100
PERF_DETAIL_ADVANCED        200
PERF_DETAIL_EXPERT          300
PERF_DETAIL_WIZARD          400
PDH_FMT_RAW     0x00000010
PDH_FMT_ANSI    0x00000020
PDH_FMT_UNICODE 0x00000040
PDH_FMT_LONG    0x00000100
PDH_FMT_DOUBLE  0x00000200
PDH_FMT_LARGE   0x00000400
PDH_FMT_NOSCALE 0x00001000
PDH_FMT_1000    0x00002000
PDH_FMT_NODATA  0x00004000
PDH_FMT_NOCAP100 0x00008000
PERF_DETAIL_COSTLY   0x00010000
PERF_DETAIL_STANDARD 0x0000FFFF
UF_SCRIPT                          0x0001
UF_ACCOUNTDISABLE                  0x0002
UF_HOMEDIR_REQUIRED                0x0008
UF_LOCKOUT                         0x0010
UF_PASSWD_NOTREQD                  0x0020
UF_PASSWD_CANT_CHANGE              0x0040
UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED 0x0080
UF_TEMP_DUPLICATE_ACCOUNT       0x0100
UF_NORMAL_ACCOUNT               0x0200
UF_INTERDOMAIN_TRUST_ACCOUNT    0x0800
UF_WORKSTATION_TRUST_ACCOUNT    0x1000
UF_SERVER_TRUST_ACCOUNT         0x2000
UF_DONT_EXPIRE_PASSWD           0x10000
UF_MNS_LOGON_ACCOUNT            0x20000
UF_SMARTCARD_REQUIRED           0x40000
UF_TRUSTED_FOR_DELEGATION       0x80000
UF_NOT_DELEGATED               0x100000
UF_USE_DES_KEY_ONLY            0x200000
UF_DONT_REQUIRE_PREAUTH        0x400000
UF_PASSWORD_EXPIRED            0x800000
UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION 0x1000000
FILE_CASE_PRESERVED_NAMES       0x00000002
FILE_UNICODE_ON_DISK            0x00000004
FILE_PERSISTENT_ACLS            0x00000008
FILE_FILE_COMPRESSION           0x00000010
FILE_VOLUME_QUOTAS              0x00000020
FILE_SUPPORTS_SPARSE_FILES      0x00000040
FILE_SUPPORTS_REPARSE_POINTS    0x00000080
FILE_SUPPORTS_REMOTE_STORAGE    0x00000100
FILE_VOLUME_IS_COMPRESSED       0x00008000
FILE_SUPPORTS_OBJECT_IDS        0x00010000
FILE_SUPPORTS_ENCRYPTION        0x00020000
FILE_NAMED_STREAMS              0x00040000
FILE_READ_ONLY_VOLUME           0x00080000
KEYEVENTF_EXTENDEDKEY 0x0001
KEYEVENTF_KEYUP       0x0002
KEYEVENTF_UNICODE     0x0004
KEYEVENTF_SCANCODE    0x0008
MOUSEEVENTF_MOVE        0x0001
MOUSEEVENTF_LEFTDOWN    0x0002
MOUSEEVENTF_LEFTUP      0x0004
MOUSEEVENTF_RIGHTDOWN   0x0008
MOUSEEVENTF_RIGHTUP     0x0010
MOUSEEVENTF_MIDDLEDOWN  0x0020
MOUSEEVENTF_MIDDLEUP    0x0040
MOUSEEVENTF_XDOWN       0x0080
MOUSEEVENTF_XUP         0x0100
MOUSEEVENTF_WHEEL       0x0800
MOUSEEVENTF_VIRTUALDESK 0x4000
MOUSEEVENTF_ABSOLUTE    0x8000
XBUTTON1      0x0001
XBUTTON2      0x0002
VK_BACK           0x08
VK_TAB            0x09
VK_CLEAR          0x0C
VK_RETURN         0x0D
VK_SHIFT          0x10
VK_CONTROL        0x11
VK_MENU           0x12
VK_PAUSE          0x13
VK_CAPITAL        0x14
VK_KANA           0x15
VK_HANGEUL        0x15
VK_HANGUL         0x15
VK_JUNJA          0x17
VK_FINAL          0x18
VK_HANJA          0x19
VK_KANJI          0x19
VK_ESCAPE         0x1B
VK_CONVERT        0x1C
VK_NONCONVERT     0x1D
VK_ACCEPT         0x1E
VK_MODECHANGE     0x1F
VK_SPACE          0x20
VK_PRIOR          0x21
VK_NEXT           0x22
VK_END            0x23
VK_HOME           0x24
VK_LEFT           0x25
VK_UP             0x26
VK_RIGHT          0x27
VK_DOWN           0x28
VK_SELECT         0x29
VK_PRINT          0x2A
VK_EXECUTE        0x2B
VK_SNAPSHOT       0x2C
VK_INSERT         0x2D
VK_DELETE         0x2E
VK_HELP           0x2F
VK_LWIN           0x5B
VK_RWIN           0x5C
VK_APPS           0x5D
VK_SLEEP          0x5F
VK_NUMPAD0        0x60
VK_NUMPAD1        0x61
VK_NUMPAD2        0x62
VK_NUMPAD3        0x63
VK_NUMPAD4        0x64
VK_NUMPAD5        0x65
VK_NUMPAD6        0x66
VK_NUMPAD7        0x67
VK_NUMPAD8        0x68
VK_NUMPAD9        0x69
VK_MULTIPLY       0x6A
VK_ADD            0x6B
VK_SEPARATOR      0x6C
VK_SUBTRACT       0x6D
VK_DECIMAL        0x6E
VK_DIVIDE         0x6F
VK_F1             0x70
VK_F2             0x71
VK_F3             0x72
VK_F4             0x73
VK_F5             0x74
VK_F6             0x75
VK_F7             0x76
VK_F8             0x77
VK_F9             0x78
VK_F10            0x79
VK_F11            0x7A
VK_F12            0x7B
VK_F13            0x7C
VK_F14            0x7D
VK_F15            0x7E
VK_F16            0x7F
VK_F17            0x80
VK_F18            0x81
VK_F19            0x82
VK_F20            0x83
VK_F21            0x84
VK_F22            0x85
VK_F23            0x86
VK_F24            0x87
VK_NUMLOCK        0x90
VK_SCROLL         0x91
VK_LSHIFT         0xA0
VK_RSHIFT         0xA1
VK_LCONTROL       0xA2
VK_RCONTROL       0xA3
VK_LMENU          0xA4
VK_RMENU          0xA5
VK_BROWSER_BACK        0xA6
VK_BROWSER_FORWARD     0xA7
VK_BROWSER_REFRESH     0xA8
VK_BROWSER_STOP        0xA9
VK_BROWSER_SEARCH      0xAA
VK_BROWSER_FAVORITES   0xAB
VK_BROWSER_HOME        0xAC
VK_VOLUME_MUTE         0xAD
VK_VOLUME_DOWN         0xAE
VK_VOLUME_UP           0xAF
VK_MEDIA_NEXT_TRACK    0xB0
VK_MEDIA_PREV_TRACK    0xB1
VK_MEDIA_STOP          0xB2
VK_MEDIA_PLAY_PAUSE    0xB3
VK_LAUNCH_MAIL         0xB4
VK_LAUNCH_MEDIA_SELECT 0xB5
VK_LAUNCH_APP1         0xB6
VK_LAUNCH_APP2         0xB7
SND_SYNC            0x0000
SND_ASYNC           0x0001
SND_NODEFAULT       0x0002
SND_MEMORY          0x0004
SND_LOOP            0x0008
SND_NOSTOP          0x0010
SND_NOWAIT      0x00002000
SND_ALIAS       0x00010000
SND_ALIAS_ID    0x00110000
SND_FILENAME    0x00020000
SND_RESOURCE    0x00040004
SND_PURGE           0x0040
SND_APPLICATION     0x0080
STYPE_DISKTREE          0
STYPE_PRINTQ            1
STYPE_DEVICE            2
STYPE_IPC               3
STYPE_TEMPORARY         0x40000000
STYPE_SPECIAL           0x80000000
LOGON32_LOGON_INTERACTIVE       2
LOGON32_LOGON_NETWORK           3
LOGON32_LOGON_BATCH             4
LOGON32_LOGON_SERVICE           5
LOGON32_LOGON_UNLOCK            7
LOGON32_LOGON_NETWORK_CLEARTEXT 8
LOGON32_LOGON_NEW_CREDENTIALS   9
LOGON32_PROVIDER_DEFAULT    0
LOGON32_PROVIDER_WINNT35    1
LOGON32_PROVIDER_WINNT40    2
LOGON32_PROVIDER_WINNT50    3
}
proc twapi::list_raw_api {} {
set rawapi [list ]
foreach fn [info commands ::twapi::*] {
if {[regexp {^::twapi::([A-Z][^_]*)$} $fn ignore fn]} {
lappend rawapi $fn
}
}
return $rawapi
}
proc twapi::close_handles {args} {
foreach h [concat $args] {
if {[catch {CloseHandle $h} msg]} {
set erinfo $::errorInfo
set ercode $::errorCode
set ermsg $msg
}
}
if {[info exists erinfo]} {
error $msg $erinfo $ercode
}
}
proc twapi::get_tcl_channel_handle {chan direction} {
set direction [expr {[string equal $direction "write"] ? 1 : 0}]
return [Tcl_GetChannelHandle $chan $direction]
}
proc twapi::wait {script guard wait_ms {gap_ms 10}} {
if {$gap_ms == 0} {
set gap_ms 10
}
set end_ms [expr {[clock clicks -milliseconds] + $wait_ms}]
while {[clock clicks -milliseconds] < $end_ms} {
set script_result [uplevel $script]
if {[string equal $script_result $guard]} {
return 1
}
after $gap_ms
}
return [string equal [uplevel $script] $guard]
}
proc twapi::get_version {args} {
array set opts [parseargs args {patchlevel}]
if {$opts(patchlevel)} {
return $twapi::patchlevel
} else {
return $twapi::version
}
}
proc twapi::_array_set_all {v_arr val} {
upvar $v_arr arr
foreach e [array names arr] {
set arr($e) $val
}
}
proc twapi::_array_non_zero_entry {v_arr indices} {
upvar $v_arr arr
foreach i $indices {
if {$arr($i)} {
return 1
}
}
return 0
}
proc twapi::_array_non_zero_switches {v_arr indices all} {
upvar $v_arr arr
set result [list ]
foreach i $indices {
if {$all || ([info exists arr($i)] && $arr($i))} {
lappend result -$i
}
}
return $result
}
proc twapi::swig_struct_fields {structptr structname} {
set result [list ]
foreach fieldcmd [info commands :::twapi::${structname}_*_get] {
if {[catch {$fieldcmd $structptr} fieldval] == 0} {
regexp "${structname}_(.*)_get" $fieldcmd dontcare fieldname
lappend result $fieldname $fieldval
}
}
return $result
}
proc twapi::setbits {v_bits mask} {
upvar $v_bits bits
set bits [expr {int($bits) | int($mask)}]
return $bits
}
proc twapi::resetbits {v_bits mask} {
upvar $v_bits bits
set bits [expr {int($bits) & int(~ $mask)}]
return $bits
}
proc twapi::assignbits {v_bits value {mask -1}} {
upvar $v_bits bits
set bits [expr {(int($bits) & int(~ $mask)) | (int($value) & int($mask))}]
return $bits
}
proc twapi::_parse_symbolic_bitmask {syms symvals} {
if {[llength $symvals] == 1} {
upvar $symvals lookup
} else {
array set lookup $symvals
}
set bits 0
foreach sym $syms {
if {[info exists lookup($sym)]} {
set bits [expr {$bits | $lookup($sym)}]
} else {
set bits [expr {$bits | $sym}]
}
}
return $bits
}
proc twapi::_make_symbolic_bitmask {bits symvals {append_unknown 1}} {
if {[llength $symvals] == 1} {
upvar $symvals lookup
set map [array get lookup]
} else {
set map $symvals
}
set symbits 0
set symmask [list ]
foreach {sym val} $map {
if {$bits & $val} {
set symbits [expr {$symbits | $val}]
lappend symmask $sym
}
}
set bits [expr {$bits & ~$symbits}]
if {$bits && $append_unknown} {
lappend symmask $bits
}
return $symmask
}
proc twapi::_switches_to_bitmask {switches symvals {bits 0}} {
if {[llength $symvals] == 1} {
upvar $symvals lookup
} else {
array set lookup $symvals
}
if {[llength $switches] == 1} {
upvar $switches swtable
} else {
array set swtable $switches
}
foreach {switch bool} [array get swtable] {
if {$bool} {
set bits [expr {$bits | $lookup($switch)}]
} else {
set bits [expr {$bits & ~ $lookup($switch)}]
}
}
return $bits
}
proc twapi::_bitmask_to_switches {bits symvals} {
if {[llength $symvals] == 1} {
upvar $symvals lookup
set map [array get lookup]
} else {
set map $symvals
}
set symbits 0
set symmask [list ]
foreach {sym val} $map {
if {$bits & $val} {
set symbits [expr {$symbits | $val}]
lappend symmask $sym 1
} else {
lappend symmask $sym 0
}
}
return $symmask
}
proc twapi::kl_create {args} {
if {[llength $args] & 1} {
error "No value specified for keyed list field [lindex $args end]. A keyed list must have an even number of elements."
}
return $args
}
proc twapi::kl_create2 {flds vals} {
set l [list ]
foreach fld $flds val $vals {
lappend l $fld $val
}
return $l
}
interp alias {} ::twapi::kl_get_default {} ::twapi::kl_get
proc twapi::kl_set {kl field newval} {
set i 0
foreach {fld val} $kl {
if {[string equal $fld $field]} {
incr i
return [lreplace $kl $i $i $newval]
}
incr i 2
}
lappend kl $field $newval
return $kl
}
proc twapi::kl_vget {kl field varname} {
upvar $varname var
return [expr {! [catch {set var [kl_get $kl $field]}]}]
}
proc twapi::kl_unset {kl field} {
array set arr $kl
unset -nocomplain arr($field)
return [array get arr]
}
proc twapi::kl_equal {kl_a kl_b} {
array set a $kl_a
foreach {kb valb} $kl_b {
if {[info exists a($kb)] && ($a($kb) == $valb)} {
unset a($kb)
} else {
return 0
}
}
if {[array size a]} {
return 0
} else {
return 1
}
}
proc twapi::kl_fields {kl} {
set fields [list ]
foreach {fld val} $kl {
lappend fields $fld
}
return $fields
}
proc twapi::kl_flatten {list_of_kl args} {
set result {}
foreach kl $list_of_kl {
foreach field $args {
lappend result [kl_get $kl $field]
}
}
return $result
}
proc twapi::_kl_print {kl args} {
if {[llength $args] == 1} {
puts [kl_get $kl [lindex $args 0]]
return
}
if {[llength $args] == 0} {
set args [kl_fields $kl]
}
foreach field $args {
puts "$field: [kl_get $kl $field]"
}
return
}
proc twapi::get_array_as_options {v_arr} {
upvar $v_arr arr
set result [list ]
foreach {index value} [array get arr] {
lappend result -$index $value
}
return $result
}
proc twapi::_is_swig_ptr {p} {
return [regexp {^_[[:xdigit:]]{8}_p_} $p]
}
proc twapi::_is_win32_handle {h} {
return [regexp {^_[[:xdigit:]]{8}_HANDLE} $h]
}
proc twapi::_cast_swig_ptr {p newtype} {
if {$p eq "NULL"} {
return $p
}
return "[string range $p 0 11]$newtype"
}
proc twapi::_parse_integer_pair {pair {msg "Invalid integer pair"}} {
if {[llength $pair] == 2} {
foreach {first second} $pair break
if {[string is integer -strict $first] &&
[string is integer -strict $second]} {
return [list $first $second]
}
} elseif {[regexp {^([[:digit:]]+),([[:digit:]]+)$} $pair dummy first second]} {
return [list $first $second]
}
error "$msg: '$pair'. Should be a list of two integers or in the form 'x,y'"
}
proc twapi::_map_console_color {colors background} {
set attr 0
foreach color $colors {
switch -exact -- $color {
blue   {setbits attr 1}
green  {setbits attr 2}
red    {setbits attr 4}
white  {setbits attr 7}
bright {setbits attr 8}
black  { }
default {error "Unknown color name $color"}
}
}
if {$background} {
set attr [expr {$attr << 4}]
}
return $attr
}
proc twapi::_normalize_path {path} {
global env
regsub {^[\\/]\?\?[\\/](.*)} $path {\1} path
catch {set systemroot $env(WINDIR)}
catch {set systemroot $env(SYSTEMROOT)}
regsub -nocase {^[\\/]systemroot([\\/].*)} $path "${systemroot}\\1" path
return $path
}
interp alias {} twapi::large_system_time_to_secs {} twapi::large_system_time_to_secs_since_1970
proc twapi::large_system_time_to_secs_since_1970 {ns100 {fraction false}} {
set ns100_since_1970 [expr {wide($ns100)-wide(116444736000000000)}]
if {0} {
set secs_since_1970 [expr {wide($ns100_since_1970)/wide(10000000)}]
if {$fraction} {
append secs_since_1970 .[expr {wide($ns100_since_1970)%wide(10000000)}]
}
} else {
if {[string length $ns100_since_1970] > 7} {
set secs_since_1970 [string range $ns100_since_1970 0 end-7]
if {$fraction} {
set frac [string range $ns100_since_1970 end-6 end]
append secs_since_1970 .$frac
}
} else {
set secs_since_1970 0
if {$fraction} {
set frac [string range "0000000${ns100_since_1970}" end-6 end]
append secs_since_1970 .$frac
}
}
}
return $secs_since_1970
}
proc twapi::secs_since_1970_to_large_system_time {secs} {
set ns100 "${secs}0000000"
return [expr {$ns100 + wide(116444736000000000)}]
}
interp alias {} ::twapi::get_system_time {} ::twapi::GetSystemTimeAsFileTime
interp alias {} ::twapi::large_system_time_to_timelist {} ::twapi::FileTimeToSystemTime
interp alias {} ::twapi::timelist_to_large_system_time {} ::twapi::SystemTimeToFileTime
proc twapi::_seconds_to_timelist {secs} {
set result [list ]
foreach x [clock format $secs -format "%Y %m %e %k %M %S 0" -gmt false] {
lappend result [scan $x %d]
}
return $result
}
proc twapi::_timelist_to_seconds {timelist} {
return [clock scan [_timelist_to_timestring $timelist] -gmt false]
}
proc twapi::_timelist_to_timestring {timelist} {
if {[llength $timelist] < 6} {
error "Invalid time list format"
}
return "[lindex $timelist 0]-[lindex $timelist 1]-[lindex $timelist 2] [lindex $timelist 3]:[lindex $timelist 4]:[lindex $timelist 5]"
}
proc twapi::_timestring_to_timelist {timestring} {
return [_seconds_to_timelist [clock scan $timestring -gmt false]]
}
proc twapi::malloc_and_cast {size type {size_field 0}} {
set mem [malloc $size]
if {$size_field} {
Twapi_WriteMemoryInt $mem 0 $size $size_field
}
return [_cast_swig_ptr $mem $type]
}
proc twapi::malloc_binary {args} {
array set opts [parseargs args {
size.int
type.arg
}]
set bin [eval [list binary format] $args]
if {![info exists opts(size)]} {
set opts(size) [string length $bin]
}
set p [malloc $opts(size)]
Twapi_WriteMemoryBinary $p 0 $opts(size) $bin
if {[info exists opts(type)]} {
return [_cast_swig_ptr $p $opts(type)]
}
return $p
}
proc twapi::mem_binary_scan {mem off mem_sz args} {
uplevel [list binary scan [Twapi_ReadMemoryBinary $mem $off $mem_sz]] $args
}
proc twapi::_validate_guid {guid} {
if {![regexp {^\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}$} $guid]} {
error "Invalid GUID syntax: '$guid'"
}
}
proc twapi::_ucs16_binary_to_string {bin {off 0}} {
return [encoding convertfrom unicode [string range $bin $off [string first \0\0\0 $bin]]]
}
proc twapi::_binary_to_guid {bin {off 0}} {
if {[binary scan $bin "@$off i s s H4 H12" g1 g2 g3 g4 g5] != 5} {
error "Invalid GUID binary"
}
return [format "{%8.8X-%2.2hX-%2.2hX-%s}" $g1 $g2 $g3 [string toupper "$g4-$g5"]]
}
proc twapi::_guid_to_binary {guid} {
_validate_guid $guid
foreach {g1 g2 g3 g4 g5} [split [string range $guid 1 end-1] -] break
return [binary format "i s s H4 H12" 0x$g1 0x$g2 0x$g3 $g4 $g5]
}
proc twapi::_decode_mem_guid {mem {off 0}} {
return [_binary_to_guid [Twapi_ReadMemoryBinary $mem $off 16]]
}
proc twapi::_decode_mem_registry_value {type mem len {off 0}} {
set type [expr {$type}];    # Convert hex etc. to decimal form
switch -exact -- $type {
1 -
2 {
return [list [expr {$type == 2 ? "expand_sz" : "sz"}] \
[Twapi_ReadMemoryUnicode $mem $off -1]]
}
7 {
set multi [list ]
while {1} {
set str [Twapi_ReadMemoryUnicode $mem $off -1]
set n [string length $str]
if {($len != -1) && ($off+$n+1) > $len} {
error "Possible memory corruption: read memory beyond specified memory size."
}
if {$n == 0} {
return [list multi_sz $multi]
}
lappend multi $str
incr off [expr {2*($n+1)}]
}
}
4 {
if {$len < 4} {
error "Insufficient number of bytes to convert to integer."
}
return [list dword [Twapi_ReadMemoryInt $mem $off]]
}
5 {
if {$len < 4} {
error "Insufficient number of bytes to convert to big-endian integer."
}
set type "dword_big_endian"
set scanfmt "I"
set len 4
}
11 {
if {$len < 8} {
error "Insufficient number of bytes to convert to wide integer."
}
set type "qword"
set scanfmt "w"
set len 8
}
0 { set type "none" }
6 { set type "link" }
8 { set type "resource_list" }
3 { set type "binary" }
default {
error "Unsupported registry value type '$type'"
}
}
set val [Twapi_ReadMemoryBinary $mem $off $len]
if {[info exists scanfmt]} {
if {[binary scan $val $scanfmt val] != 1} {
error "Could not convert from binary value using scan format $scanfmt"
}
}
return [list $type $val]
}
proc twapi::debug_puts {msg {fd stderr}} {
puts $fd $msg; flush $fd
}
proc twapi::_log_timestamp {} {
return [clock format [clock seconds] -format "%a %T"]
}
if {[file extension [info script]] ne ".tm"} {
foreach ::twapi::_field_ {
osinfo.tcl
security.tcl
process.tcl
disk.tcl
} {
source [file join [file dirname [info script]] $::twapi::_field_]
}
if {[lsearch [::twapi::get_build_config] nodesktop] < 0} {
foreach ::twapi::_field_ {
ui.tcl
clipboard.tcl
shell.tcl
nls.tcl
com.tcl
} {
source [file join [file dirname [info script]] $::twapi::_field_]
}
}
if {[lsearch [::twapi::get_build_config] noserver] < 0} {
foreach ::twapi::_field_ {
services.tcl
eventlog.tcl
} {
source [file join [file dirname [info script]] $::twapi::_field_]
}
}
if {[lsearch [::twapi::get_build_config] lean] < 0} {
foreach ::twapi::_field_ {
process2.tcl
accounts.tcl
pdh.tcl
share.tcl
network.tcl
console.tcl
synch.tcl
desktop.tcl
printer.tcl
mstask.tcl
msi.tcl
crypto.tcl
device.tcl
power.tcl
} {
source [file join [file dirname [info script]] $::twapi::_field_]
}
}
unset twapi::_field_
}
proc twapi::_get_public_procs {} {
set public_procs {}
foreach p [info procs] {
if {![regexp {^([_A-Z]|try)} $p]} {
lappend public_procs $p
}
}
foreach p [interp aliases] {
if {[string match "twapi::*" $p]} {
lappend public_procs [string range $p 7 end]
} elseif {[string match "::twapi::*" $p]} {
lappend public_procs [string range $p 9 end]
}
}
return $public_procs
}
namespace eval twapi {
variable my_process_handle [GetCurrentProcess]
}
proc twapi::export_public_commands {} {
uplevel #0 [list namespace eval twapi [list eval namespace export [::twapi::_get_public_procs]]]
}
proc twapi::import_commands {} {
export_public_commands
uplevel namespace import twapi::*
}
package provide $::twapi::dll_base_name $twapi::patchlevel
if {[llength [info commands tkcon*]]} {
twapi::import_commands
}
#-- from accounts.tcl
proc twapi::get_users {args} {
array set opts [parseargs args {system.arg} -nulldefault]
return [Twapi_NetUserEnum $opts(system) 0]
}
proc twapi::new_user {username args} {
array set opts [parseargs args [list \
system.arg \
password.arg \
comment.arg \
[list priv.arg "user" [array names twapi::priv_level_map]] \
home_dir.arg \
script_path.arg \
] \
-nulldefault]
NetUserAdd $opts(system) $username $opts(password) 1 \
$opts(home_dir) $opts(comment) 0 $opts(script_path)
try {
set_user_priv_level $username $opts(priv) -system $opts(system)
} onerror {} {
set ecode $errorCode
set einfo $errorInfo
catch {delete_user $username -system $opts(system)}
error $errorResult $einfo $ecode
}
}
proc twapi::delete_user {username args} {
eval set [parseargs args {system.arg} -nulldefault]
_delete_rights $username $system
NetUserDel $system $username
}
foreach twapi::_field_ {name password home_dir comment script_path full_name country_code profile home_dir_drive} {
proc twapi::set_user_$::twapi::_field_ {username fieldval args} "
array set opts \[parseargs args {
system.arg
} -nulldefault \]
Twapi_NetUserSetInfo_$::twapi::_field_ \$opts(system) \$username \$fieldval"
}
unset twapi::_field_
proc twapi::set_user_priv_level {username priv_level args} {
eval set [parseargs args {system.arg} -nulldefault]
if {0} {
if {![info exists twapi::priv_level_map($priv_level)]} {
error "Invalid privilege level value '$priv_level' specified. Must be one of [join [array names twapi::priv_level_map] ,]"
}
set priv $twapi::priv_level_map($priv_level)
Twapi_NetUserSetInfo_priv $system $username $priv
} else {
variable builtin_account_sids
switch -exact -- $priv_level {
guest {
set outgroups {administrators users}
set ingroup guests
}
user  {
set outgroups {administrators}
set ingroup users
}
admin {
set outgroups {}
set ingroup administrators
}
default {error "Invalid privilege level '$priv_level'. Must be one of 'guest', 'user' or 'admin'"}
}
foreach outgroup $outgroups {
set group [lookup_account_sid $builtin_account_sids($outgroup)]
catch {remove_member_from_local_group $group $username}
}
set group [lookup_account_sid $builtin_account_sids($ingroup)]
add_member_to_local_group $group $username
}
}
proc twapi::set_user_expiration {username time args} {
eval set [parseargs args {system.arg} -nulldefault]
if {[string equal $time "never"]} {
set time -1
} else {
set time [clock scan $time]
}
Twapi_NetUserSetInfo_acct_expires $system $username $time
}
proc twapi::unlock_user {username args} {
eval [list _change_usri3_flags $username $twapi::windefs(UF_LOCKOUT) 0] $args
}
proc twapi::enable_user {username args} {
eval [list _change_usri3_flags $username $twapi::windefs(UF_ACCOUNTDISABLE) 0] $args
}
proc twapi::disable_user {username args} {
variable windefs
eval [list _change_usri3_flags $username $windefs(UF_ACCOUNTDISABLE) $windefs(UF_ACCOUNTDISABLE)] $args
}
proc twapi::get_user_account_info {account args} {
variable windefs
array set fields {
comment {usri3_comment 1}
password_expired {usri3_password_expired 3}
full_name {usri3_full_name 2}
parms {usri3_parms 2}
units_per_week {usri3_units_per_week 2}
primary_group_id {usri3_primary_group_id 3}
status {usri3_flags 1}
logon_server {usri3_logon_server 2}
country_code {usri3_country_code 2}
home_dir {usri3_home_dir 1}
password_age {usri3_password_age 1}
home_dir_drive {usri3_home_dir_drive 3}
num_logons {usri3_num_logons 2}
acct_expires {usri3_acct_expires 2}
last_logon {usri3_last_logon 2}
user_id {usri3_user_id 3}
usr_comment {usri3_usr_comment 2}
bad_pw_count {usri3_bad_pw_count 2}
code_page {usri3_code_page 2}
logon_hours {usri3_logon_hours 2}
workstations {usri3_workstations 2}
last_logoff {usri3_last_logoff 2}
name {usri3_name 0}
script_path {usri3_script_path 1}
priv {usri3_priv 1}
profile {usri3_profile 3}
max_storage {usri3_max_storage 2}
}
array set opts [parseargs args \
[concat [array names fields] \
[list sid local_groups global_groups system.arg all]] \
-nulldefault]
if {$opts(all)} {
foreach field [array names fields] {
set opts($field) 1
}
set opts(local_groups) 1
set opts(global_groups) 1
set opts(sid) 1
}
set level 0
foreach {field fielddata} [array get fields] {
if {[lindex $fielddata 1] > $level} {
set level [lindex $fielddata 1]
}
}
array set data [NetUserGetInfo $opts(system) $account $level]
array set result [list ]
foreach {field fielddata} [array get fields] {
if {$opts($field)} {
set result($field) $data([lindex $fielddata 0])
}
}
if {$opts(status)} {
if {$result(status) & $windefs(UF_ACCOUNTDISABLE)} {
set result(status) "disabled"
} elseif {$result(status) & $windefs(UF_LOCKOUT)} {
set result(status) "locked"
} else {
set result(status) "enabled"
}
}
if {[info exists result(logon_hours)]} {
binary scan $result(logon_hours) b* result(logon_hours)
}
foreach time_field {acct_expires last_logon last_logoff} {
if {[info exists result($time_field)]} {
if {$result($time_field) == -1} {
set result($time_field) "never"
} elseif {$result($time_field) == 0} {
set result($time_field) "unknown"
} else {
set result($time_field) [clock format $result($time_field) -gmt 1]
}
}
}
if {[info exists result(priv)]} {
switch -exact -- [expr {$result(priv) & 3}] {
0 { set result(priv) "guest" }
1 { set result(priv) "user" }
2 { set result(priv) "admin" }
}
}
if {$opts(local_groups)} {
set result(local_groups) [NetUserGetLocalGroups $opts(system) $account 0]
}
if {$opts(global_groups)} {
set result(global_groups) [NetUserGetGroups $opts(system) $account]
}
if {$opts(sid)} {
set result(sid) [lookup_account_name $account -system $opts(system)]
}
return [get_array_as_options result]
}
proc twapi::get_user_local_groups_recursive {account args} {
array set opts [parseargs args {
system.arg
} -nulldefault -maxleftover 0]
return [NetUserGetLocalGroups $opts(system) [map_account_to_name $account] 1]
}
proc twapi::set_user_account_info {account args} {
variable windefs
set notspecified "3kjafnq2or2034r12"; # Some junk
array set opts [parseargs args {
{system.arg ""}
comment.arg
full_name.arg
country_code.arg
home_dir.arg
home_dir.arg
acct_expires.arg
name.arg
script_path.arg
priv.arg
profile.arg
}]
if {[info exists opts(comment)]} {
set_user_comment $account $opts(comment) -system $opts(system)
}
if {[info exists opts(full_name)]} {
set_user_full_name $account $opts(full_name) -system $opts(system)
}
if {[info exists opts(country_code)]} {
set_user_country_code $account $opts(country_code) -system $opts(system)
}
if {[info exists opts(home_dir)]} {
set_user_home_dir $account $opts(home_dir) -system $opts(system)
}
if {[info exists opts(home_dir_drive)]} {
set_user_home_dir_drive $account $opts(home_dir_drive) -system $opts(system)
}
if {[info exists opts(acct_expires)]} {
set_user_expiration $account $opts(acct_expires) -system $opts(system)
}
if {[info exists opts(name)]} {
set_user_name $account $opts(name) -system $opts(system)
}
if {[info exists opts(script_path)]} {
set_user_script_path $account $opts(script_path) -system $opts(system)
}
if {[info exists opts(priv)]} {
set_user_priv_level $account $opts(priv) -system $opts(system)
}
if {[info exists opts(profile)]} {
set_user_profile $account $opts(profile) -system $opts(system)
}
}
proc twapi::get_global_group_info {name args} {
array set opts [parseargs args {
{system.arg ""}
comment
name
members
sid
all
} -maxleftover 0]
set result [list ]
if {$opts(all) || $opts(sid)} {
lappend result -sid [lookup_account_name $name -system $opts(system)]
}
if {$opts(all) || $opts(comment) || $opts(name)} {
array set info [NetGroupGetInfo $opts(system) $name 1]
if {$opts(all) || $opts(name)} {
lappend result -name $info(grpi3_name)
}
if {$opts(all) || $opts(comment)} {
lappend result -comment $info(grpi3_comment)
}
}
if {$opts(all) || $opts(members)} {
lappend result -members [get_global_group_members $name -system $opts(system)]
}
return $result
}
proc twapi::get_local_group_info {name args} {
array set opts [parseargs args {
{system.arg ""}
comment
name
members
sid
all
} -maxleftover 0]
set result [list ]
if {$opts(all) || $opts(sid)} {
lappend result -sid [lookup_account_name $name -system $opts(system)]
}
if {$opts(all) || $opts(comment) || $opts(name)} {
array set info [NetLocalGroupGetInfo $opts(system) $name 1]
if {$opts(all) || $opts(name)} {
lappend result -name $info(lgrpi1_name)
}
if {$opts(all) || $opts(comment)} {
lappend result -comment $info(lgrpi1_comment)
}
}
if {$opts(all) || $opts(members)} {
lappend result -members [get_local_group_members $name -system $opts(system)]
}
return $result
}
proc twapi::get_global_groups {args} {
array set opts [parseargs args {system.arg} -nulldefault]
return [NetGroupEnum $opts(system)]
}
proc twapi::get_local_groups {args} {
array set opts [parseargs args {system.arg} -nulldefault]
return [NetLocalGroupEnum $opts(system)]
}
proc twapi::new_global_group {grpname args} {
array set opts [parseargs args {
system.arg
comment.arg
} -nulldefault]
NetGroupAdd $opts(system) $grpname $opts(comment)
}
proc twapi::new_local_group {grpname args} {
array set opts [parseargs args {
system.arg
comment.arg
} -nulldefault]
NetLocalGroupAdd $opts(system) $grpname $opts(comment)
}
proc twapi::delete_global_group {grpname args} {
eval set [parseargs args {system.arg} -nulldefault]
_delete_rights $grpname $system
NetGroupDel $opts(system) $grpname
}
proc twapi::delete_local_group {grpname args} {
array set opts [parseargs args {system.arg} -nulldefault]
_delete_rights $grpname $opts(system)
NetLocalGroupDel $opts(system) $grpname
}
proc twapi::get_global_group_members {grpname args} {
array set opts [parseargs args {system.arg} -nulldefault]
NetGroupGetUsers $opts(system) $grpname
}
proc twapi::get_local_group_members {grpname args} {
array set opts [parseargs args {system.arg} -nulldefault]
NetLocalGroupGetMembers $opts(system) $grpname
}
proc twapi::add_user_to_global_group {grpname username args} {
eval set [parseargs args {system.arg} -nulldefault]
try {
NetGroupAddUser $system $grpname $username
} onerror {TWAPI_WIN32 1320} {
}
}
proc twapi::add_member_to_local_group {grpname username args} {
eval set [parseargs args {system.arg} -nulldefault]
try {
Twapi_NetLocalGroupAddMember $system $grpname $username
} onerror {TWAPI_WIN32 1378} {
}
}
proc twapi::remove_user_from_global_group {grpname username args} {
eval set [parseargs args {system.arg} -nulldefault]
try {
NetGroupDelUser $system $grpname $username
} onerror {TWAPI_WIN32 1321} {
}
}
proc twapi::remove_member_from_local_group {grpname username args} {
eval set [parseargs args {system.arg} -nulldefault]
try {
Twapi_NetLocalGroupDelMember $system $grpname $username
} onerror {TWAPI_WIN32 1377} {
}
}
proc twapi::open_user_token {username password args} {
variable windefs
array set opts [parseargs args {
domain.arg
{type.arg batch}
{provider.arg default}
} -nulldefault]
set typedef "LOGON32_LOGON_[string toupper $opts(type)]"
if {![info exists windefs($typedef)]} {
error "Invalid value '$opts(type)' specified for -type option"
}
set providerdef "LOGON32_PROVIDER_[string toupper $opts(provider)]"
if {![info exists windefs($typedef)]} {
error "Invalid value '$opts(provider)' specified for -provider option"
}
if {[regexp {^([^@]+)@(.+)} $username dummy user domain]} {
if {[string length $opts(domain)] != 0} {
error "The -domain option must not be specified when the username is in UPN format (user@domain)"
}
} else {
if {[string length $opts(domain)] == 0} {
set opts(domain) "."
}
}
return [LogonUser $username $opts(domain) $password $windefs($typedef) $windefs($providerdef)]
}
proc twapi::impersonate_token {token} {
ImpersonateLoggedOnUser $token
}
proc twapi::impersonate_user {args} {
set token [eval open_user_token $args]
try {
impersonate_token $token
} finally {
close_token $token
}
}
proc twapi::revert_to_self {{opt ""}} {
RevertToSelf
}
proc twapi::impersonate_self {level} {
switch -exact -- $level {
anonymous      { set level 0 }
identification { set level 1 }
impersonation  { set level 2 }
delegation     { set level 3 }
default {
error "Invalid impersonation level $level"
}
}
ImpersonateSelf $level
}
proc twapi::set_thread_token {token} {
SetThreadToken NULL $token
}
proc twapi::reset_thread_token {} {
SetThreadToken NULL NULL
}
proc twapi::get_lsa_policy_handle {args} {
array set opts [parseargs args {
{system.arg ""}
{access.arg policy_read}
} -maxleftover 0]
set access [_access_rights_to_mask $opts(access)]
return [Twapi_LsaOpenPolicy $opts(system) $access]
}
proc twapi::close_lsa_policy_handle {h} {
LsaClose $h
return
}
proc twapi::get_account_rights {account args} {
array set opts [parseargs args {
{system.arg ""}
} -maxleftover 0]
set sid [map_account_to_sid $account -system $opts(system)]
try {
set lsah [get_lsa_policy_handle -system $opts(system) -access policy_lookup_names]
return [Twapi_LsaEnumerateAccountRights $lsah $sid]
} onerror {TWAPI_WIN32 2} {
return [list ]
} finally {
if {[info exists lsah]} {
close_lsa_policy_handle $lsah
}
}
}
proc twapi::find_accounts_with_right {right args} {
array set opts [parseargs args {
{system.arg ""}
name
} -maxleftover 0]
try {
set lsah [get_lsa_policy_handle \
-system $opts(system) \
-access {
policy_lookup_names
policy_view_local_information
}]
set accounts [list ]
foreach sid [Twapi_LsaEnumerateAccountsWithUserRight $lsah $right] {
if {$opts(name)} {
if {[catch {lappend accounts [lookup_account_sid $sid]}]} {
lappend accounts $sid
}
} else {
lappend accounts $sid
}
}
return $accounts
} onerror {TWAPI_WIN32 259} {
return [list ]
} finally {
if {[info exists lsah]} {
close_lsa_policy_handle $lsah
}
}
}
proc twapi::_modify_account_rights {operation account rights args} {
set switches {
system.arg
handle.arg
}    
switch -exact -- $operation {
add {
}
remove {
lappend switches all
}
default {
error "Invalid operation '$operation' specified"
}
}
array set opts [parseargs args $switches -maxleftover 0]
if {[info exists opts(system)] && [info exists opts(handle)]} {
error "Options -system and -handle may not be specified together"
}
if {[info exists opts(handle)]} {
set lsah $opts(handle)
set sid $account
} else {
if {![info exists opts(system)]} {
set opts(system) ""
}
set sid [map_account_to_sid $account -system $opts(system)]
catch {
set lsah [get_lsa_policy_handle \
-system $opts(system) \
-access {
policy_lookup_names
policy_create_account
}]
}
if {![info exists lsah]} {
set lsah [get_lsa_policy_handle \
-system $opts(system) \
-access policy_lookup_names]
}
}
try {
if {$operation == "add"} {
Twapi_LsaAddAccountRights $lsah $sid $rights
} else {
Twapi_LsaRemoveAccountRights $lsah $sid $opts(all) $rights
}
} finally {
if {! [info exists opts(handle)]} {
close_lsa_policy_handle $lsah
}
}
}
interp alias {} twapi::add_account_rights {} twapi::_modify_account_rights add
interp alias {} twapi::remove_account_rights {} twapi::_modify_account_rights remove
proc twapi::find_logon_sessions {args} {
array set opts [parseargs args {
user.arg
type.arg
tssession.arg
} -maxleftover 0]
set luids [LsaEnumerateLogonSessions]
if {! ([info exists opts(user)] || [info exists opts(type)] ||
[info exists opts(tssession)])} {
return $luids
}
set result [list ]
if {[info exists opts(user)]} {
set sid [map_account_to_sid $opts(user)]
}
if {[info exists opts(type)]} {
set logontypes [list ]
foreach logontype $opts(type) {
lappend logontypes [_logon_session_type_code $logontype]
}
}
foreach luid $luids {
try {
unset -nocomplain session
array set session [LsaGetLogonSessionData $luid]
if {[array size session] == 0} {
set session(Sid) S-1-5-18; # SYSTEM
set session(Session) 0
set session(LogonType) 0
}
if {[info exists opts(user)] && $session(Sid) ne $sid} {
continue;               # User id does not match
}
if {[info exists opts(type)] && [lsearch -exact $logontypes $session(LogonType)] < 0} {
continue;               # Type does not match
}
if {[info exists opts(tssession)] && $session(Session) != $opts(tssession)} {
continue;               # Term server session does not match
}
lappend result $luid
} onerror {TWAPI_WIN32 1312} {
continue
}
}
return $result
}
proc twapi::get_logon_session_info {luid args} {
array set opts [parseargs args {
all
authpackage
dnsdomain
logondomain
logonid
logonserver
logontime
type
sid
user
tssession
userprincipal
} -maxleftover 0]
array set session [LsaGetLogonSessionData $luid]
foreach fld {LogonServer DnsDomainName Upn} {
if {![info exists session($fld)]} {
set session($fld) ""
}
}
array set result [list ]
foreach {opt index} {
authpackage AuthenticationPackage
dnsdomain   DnsDomainName
logondomain LogonDomain
logonid     LogonId
logonserver LogonServer
logontime   LogonTime
type        LogonType
sid         Sid
user        UserName
tssession   Session
userprincipal Upn
} {
if {$opts(all) || $opts($opt)} {
set result(-$opt) $session($index)
}
}
if {[info exists result(-type)]} {
set result(-type) [_logon_session_type_symbol $result(-type)]
}
return [array get result]
}
proc twapi::_change_usri3_flags {username mask values args} {
array set opts [parseargs args {
system.arg
} -nulldefault -maxleftover 0]
array set data [NetUserGetInfo $opts(system) $username 1]
set flags [expr {$data(usri3_flags) & (~ $mask)}]
set flags [expr {$flags | ($values & $mask)}]
Twapi_NetUserSetInfo_flags $opts(system) $username $flags
}
proc twapi::_map_impersonation_level ilevel {
switch -exact -- $ilevel {
0 { return "anonymous" }
1 { return "identification" }
2 { return "impersonation" }
3 { return "delegation" }
default { return $ilevel }
}
}
proc twapi::_logon_session_type_code {type} {
set code [lsearch -exact $::twapi::logon_session_type_map $type]
if {$code >= 0} {
return $code
}
if {![string is integer -strict $type]} {
error "Invalid logon session type '$type' specified"
}
return $type
}
proc twapi::_logon_session_type_symbol {code} {
set symbol [lindex $::twapi::logon_session_type_map $code]
if {$symbol eq ""} {
return $code
} else {
return $symbol
}
}
#-- from clipboard.tcl
namespace eval twapi {
}
proc twapi::open_clipboard {} {
OpenClipboard
}
proc twapi::close_clipboard {} {
catch {CloseClipboard}
return
}
proc twapi::empty_clipboard {} {
EmptyClipboard
}
proc twapi::read_clipboard {fmt} {
try {
set h [GetClipboardData $fmt]
set p [GlobalLock $h]
set data [Twapi_ReadMemoryBinary $p 0 [GlobalSize $h]]
} onerror {} {
catch {close_clipboard}
error $errorResult $errorInfo $errorCode
} finally {
if {[info exists p]} {
GlobalUnlock $h
}
}
return $data
}
proc twapi::read_clipboard_text {args} {
array set opts [parseargs args {
{raw.bool 0}
}]
try {
set h [GetClipboardData 13];    # 13 -> Unicode
set p [GlobalLock $h]
set data [string range [Twapi_ReadMemoryUnicode $p 0 [GlobalSize $h]] 0 end-1]
if {! $opts(raw)} {
set data [string map {"\r\n" "\n"} $data]
}
} onerror {} {
catch {close_clipboard}
error $errorResult $errorInfo $errorCode
} finally {
if {[info exists p]} {
GlobalUnlock $h
}
}
return $data
}
proc twapi::write_clipboard {fmt data} {
try {
set len [string length $data]
set mem_h [GlobalAlloc 2 $len]
set mem_p [GlobalLock $mem_h]
Twapi_WriteMemoryBinary $mem_p 0 $len $data
set h $mem_h
unset mem_p mem_h
GlobalUnlock $h
SetClipboardData $fmt $h
} onerror {} {
catch {close_clipboard}
error $errorResult $errorInfo $errorCode
} finally {
if {[info exists mem_p]} {
GlobalUnlock $mem_h
}
if {[info exists mem_h]} {
GlobalFree $mem_h
}
}
return
}
proc twapi::write_clipboard_text {data} {
try {
set mem_size [expr {2*(1+[string length $data])}]
set mem_h [GlobalAlloc 2 $mem_size]
set mem_p [GlobalLock $mem_h]
Twapi_WriteMemoryUnicode $mem_p 0 $mem_size $data
set h $mem_h
unset mem_h mem_p
GlobalUnlock $h
SetClipboardData 13 $h;         # 13 -> Unicode format
} onerror {} {
catch {close_clipboard}
error $errorResult $errorInfo $errorCode
} finally {
if {[info exists mem_p]} {
GlobalUnlock $mem_h
}
if {[info exists mem_h]} {
GlobalFree $mem_h
}
}
return
}
proc twapi::get_clipboard_formats {} {
return [Twapi_EnumClipboardFormats]
}
proc twapi::get_registered_clipboard_format_name {fmt} {
return [GetClipboardFormatName $fmt]
}
proc twapi::register_clipboard_format {fmt_name} {
RegisterClipboardFormat $fmt_name
}
proc twapi::clipboard_format_available {fmt} {
return [IsClipboardFormatAvailable $fmt]
}
interp alias {} ::twapi::start_clipboard_monitor {} ::twapi::MonitorClipboardStart
interp alias {} ::twapi::stop_clipboard_monitor {} ::twapi::MonitorClipboardStop
#-- from com.tcl
namespace eval twapi {
array set _typekind_map {
0 enum
1 record
2 module
3 interface
4 dispatch
5 coclass
6 alias
7 union
}
array set _iid_to_name_cache {
}
array set _name_to_iid_cache {
idispatch {{00020400-0000-0000-C000-000000000046}}
iunknown  {{00000000-0000-0000-C000-000000000046}}
ipersist  {{0000010c-0000-0000-C000-000000000046}}
ipersistfile {{0000010b-0000-0000-C000-000000000046}}
itasktrigger {{148BD52B-A2AB-11CE-B11F-00AA00530503}}
ischeduleworkitem {{a6b952f0-a4b1-11d0-997d-00aa006887ec}}
itask {{148BD524-A2AB-11CE-B11F-00AA00530503}}
ienumworkitems {{148BD528-A2AB-11CE-B11F-00AA00530503}}
itaskscheduler {{148BD527-A2AB-11CE-B11F-00AA00530503}}
iprovidetaskpage {{4086658a-cbbb-11cf-b604-00c04fd8d565}}
}
array set idispatch_prototypes {}
array set com_instance_data {}
variable com_instance_counter 0
variable com_debug 1
}
proc twapi::progid_to_clsid {progid} {
return [CLSIDFromProgID $progid]
}
proc twapi::clsid_to_progid {progid} {
return [ProgIDFromCLSID $progid]
}
proc twapi::iunknown_release {ifc} {
if {$ifc eq "NULL"} {
error "NULL interface pointer passed."
}
if {$::twapi::com_debug} {
set refs [IUnknown_AddRef $ifc]
if {$refs >= 2} {
IUnknown_Release $ifc
} else {
error "Internal error: attempt to release interface that's already released"
}
}
IUnknown_Release $ifc
}
proc twapi::iunknown_addref {ifc} {
if {$ifc eq "NULL"} {
error "NULL interface pointer passed."
}
IUnknown_AddRef $ifc
}
proc twapi::iunknown_query_interface {ifc name_or_iid} {
if {$ifc eq "NULL"} {
error "NULL interface pointer passed."
}
foreach {iid name} [_resolve_iid $name_or_iid] break
return [IUnknown_QueryInterface $ifc $iid $name]
}
proc twapi::get_iunknown_active {clsid} {
return [GetActiveObject $clsid]
}
proc twapi::com_create_instance {clsid name_or_iid args} {
array set opts [parseargs args {
{model.arg any}
download.bool
{disablelog.bool false}
enableaaa.bool
{nocustommarshal.bool false}
} -maxleftover 0]
set flags [expr { $opts(nocustommarshal) ? 0x1000 : 0}]
set model 0
if {[info exists opts(model)]} {
foreach m $opts(model) {
switch -exact -- $m {
any           {setbits model 23}
inprocserver  {setbits model 1}
inprochandler {setbits model 2}
localserver   {setbits model 4}
remoteserver  {setbits model 16}
}
}
}
setbits flags $model
if {[info exists opts(download)]} {
if {$opts(download)} {
setbits flags 0x2000;       # CLSCTX_ENABLE_CODE_DOWNLOAD
} else {
setbits flags 0x400;       # CLSCTX_NO_CODE_DOWNLOAD
}
}
if {$opts(disablelog)} {
setbits flags 0x4000;           # CLSCTX_NO_FAILURE_LOG
}
if {[info exists opts(enableaaa)]} {
if {$opts(enableaaa)} {
setbits flags 0x10000;       # CLSCTX_ENABLE_AAA
} else {
setbits flags 0x8000;       # CLSCTX_DISABLE_AAA
}
}
foreach {iid iid_name} [_resolve_iid $name_or_iid] break
if {[catch {set ifc [Twapi_CoCreateInstance $clsid NULL $flags $iid $iid_name]}]} {
set iunk [Twapi_CoCreateInstance $clsid NULL $flags [_iid_iunknown] IUnknown]
try {
twapi::OleRun $iunk
set ifc [iunknown_query_interface $iunk $iid]
} finally {
iunknown_release $iunk
}
}
return $ifc
}
proc twapi::get_iunknown {clsid args} {
return [eval [list com_create_instance $clsid IUnknown] $args]
}
proc twapi::get_idispatch {clsid args} {
return [eval [list com_create_instance $clsid IDispatch] $args]
}
proc twapi::idispatch_has_typeinfo {ifc} {
return [IDispatch_GetTypeInfoCount $ifc]
}
proc twapi::idispatch_get_itypeinfo {ifc args} {
array set opts [parseargs args {
lcid.int
} -maxleftover 0 -nulldefault]
IDispatch_GetTypeInfo $ifc 0 $opts(lcid)
}
proc twapi::idispatch_names_to_ids {ifc name args} {
array set opts [parseargs args {
lcid.int
paramnames.arg
} -maxleftover 0 -nulldefault]
return [IDispatch_GetIDsOfNames $ifc [concat [list $name] $opts(paramnames)] $opts(lcid)]
}
proc twapi::idispatch_invoke {ifc prototype args} {
if {$prototype eq ""} {
set prototype {0 {} 0 2 8 {}}
}
uplevel 1 [list twapi::IDispatch_Invoke $ifc $prototype] $args
}
proc twapi::comobj_null {args} {
switch -exact -- [lindex $args 0] {
-isnull    { return true }
-interface { return NULL }
-destroy   { return }
default {
error "NULL comobj called with arguments <[join $args ,]>."
}
}
}
proc twapi::comobj_idispatch {ifc need_addref {objclsid ""}} {
if {$ifc eq "NULL"} {
return ::twapi::comobj_null
}
if {$need_addref} {
iunknown_addref $ifc
}
set objname ::twapi::com_[incr twapi::com_instance_counter]
set ::twapi::com_instance_data($objname,ifc) $ifc
interp alias {} $objname {} ::twapi::_comobj_wrapper $objname $objclsid
return $objname
}
proc twapi::comobj {comid args} {
set clsid [_convert_to_clsid $comid]
return [comobj_idispatch [eval [list get_idispatch $clsid] $args] false $clsid]
}
proc twapi::idispatch_fill_prototypes {ifc v_protos lcid args} {
upvar $v_protos protos
array set protos {};                #  Just to make sure array is created
set names [list ]
foreach name $args {
set count [llength [array names protos $ifc,$name,$lcid*]]
if {$count} {
return $count
}
}
set count 0
try {
set ti [idispatch_get_itypeinfo $ifc -lcid $lcid]
switch -exact -- [lindex [itypeinfo_get_info $ti -typekind] 1] {
dispatch {
}
interface {
set ti2 [itypeinfo_get_referenced_itypeinfo $ti -1]
iunknown_release $ti
set ti $ti2
}
default {
error "Interface is not a dispatch interface"
}
}
set tc [itypeinfo_get_itypecomp $ti]
foreach name $args {
foreach invkind {1 2 4} {
if {![catch {
set binddata [ITypeComp_Bind $tc $name $invkind $lcid]
}]} {
if {[llength $binddata] == 0} {
continue;       # Not found
}
foreach {type data ti2} $binddata break
iunknown_release $ti2; # Don't need this but must release
if {$type ne "funcdesc"} continue
array set bindings $data
set protos($ifc,$name,$lcid,$bindings(invkind)) [list $bindings(memid) "" $lcid $bindings(invkind) $bindings(elemdescFunc.tdesc) $bindings(lprgelemdescParam)]
incr count
}
}
}
} onerror {TWAPI_WIN32 0x80004002} {
} finally {
if {[info exists tc]} {
iunknown_release $tc
}
if {[info exists ti]} {
iunknown_release $ti
}
}    
if {$count} {
return $count
}
try {
set dispex [iunknown_query_interface $ifc IDispatchEx]
if {$dispex ne ""} {
set dispid [IDispatchEx_GetDispID $dispex $name 10]
set invkinds [list 1 2 4];      # In case call below fails
if {! [catch {set flags [IDispatchEx_GetMemberProperties $dispex 0x115] }]} {
set invkinds [list ]
if {$flags & 0x100} {lappend invkinds 1}
if {$flags & 0x1} {lappend invkinds 2}
if {$flags & 0x14} {
lappend invkinds 4
}
}
foreach invkind $invkinds {
set protos($ifc,$name,$lcid,$invkind) [list $dispid "" $lcid $invkind 8]
incr count
}
}
} onerror {} {
} finally {
if {[info exists dispex] && $dispex ne ""} {
iunknown_release $dispex
}
}
return $count
}
proc twapi::idispatch_define_prototype {ifc name args} {
array set opts [parseargs args {
{lcid.int 0}
{type.arg 1 {-get get -set set -call call 1 2 4}}
{rettype.arg bstr}
params.arg
} -maxleftover 0]
set dispid [lindex [idispatch_names_to_ids $ifc $name] 1]
if {$dispid eq ""} {
win32_error 0x80020003 "No property or method found with name '$name'."
}
switch -exact -- $opts(type) {
"call"  -
"-call" {set flags 1 }
"get"   -
"-get" { set flags 2 }
"set"   -
"-set" { set flags 4 }
default {
set flags $opts(type)
}
}
set proto [list $dispid "" $opts(lcid) $flags $opts(rettype)]
if {[info exists opts(params)]} {
lappend proto $opts(params)
}
return $proto
}
proc twapi::itypeinfo_get_info {ifc args} {
array set opts [parseargs args {
all
guid
lcid
constructorid
destructorid
schema
instancesize
typekind
fncount
varcount
interfacecount
vtblsize
alignment
majorversion
minorversion
aliasdesc
flags
idldesc
memidmap
} -maxleftover 0]
array set data [ITypeInfo_GetTypeAttr $ifc]
set result [list ]
foreach {opt key} {
guid guid
lcid lcid
constructorid memidConstructor
destructorid  memidDestructor
schema lpstrSchema
instancesize cbSizeInstance
fncount cFuncs
varcount cVars
interfacecount cImplTypes
vtblsize cbSizeVft
alignment cbAlignment
majorversion wMajorVerNum
minorversion wMinorVerNum
aliasdesc tdescAlias
} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt $data($key)
}
}
if {$opts(all) || $opts(typekind)} {
set typekind $data(typekind)
if {[info exists ::twapi::_typekind_map($typekind)]} {
set typekind $::twapi::_typekind_map($typekind)
}
lappend result -typekind $typekind
}
if {$opts(all) || $opts(flags)} {
lappend result -flags [_make_symbolic_bitmask $data(wTypeFlags) {
appobject       1
cancreate       2
licensed        4
predeclid       8
hidden         16
control        32
dual           64
nonextensible 128
oleautomation 256
restricted    512
aggregatable 1024
replaceable  2048
dispatchable 4096
reversebind  8192
proxy       16384
}]
}
if {$opts(all) || $opts(idldesc)} {
lappend result -idldesc [_make_symbolic_bitmask $data(idldescType) {
in 1
out 2
lcid 4
retval 8
}]
}
if {$opts(all) || $opts(memidmap)} {
set memidmap [list ]
for {set i 0} {$i < $data(cFuncs)} {incr i} {
array set fninfo [itypeinfo_get_func_info $ifc $i -memid -name]
lappend memidmap $fninfo(-memid) $fninfo(-name)
}
lappend result -memidmap $memidmap
}
return $result
}
proc twapi::itypeinfo_get_referenced_itypeinfo {ifc index} {
set hreftype [ITypeInfo_GetRefTypeOfImplType $ifc $index]
return [ITypeInfo_GetRefTypeInfo $ifc $hreftype]
}
proc twapi::itypeinfo_get_itypelib {ifc} {
return [ITypeInfo_GetContainingTypeLib $ifc]
}
proc twapi::itypeinfo_get_itypecomp {ifc} {
return [ITypeInfo_GetTypeComp $ifc]
}
proc twapi::itypeinfo_get_name {ifc} {
return [lindex [itypeinfo_get_doc $ifc -1 -name] 1]
}
proc twapi::itypeinfo_get_var_info {ifc index args} {
array set opts [parseargs args {
all
name
memid
schema
datatype
value
valuetype
varkind
flags
} -maxleftover 0]
array set data [ITypeInfo_GetVarDesc $ifc $index]
set result [list ]
foreach {opt key} {
memid memid
schema lpstrSchema
datatype elemdescVar.tdesc
} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt $data($key)
}
}
if {$opts(all) || $opts(value)} {
if {[info exists data(lpvarValue)]} {
lappend result -value [lindex $data(lpvarValue) 1]
} else {
lappend result -value $data(oInst)
}
}
if {$opts(all) || $opts(valuetype)} {
if {[info exists data(lpvarValue)]} {
lappend result -valuetype [lindex $data(lpvarValue) 0]
} else {
lappend result -valuetype int
}
}
if {$opts(all) || $opts(varkind)} {
lappend result -varkind [string map {
0 perinstance
1 static
2 const
3 dispatch
} $data(varkind)]
}
if {$opts(all) || $opts(flags)} {
lappend result -flags [_make_symbolic_bitmask $data(wVarFlags) {
readonly       1
source       2
bindable        4
requestedit       8
displaybind         16
defaultbind        32
hidden           64
restricted 128
defaultcollelem 256
uidefault    512
nonbrowsable 1024
replaceable  2048
immediatebind 4096
}]
}
if {$opts(all) || $opts(name)} {
set result [concat $result [itypeinfo_get_doc $ifc $data(memid) -name]]
}    
return $result
}
proc twapi::itypeinfo_get_func_info {ifc index args} {
array set opts [parseargs args {
all
name
memid
funckind
invkind
callconv
params
paramnames
flags
datatype
resultcodes
vtbloffset
} -maxleftover 0]
array set data [ITypeInfo_GetFuncDesc $ifc $index]
set result [list ]
if {$opts(all) || $opts(paramnames)} {
lappend result -paramnames [lrange [itypeinfo_get_names $ifc $data(memid)] 1 end]
}
foreach {opt key} {
memid       memid
vtbloffset  oVft
datatype    elemdescFunc.tdesc
resultcodes lprgscode
} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt $data($key)
}
}
if {$opts(all) || $opts(funckind)} {
lappend result -funckind [string map {
0 virtual
1 purevirtual
2 nonvirtual
3 static
4 dispatch
} $data(funckind)]
}
if {$opts(all) || $opts(invkind)} {
lappend result -invkind [string map {
0 func
1 propget
2 propput
3 propputref
} $data(invkind)]
}
if {$opts(all) || $opts(callconv)} {
lappend result -callconv [string map {
0 fastcall
1 cdecl
2 pascal
3 macpascal
4 stdcall
5 fpfastcall
6 syscall
7 mpwcdecl
8 mpwpascal
} $data(callconv)]
}
if {$opts(all) || $opts(flags)} {
lappend result -flags [_make_symbolic_bitmask $data(wFuncFlags) {
restricted   1
source       2
bindable     4
requestedit  8
displaybind  16
defaultbind  32
hidden       64
usesgetlasterror  128
defaultcollelem 256
uidefault    512
nonbrowsable 1024
replaceable  2048
immediatebind 4096
}]
}
if {$opts(all) || $opts(params)} {
set params [list ]
foreach param $data(lprgelemdescParam) {
foreach {paramtype paramdesc} $param break
set paramflags [_make_symbolic_bitmask [lindex $paramdesc 0] {
in 1
out 2
lcid 4
retval 8
optional 16
hasdefault 32
hascustom  64
}]
if {[llength $paramdesc] > 1} {
lappend params [list $paramtype $paramflags [lindex $paramdesc 1]]
} else {
lappend params [list $paramtype $paramflags]
}
}
lappend result -params $params
}
if {$opts(all) || $opts(name)} {
set result [concat $result [itypeinfo_get_doc $ifc $data(memid) -name]]
}    
return $result
}
proc twapi::itypeinfo_get_doc {ifc memid args} {
array set opts [parseargs args {
all
name
docstring
helpctx
helpfile
} -maxleftover 0]
foreach {name docstring helpctx helpfile} [ITypeInfo_GetDocumentation $ifc $memid] break
set result [list ]
foreach opt {name docstring helpctx helpfile} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt [set $opt]
}
}
return $result
}
proc twapi::itypeinfo_names_to_ids {ifc name args} {
array set opts [parseargs args {
paramnames.arg
} -maxleftover 0 -nulldefault]
return [ITypeInfo_GetIDsOfNames $ifc [concat [list $name] $opts(paramnames)]]
}
proc twapi::itypeinfo_get_impl_type_flags {ifc index} {
return [_make_symbolic_bitmask \
[ITypeInfo_GetImplTypeFlags $ifc $index] \
{
default      1
source       2
restricted   4
defaultvtable 8
}]    
}
proc twapi::itypeinfo_get_names {ifc memid} {
return [ITypeInfo_GetNames $ifc $memid]
}
proc twapi::get_itypelib {path args} {
array set opts [parseargs args {
{registration.arg none {none register default}}
} -maxleftover 0]
return [LoadTypeLibEx $path [string map {default 0 register 1 none 2} $opts(registration)]]
}
proc twapi::get_registered_itypelib {uuid major minor args} {
array set opts [parseargs args {
lcid.int
} -maxleftover 0 -nulldefault]
return [LoadRegTypeLib $uuid $major $minor $opts(lcid)]
}
proc twapi::itypelib_register {ifc path helppath args} {
RegisterTypeLib $ifc $path $helppath
}
proc twapi::itypelib_unregister {uuid major minor args} {
array set opts [parseargs args {
lcid.int
} -maxleftover 0 -nulldefault]
UnRegisterTypeLib $uuid $major $minor $opts(lcid) 1
}
proc twapi::itypelib_count {ifc} {
return [ITypeLib_GetTypeInfoCount $ifc]
}
proc twapi::itypelib_get_entry_typekind {ifc id} {
set typekind [ITypeLib_GetTypeInfoType $ifc $id]
if {[info exists ::twapi::_typekind_map($typekind)]} {
set typekind $::twapi::_typekind_map($typekind)
}
}
proc twapi::itypelib_get_entry_doc {ifc id args} {
array set opts [parseargs args {
all
name
docstring
helpctx
helpfile
} -maxleftover 0]
foreach {name docstring helpctx helpfile} [ITypeLib_GetDocumentation $ifc $id] break
set result [list ]
foreach opt {name docstring helpctx helpfile} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt [set $opt]
}
}
return $result
}
interp alias {} twapi::itypelib_get_entry_itypeinfo {} twapi::ITypeLib_GetTypeInfo
interp alias {} twapi::itypelib_get_registered_itypeinfo {} ITypeLib_GetTypeInfoOfGuid
proc twapi::itypelib_get_registered_path {guid major minor args} {
array set opts [parseargs args {
lcid.int
} -maxleftover 0 -nulldefault]
set path [QueryPathOfRegTypeLib $guid $major $minor $opts(lcid)]
if {[string equal [string index $path end] \0]} {
set path [string range $path 0 end-1]
}
return $path
}
proc twapi::itypelib_get_info {ifc args} {
array set opts [parseargs args {
all
guid
lcid
syskind
majorversion
minorversion
flags
} -maxleftover 0]
array set data [ITypeLib_GetLibAttr $ifc]
set result [list ]
foreach {opt key} {
guid guid
lcid lcid
majorversion wMajorVerNum
minorversion wMinorVerNum
} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt $data($key)
}
}
if {$opts(all) || $opts(flags)} {
lappend result -flags [_make_symbolic_bitmask $data(wLibFlags) {
restricted      1
control         2
hidden          4
hasdiskimage    8
}]
}
if {$opts(all) || $opts(syskind)} {
lappend result -syskind [string map {
0 win16
1 win32
2 mac
} $data(syskind)]
}
return $result
}
proc twapi::itypelib_foreach {args} {
array set opts [parseargs args {
type.arg
name.arg
guid.arg
} -maxleftover 3]
if {[llength $args] != 3} {
error "Syntax error: Should be 'itypelib_foreach ?options? VARNAME ITYPELIB SCRIPT'"
}
foreach {varname tl script} $args break
set count [itypelib_count $tl]
for {set i 0} {$i < $count} {incr i} {
if {[info exists opts(type)] &&
$opts(type) ne [itypelib_get_entry_typekind $tl $i]} {
continue;                   # Type does not match
}
if {[info exists opts(name)] &&
[string compare -nocase $opts(name) [lindex [itypelib_get_entry_doc $tl $i -name] 1]]} {
continue;                   # Name does not match
}
upvar $varname ti
set ti [itypelib_get_entry_itypeinfo $tl $i]
if {[info exists opts(guid)]} {
if {[string compare -nocase [lindex [itypeinfo_get_info $ti -guid] 1] $opts(guid)]} {
continue
}
}
set ret [catch {uplevel $script} msg]
switch -exact -- $ret {
1 {
error $msg $::errorInfo $::errorCode
}
2 {
return; # TCL_RETURN
}
3 {
set i $count; # TCL_BREAK
}
}
}
return
}
proc twapi::name_to_iid {iname} {
set iname [string tolower $iname]
if {[info exists ::twapi::_name_to_iid_cache($iname)]} {
return $::twapi::_name_to_iid_cache($iname)
}
foreach iid [registry keys HKEY_CLASSES_ROOT\\Interface] {
if {![catch {
set val [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]
}]} {
if {[string equal -nocase $iname $val]} {
return [set ::twapi::_name_to_iid_cache($iname) $iid]
}
}
}
return [set ::twapi::_name_to_iid_cache($iname) ""]
}
proc twapi::iid_to_name {iid} {
set iname ""
catch {set iname [registry get HKEY_CLASSES_ROOT\\Interface\\$iid ""]}
return $iname
}
proc twapi::com_named_property_list {obj} {
set result [list ]
$obj -iterate itemobj {
lappend result [$itemobj Name] [$itemobj]
$itemobj -destroy
}
return $result
}
proc twapi::get_coclass_default_source_itypeinfo {coti} {
set count [lindex [itypeinfo_get_info $coti -interfacecount] 1]
for {set i 0} {$i < $count} {incr i} {
set flags [ITypeInfo_GetImplTypeFlags $coti $i]
if {($flags & 3) == 3} {
return [itypeinfo_get_referenced_itypeinfo $coti $i]
}
}
return ""
}
proc twapi::variant_time_to_timelist {double} {
return [VariantTimeToSystemTime $double]
}
proc twapi::timelist_to_variant_time {timelist} {
return [SystemTimeToVariantTime $timelist]
}
proc twapi::_print_typelib {path args} {
array set opts [parseargs args {
type.arg
name.arg
} -maxleftover 0]
set ifc [get_itypelib $path -registration none]
set count [itypelib_count $ifc]
for {set i 0} {$i < $count} {incr i} {
set type [itypelib_get_entry_typekind $ifc $i]
if {[info exists opts(type)] && $opts(type) ne $type} continue
array set tlinfo [itypelib_get_entry_doc $ifc $i -all]
if {[info exists opts(name)] && [string compare -nocase $opts(name) $tlinfo(-name)]} continue
set desc [list "$i:\t$type\t$tlinfo(-name) - $tlinfo(-docstring)"]
set ti [twapi::itypelib_get_entry_itypeinfo $ifc $i]
array set attrs [itypeinfo_get_info $ti -all]
switch -exact -- $type {
record -
union  -
enum {
for {set j 0} {$j < $attrs(-varcount)} {incr j} {
array set vardata [itypeinfo_get_var_info $ti $j -all]
set vardesc "\t\t$vardata(-varkind) $vardata(-datatype) $vardata(-name)"
if {$type eq "enum"} {
append vardesc " = $vardata(-value)"
} else {
append vardesc " (offset $vardata(-value))"
}
lappend desc $vardesc
}
}
alias {
lappend desc "\t\ttypedef $attrs(-aliasdesc)"
}
dispatch -
interface {
for {set j 0} {$j < $attrs(-fncount)} {incr j} {
array set funcdata [itypeinfo_get_func_info $ti $j -all] 
if {$funcdata(-funckind) eq "dispatch"} {
set funckind "(dispid $funcdata(-memid))"
} else {
set funckind "(vtable $funcdata(-vtbloffset))"
}
lappend desc "\t\t$funckind [_resolve_com_type $ti $funcdata(-datatype)] $funcdata(-name) [_resolve_com_params $ti $funcdata(-params) $funcdata(-paramnames)]"
}
}
coclass {
for {set j 0} {$j < $attrs(-interfacecount)} {incr j} {
set ti2 [itypeinfo_get_referenced_itypeinfo $ti $j]
set idesc "\t\t[itypeinfo_get_name $ti2]"
set iflags [itypeinfo_get_impl_type_flags $ti $j]
if {[llength $iflags]} {
append idesc " ([join $iflags ,])"
}
lappend desc $idesc
iunknown_release $ti2
}
}
}
puts [join $desc \n]
iunknown_release $ti
}
iunknown_release $ifc
return
}
proc twapi::_print_interface {ifc} {
set ti [idispatch_get_itypeinfo $ifc]
twapi::_print_interface_helper $ti
iunknown_release $ti
}
proc twapi::_print_interface_helper {ti {names_already_done ""}} {
set name [itypeinfo_get_name $ti]
if {[lsearch -exact $names_already_done $name] >= 0} {
return $names_already_done
}
lappend names_already_done $name
array set attrs [itypeinfo_get_info $ti -all]
for {set j 0} {$j < $attrs(-fncount)} {incr j} {
array set funcdata [itypeinfo_get_func_info $ti $j -all] 
if {$funcdata(-funckind) eq "dispatch"} {
set funckind "(dispid $funcdata(-memid))"
} else {
set funckind "(vtable $funcdata(-vtbloffset))"
}
lappend desc "\t$funckind [_resolve_com_type $ti $funcdata(-datatype)] $funcdata(-name) [_resolve_com_params $ti $funcdata(-params) $funcdata(-paramnames)]"
}
puts $name
puts [join $desc \n]
for {set j 0} {$j < $attrs(-interfacecount)} {incr j} {
set ti2 [itypeinfo_get_referenced_itypeinfo $ti $j]
set names_already_done [_print_interface_helper $ti2 $names_already_done]
iunknown_release $ti2
}
return $names_already_done
}
proc twapi::_resolve_com_params {ti params paramnames} {
set result [list ]
foreach param $params paramname $paramnames {
set paramdesc [lreplace $param 0 0 [_resolve_com_type $ti [lindex $param 0]]]
lappend paramdesc $paramname
lappend result $paramdesc
}
return $result
}
proc twapi::_resolve_com_type {ti typedesc} {
switch -exact -- [lindex $typedesc 0] {
ptr {
set typedesc [list ptr [_resolve_com_type $ti [lindex $typedesc 1]]]
}
userdefined {
set hreftype [lindex $typedesc 1]
set ti2 [ITypeInfo_GetRefTypeInfo $ti $hreftype]
set typedesc [list userdefined [itypeinfo_get_name $ti2]]
iunknown_release $ti2
}
default {
}
}
return $typedesc
}
proc twapi::_convert_from_variant {variant addref {raw false}} {
if {[llength $variant] == 0} {
return ""
}
set vt [lindex $variant 0]
if {$vt & 0x2000} {
if {[llength $variant] < 3} {
return [list ]
}
set vt [expr {$vt & ~ 0x2000}]
if {$vt == 12} {
set result [list ]
foreach elem [lindex $variant 2] {
lappend result [_convert_from_variant $elem $addref $raw]
}
return $result
} else {
return [lindex $variant 2]
}
} else {
if {$vt == 9} {
set idisp [lindex $variant 1]; # May be NULL!
if {$raw} {
if {$addref && $idisp ne "NULL"} {
iunknown_addref $idisp
}
return $idisp
} else {
return [comobj_idispatch $idisp $addref]
}
} elseif {$vt == 13} {
set iunk [lindex $variant 1]; # May be NULL!
if {$raw} {
if {$addref && $iunk ne "NULL"} {
iunknown_addref $iunk
}
return $iunk
} else {
if {$iunk eq "NULL"} {
return ::twapi::comobj_null
}
set idisp [iunknown_query_interface $iunk IDispatch]
if {$idisp eq ""} {
if {$addref} {
iunknown_addref $iunk
}
return $iunk
} else {
if {! $addref} {
iunknown_release $iunk
}
return [comobj_idispatch $idisp false]
}
}
}
}
return [lindex $variant 1]
}
proc twapi::_comobj_wrapper {comobj clsid args} {
if {![info exists ::twapi::com_instance_data($comobj,ifc)]} {
error "Missing COM interface"
}
set ifc $::twapi::com_instance_data($comobj,ifc)
set nargs [llength $args]
switch -exact -- [lindex $args 0] {
-get {
if {$nargs < 2} {
error "Insufficient number of arguments supplied for method call"
}
set name [lindex $args 1]
set params [lrange $args 2 end]
set flags  2;           # Property get
}
-set {
if {$nargs < 3} {
error "Insufficient number of arguments supplied for method call"
}
set name [lindex $args 1]
set params [lrange $args 2 end]
set flags  4;           # Property set
}
-call {
if {$nargs < 2} {
error "Insufficient number of arguments supplied for method call"
}
set name [lindex $args 1]
set params [lrange $args 2 end]
set flags  1;           # Method call
}
-destroy {
foreach sink_item [array names ::twapi::com_instance_data "$comobj,sink,*"] {
set sinkid [lindex [split $sink_item ,] 2]
$comobj -unbind $sinkid
}
array unset twapi::idispatch_prototypes ${ifc}*
twapi::iunknown_release $ifc
rename $comobj ""
return
}
-isnull {
return false
}
-precache {
foreach {name proto} [lindex $args 1] {
set flags [lindex $proto 3]
set ::twapi::idispatch_prototypes($ifc,$name,0,$flags) $proto
}
return
}
"" {
return [_convert_from_variant [twapi::idispatch_invoke $ifc ""] false]
}
-print {
_print_interface $ifc
return
}
-interface {
return $ifc
}
-queryinterface {
return [iunknown_query_interface $ifc [lindex $args 1]]
}
-with {
set subobjlist [lindex $args 1]
set next $comobj
set releaselist [list ]
try {
while {[llength $subobjlist]} {
set nextargs [lindex $subobjlist 0]
set subobjlist [lrange $subobjlist 1 end]
set next [uplevel [list $next] $nextargs]
lappend releaselist $next
}
return [uplevel [list $next] [lrange $args 2 end]]
} finally {
foreach next $releaselist {
$next -destroy
}
}
}
-iterate {
if {[llength $args] < 3} {
error "Insufficient arguments. Syntax '$comobj -iterate VARNAME CODEBLOCK'"
}
upvar [lindex $args 1] var
set enum_disp [$comobj -get _NewEnum]
try {
set iter [iunknown_query_interface $enum_disp IEnumVARIANT]
if {$iter ne ""} {
while {1} {
set next [IEnumVARIANT_Next $iter 1]
foreach {more values} $next break
if {[llength $values]} {
set var [_convert_from_variant [lindex $values 0] false]
set ret [catch {uplevel [lindex $args 2]} msg]
switch -exact -- $ret {
1 {
error $msg $::errorInfo $::errorCode
}
2 {
return; # TCL_RETURN
}
3 {
set more 0; # TCL_BREAK
}
}
}
if {! $more} break
}
}
} finally {
iunknown_release $enum_disp
if {[info exists iter] && $iter ne ""} {
iunknown_release $iter
}
}
return
}
-bind {
if {[llength $args] != 2} {
error "Syntax error: should be '$comobj -bind SCRIPT"
}
try {
set pci [iunknown_query_interface $ifc IProvideClassInfo]
if {$pci ne ""} {
catch {set coti [IProvideClassInfo_GetClassInfo $pci]}
}
if {![info exists coti]} {
if {$clsid eq ""} {
error "Do not have class information for binding"
}
set ti [idispatch_get_itypeinfo $ifc]
set tl [lindex [itypeinfo_get_itypelib $ti] 0]
itypelib_foreach -guid $clsid -type coclass coti $tl {
break
}
}
if {![info exists coti]} {
error "Could not find coclass for binding"
}
set srcti [get_coclass_default_source_itypeinfo $coti]
array set srcinfo [itypeinfo_get_info $srcti -memidmap -guid]
set container [iunknown_query_interface $ifc IConnectionPointContainer]
if {$container eq ""} {
error "Object does not have any event source interfaces"
}
set connpt [IConnectionPointContainer_FindConnectionPoint $container $srcinfo(-guid)]
if {$connpt eq ""} {
error "Object has no matching event source"
}
set sink [ComEventSink $srcinfo(-guid) [list ::twapi::_eventsink_callback $comobj $srcinfo(-memidmap) [lindex $args 1]]]
set sinkid [IConnectionPoint_Advise $connpt $sink]
set ::twapi::com_instance_data($comobj,sink,$sinkid) $sink
set ::twapi::com_instance_data($comobj,connpt,$sinkid) $connpt
return $sinkid
} onerror {} {
foreach x {connpt sink} {
if {[info exists $x] && [set $x] ne ""} {
iunknown_release [set $x]
}
}
error $errorResult $errorInfo $errorCode
} finally {
foreach x {ti tl coti srcti container pci} {
if {[info exists $x] && [set $x] ne ""} {
iunknown_release [set $x]
}
}
}
}
-unbind {
if {[llength $args] != 2} {
error "Syntax error: Should be '$comobj -unbind BINDID'"
}
set sinkid [lindex $args 1]
if {[info exists ::twapi::com_instance_data($comobj,connpt,$sinkid)]} {
IConnectionPoint_Unadvise $::twapi::com_instance_data($comobj,connpt,$sinkid) $sinkid
unset ::twapi::com_instance_data($comobj,connpt,$sinkid)
}
if {[info exists ::twapi::com_instance_data($comobj,sink,$sinkid)]} {
iunknown_release $::twapi::com_instance_data($comobj,sink,$sinkid)
unset ::twapi::com_instance_data($comobj,sink,$sinkid)
}
return
}
default {
set name [lindex $args 0]
set params [lrange $args 1 end]
twapi::idispatch_fill_prototypes $ifc ::twapi::idispatch_prototypes 0 $name
set flags 0
if {[info exists ::twapi::idispatch_prototypes($ifc,$name,0,2)]} {
set flags [expr {$flags | 2}]
}
if {[info exists ::twapi::idispatch_prototypes($ifc,$name,0,4)]} {
set flags [expr {$flags | 4}]
}
if {[info exists ::twapi::idispatch_prototypes($ifc,$name,0,1)]} {
set flags [expr {$flags | 1}]
}
if {$flags != 0 && $flags != 1 && $flags != 2 && $flags != 4} {
set nparams [llength $params]
foreach flag {1 2 4} {
if {$flags & $flag} {
set proto $::twapi::idispatch_prototypes($ifc,$name,0,$flag)
if {[llength $proto] > 5} {
if {$nparams == [llength [lindex $proto 5]]} {
set matched_flags $flag
break
}
}
}
}
if {![info exists matched_flags]} {
if {($flags & 2) && $nparams == 0} {
set matched_flags 2
} elseif {($flags & 4) && $nparams == 1} {
set matched_flags 4
} elseif {$flags & 1} {
set matched_flags 1
}
}
if {[info exists matched_flags]} {
set flags $matched_flags
} else {
set flags 0
}
}
if {$flags == 0} {
set flags 1
}
}
}
if {![info exists ::twapi::idispatch_prototypes($ifc,$name,0,$flags)]} {
twapi::idispatch_fill_prototypes $ifc ::twapi::idispatch_prototypes 0 $name
if {![info exists ::twapi::idispatch_prototypes($ifc,$name,0,$flags)]} {
set dispid [lindex [idispatch_names_to_ids $ifc $name] 1]
if {$dispid eq ""} {
win32_error 0x80020003 "No property or method found with name '$name'."
}
set ::twapi::idispatch_prototypes($ifc,$name,0,$flags) [list $dispid "" 0 $flags 8]
}
}
return [_convert_from_variant [eval [list twapi::idispatch_invoke $ifc $::twapi::idispatch_prototypes($ifc,$name,0,$flags)] $params] false]
}
proc twapi::_comobj_active {comobj} {
if {[info exists ::twapi::com_instance_data($comobj,ifc)]} {
return 1
} else {
return 0
}
}
proc twapi::_eventsink_callback {comobj dispidmap script dispid lcid flags params} {
if {![_comobj_active $comobj]} {
if {$::twapi::com_debug} {
debug_puts "COM event received for inactive object"
}
return;                         # Object has gone away, ignore
}
set result ""
set retcode [catch {
set dispid [twapi::kl_get_default $dispidmap $dispid $dispid]
set converted_params [list ]
foreach param $params {
lappend converted_params [_convert_from_variant $param false true]
}
set result [uplevel \#0 $script [list $dispid] $converted_params]
} msg]
if {$::twapi::com_debug && $retcode} {
debug_puts "Event sink callback error ($retcode): $msg\n$::errorInfo"
}
return -code $retcode $result
}
proc twapi::_convert_to_clsid {comid} {
if {[catch {IIDFromString $comid}]} {
return [progid_to_clsid $comid]
}
return $comid
}
proc twapi::_wmi {} {
return [comobj_idispatch [::twapi::Twapi_GetObjectIDispatch "winmgmts:{impersonationLevel=impersonate}!//./root/cimv2"] false]
}
proc twapi::_iid_iunknown {} {
return $::twapi::_name_to_iid_cache(iunknown)
}
proc twapi::_iid_idispatch {} {
return $::twapi::_name_to_iid_cache(idispatch)
}
proc twapi::_resolve_iid {name_or_iid} {
set other [iid_to_name $name_or_iid]
if {$other ne ""} {
return [list $name_or_iid $other]
}
set other [name_to_iid $name_or_iid]
if {$other ne ""} {
return [list $other $name_or_iid]
}
win32_error 0x80004002 "Could not find IID $name_or_iid"
}
proc twapi::_com_tests {} {
puts "Invoking Internet Explorer"
set ie [comobj InternetExplorer.Application -enableaaa true]
$ie Visible 1
$ie Navigate http://www.google.com
after 2000
puts "Exiting Internet Explorer"
$ie Quit
$ie -destroy
puts "Internet Explorer done."
puts "------------------------------------------"
puts "Invoking Word"
set word [comobj Word.Application]
set doc [$word -with Documents Add]
$word Visible 1
puts "Inserting text"
$word -with {selection font} name "Courier New"
$word -with {selection font} size 10.0
$doc -with content text "Text in Courier 10 point"
after 2000
puts "Exiting Word"
$word Quit 0
puts "Word done."
puts "------------------------------------------"
puts "WMI BIOS test"
puts [get_bios_info]
puts "WMI BIOS done."
puts "------------------------------------------"
puts "WMI direct property access test (get bios version)"
set wmi [twapi::_wmi]
$wmi -with {{ExecQuery "select * from Win32_BIOS"}} -iterate biosobj {
puts "BIOS version: [$biosobj BiosVersion]"
$biosobj -destroy
}
$wmi -destroy
puts "------------------------------------------"
puts " Starting process tracker. Type 'twapi::_stop_process_tracker' to stop it."
twapi::_start_process_tracker
vwait ::twapi::_stop_tracker
}
proc twapi::_wmi_read_popups {} {
set res {}
set wmi [twapi::_wmi]
set wql {select * from Win32_NTLogEvent where LogFile='System' and \
EventType='3'    and \
SourceName='Application Popup'}
set svcs [$wmi ExecQuery $wql]
$svcs -iterate instance {
set propSet [$instance Properties_]
set msgVal [[$propSet Item Message] Value]
lappend res $msgVal
}
return $res
}
proc twapi::_wmi_read_popups_succint {} {
set res [list ]
set wmi [twapi::_wmi]
$wmi -with {
{ExecQuery "select * from Win32_NTLogEvent where LogFile='System' and EventType='3' and SourceName='Application Popup'"}
} -iterate event {
lappend res [$event Message]
}
return $res
}
proc twapi::_wmi_get_autostart_services {} {
set res [list ]
set wmi [twapi::_wmi]
$wmi -with {
{ExecQuery "select * from Win32_Service where StartMode='Auto'"}
} -iterate svc {
lappend res [$svc DisplayName]
}
return $res
}
proc twapi::get_bios_info {} {
set wmi [twapi::_wmi]
array set entries [list ]
$wmi -with {{ExecQuery "select * from Win32_BIOS"}} -iterate elem {
set propset [$elem Properties_]
array set entries [com_named_property_list $propset]
$elem -destroy
$propset -destroy
}
$wmi -destroy
return [array get entries]
}
proc twapi::_process_start_handler {wmi_event args} {
if {$wmi_event eq "OnObjectReady"} {
set event_obj [comobj_idispatch [lindex $args 0] true]
puts "Process [$event_obj ProcessID] [$event_obj ProcessName] started at [clock format [large_system_time_to_secs [$event_obj TIME_CREATED]] -format {%x %X}]"
$event_obj -destroy
}
}
proc twapi::_start_process_tracker {} {
set ::twapi::_process_wmi [twapi::_wmi]
set ::twapi::_process_event_sink [comobj wbemscripting.swbemsink]
set ::twapi::_process_event_sink_id [$::twapi::_process_event_sink -bind twapi::_process_start_handler]
$::twapi::_process_wmi ExecNotificationQueryAsync [$::twapi::_process_event_sink -interface] "select * from Win32_ProcessStartTrace"
}
proc twapi::_stop_process_tracker {} {
$::twapi::_process_event_sink Cancel
$::twapi::_process_event_sink -unbind $::twapi::_process_event_sink_id
$::twapi::_process_event_sink -destroy
$::twapi::_process_wmi -destroy
set ::twapi::_stop_tracker 1
return
}
proc twapi::_service_change_handler {wmi_event args} {
if {$wmi_event eq "OnObjectReady"} {
set event_obj [twapi::comobj_idispatch [lindex $args 0] true]
puts "Previous: [$event_obj PreviousInstance]"
$event_obj -destroy
}
}
proc twapi::_start_service_tracker {} {
set ::twapi::_service_wmi [twapi::_wmi]
set ::twapi::_service_event_sink [twapi::comobj wbemscripting.swbemsink]
set ::twapi::_service_event_sink_id [$::twapi::_service_event_sink -bind twapi::_service_change_handler]
$::twapi::_service_wmi ExecNotificationQueryAsync [$::twapi::_service_event_sink -interface] "select * from __InstanceModificationEvent within 1 where TargetInstance ISA 'Win32_Service'"
}
proc twapi::_stop_service_tracker {} {
$::twapi::_service_event_sink Cancel
$::twapi::_service_event_sink -unbind $::twapi::_service_event_sink_id
$::twapi::_service_event_sink -destroy
$::twapi::_service_wmi -destroy
}
#-- from console.tcl
namespace eval twapi {
}
proc twapi::allocate_console {} {
AllocConsole
}
proc twapi::free_console {} {
FreeConsole
}
proc twapi::get_console_handle {type} {
variable windefs
switch -exact -- $type {
0 -
stdin { set fn "CONIN\$" }
1 -
stdout -
2 -
stderr { set fn "CONOUT\$" }
default {
error "Unknown console handle type '$type'"
}
}
return [CreateFile $fn \
[expr {$windefs(GENERIC_READ) | $windefs(GENERIC_WRITE)}] \
[expr {$windefs(FILE_SHARE_READ) | $windefs(FILE_SHARE_WRITE)}] \
{{} 1} \
$windefs(OPEN_EXISTING) \
0 \
NULL]
}
proc twapi::get_standard_handle {type} {
switch -exact -- $type {
0 -
-11 -
stdin { set type -11 }
1 -
-12 -
stdout { set type -12 }
2 -
-13 -
stderr { set type -13 }
default {
error "Unknown console handle type '$type'"
}
}
return [GetStdHandle $type]
}
proc twapi::set_standard_handle {type handle} {
switch -exact -- $type {
0 -
-11 -
stdin { set type -11 }
1 -
-12 -
stdout { set type -12 }
2 -
-13 -
stderr { set type -13 }
default {
error "Unknown console handle type '$type'"
}
}
return [SetStdHandle $type $handle]
}
array set twapi::_console_input_mode_syms {
-processedinput 0x0001
-lineinput      0x0002
-echoinput      0x0004
-windowinput    0x0008
-mouseinput     0x0010
-insertmode     0x0020
-quickeditmode  0x0040
-extendedmode   0x0080
-autoposition   0x0100
}
array set twapi::_console_output_mode_syms {
-processedoutput 1
-wrapoutput      2
}
array set twapi::_console_output_attr_syms {
-fgblue 1
-fggreen 2
-fgturquoise 3
-fgred 4
-fgpurple 5
-fgyellow 6
-fggray 7
-fgbright 8
-fgwhite 15
-bgblue 16
-bggreen 32
-bgturquoise 48
-bgred 64
-bgyellow 96
-bgbright 128
-bgwhite 240
}
proc twapi::_get_console_input_mode {conh} {
set mode [GetConsoleMode $conh]
return [_bitmask_to_switches $mode twapi::_console_input_mode_syms]
}
interp alias {} twapi::get_console_input_mode {} twapi::_do_console_proc twapi::_get_console_input_mode stdin
proc twapi::_get_console_output_mode {conh} {
set mode [GetConsoleMode $conh]
return [_bitmask_to_switches $mode twapi::_console_output_mode_syms]
}
interp alias {} twapi::get_console_output_mode {} twapi::_do_console_proc twapi::_get_console_output_mode stdout
proc twapi::_set_console_input_mode {conh args} {
set mode [_switches_to_bitmask $args twapi::_console_input_mode_syms]
if {$mode & 0x60} {
setbits mode 0x80;              # ENABLE_EXTENDED_FLAGS
}
SetConsoleMode $conh $mode
}
interp alias {} twapi::set_console_input_mode {} twapi::_do_console_proc twapi::_set_console_input_mode stdin
proc twapi::_modify_console_input_mode {conh args} {
set prev [GetConsoleMode $conh]
set mode [_switches_to_bitmask $args twapi::_console_input_mode_syms $prev]
if {$mode & 0x60} {
setbits mode 0x80;              # ENABLE_EXTENDED_FLAGS
}
SetConsoleMode $conh $mode
return [_bitmask_to_switches $prev twapi::_console_input_mode_syms]
}
interp alias {} twapi::modify_console_input_mode {} twapi::_do_console_proc twapi::_modify_console_input_mode stdin
proc twapi::_set_console_output_mode {conh args} {
set mode [_switches_to_bitmask $args twapi::_console_output_mode_syms]
SetConsoleMode $conh $mode
}
interp alias {} twapi::set_console_output_mode {} twapi::_do_console_proc twapi::_set_console_output_mode stdout
proc twapi::_modify_console_output_mode {conh args} {
set prev [GetConsoleMode $conh]
set mode [_switches_to_bitmask $args twapi::_console_output_mode_syms $prev]
SetConsoleMode $conh $mode
return [_bitmask_to_switches $prev twapi::_console_output_mode_syms]
}
interp alias {} twapi::modify_console_output_mode {} twapi::_do_console_proc twapi::_modify_console_output_mode stdout
proc twapi::create_console_screen_buffer {args} {
array set opts [parseargs args {
{inherit.bool 0}
{mode.arg readwrite {read write readwrite}}
{secd.arg ""}
{share.arg readwrite {none read write readwrite}}
} -maxleftover 0]
switch -exact -- $opts(mode) {
read       { set mode [_access_rights_to_mask generic_read] }
write      { set mode [_access_rights_to_mask generic_write] }
readwrite  {
set mode [_access_rights_to_mask {generic_read generic_write}]
}
}
switch -exact -- $opts(share) {
none {
set share 0
}
read       {
set share 1 ;# FILE_SHARE_READ
}
write      {
set share 2 ;# FILE_SHARE_WRITE
}
readwrite  {
set share 3
}
}
return [CreateConsoleScreenBuffer \
$mode \
$share \
[_make_secattr $opts(secd) $opts(inherit)] \
1]
}
proc twapi::_get_console_screen_buffer_info {conh args} {
array set opts [parseargs args {
all
textattr
cursorpos
maxwindowsize
size
windowpos
windowsize
} -maxleftover 0]
foreach {size cursorpos textattr windowrect maxwindowsize} [GetConsoleScreenBufferInfo $conh] break
set result [list ]
foreach opt {size cursorpos maxwindowsize} {
if {$opts($opt) || $opts(all)} {
lappend result -$opt [set $opt]
}
}
if {$opts(windowpos) || $opts(all)} {
lappend result -windowpos [lrange $windowrect 0 1]
}
if {$opts(windowsize) || $opts(all)} {
foreach {left top right bot} $windowrect break
lappend result -windowsize [list [expr {$right-$left+1}] [expr {$bot-$top+1}]]
}
if {$opts(textattr) || $opts(all)} {
set result [concat $result [_bitmask_to_switches $textattr twapi::_console_output_attr_syms]]
}
return $result
}
interp alias {} twapi::get_console_screen_buffer_info {} twapi::_do_console_proc twapi::_get_console_screen_buffer_info stdout
proc twapi::_set_console_cursor_position {conh pos} {
SetConsoleCursorPosition $conh $pos
}
interp alias {} twapi::set_console_cursor_position {} twapi::_do_console_proc twapi::_set_console_cursor_position stdout
proc twapi::_write_console {conh s args} {
array set opts [parseargs args {
position.arg
{newlinemode.arg column {line column}}
{restoreposition.bool 0}
} -maxleftover 0]
array set csbi [get_console_screen_buffer_info $conh -cursorpos -size]
set oldmode [get_console_output_mode $conh]
set processed_index [lsearch -exact $oldmode "processed"]
if {$processed_index >= 0} {
set newmode [lreplace $oldmode $processed_index $processed_index]
set_console_output_mode $conh $newmode
}
try {
if {[info exists opts(position)]} {
foreach {x y} [_parse_integer_pair $opts(position)] break
} else {
foreach {x y} $csbi(-cursorpos) break
}
set startx [expr {$opts(newlinemode) == "column" ? $x : 0}]
foreach {width height} $csbi(-size) break
set s [string map "\r\n \n" $s]
foreach line [split $s \r\n] {
if {$y >= $height} break
if {$x < $width} {
set num_chars [expr {$width-$x}]
if {[string length $line] < $num_chars} {
set num_chars [string length $line]
}
WriteConsole $conh $line $num_chars
}
incr y
set x $startx
}
} finally {
if {$opts(restoreposition)} {
set_console_cursor_position $conh $csbi(-cursorpos)
}
if {[info exists newmode]} {
set_console_output_mode $conh $oldmode
}
}
return
}
interp alias {} twapi::write_console {} twapi::_do_console_proc twapi::_write_console stdout
proc twapi::_fill_console {conh args} {
array set opts [parseargs args {
position.arg
numlines.int
numcols.int
{mode.arg column {line column}}
window.bool
fillchar.arg
} -ignoreunknown]
set attr [_switches_to_bitmask $args twapi::_console_output_attr_syms]
array set csbi [get_console_screen_buffer_info $conh -windowpos -windowsize -size]
foreach {conx cony} $csbi(-size) break
if {[info exists opts(window)]} {
if {[info exists opts(numlines)] || [info exists opts(numcols)]
|| [info exists opts(position)]} {
error "Option -window cannot be used togther with options -position, -numlines or -numcols"
}
foreach {startx starty} [_parse_integer_pair $csbi(-windowpos)] break
foreach {sizex sizey} [_parse_integer_pair $csbi(-windowsize)] break
} else {
if {[info exists opts(position)]} {
foreach {startx starty} [_parse_integer_pair $opts(position)] break
} else {
set startx 0
set starty 0
}
if {[info exists opts(numlines)]} {
set sizey $opts(numlines)
} else {
set sizey $cony
}
if {[info exists opts(numcols)]} {
set sizex $opts(numcols)
} else {
set sizex [expr {$conx - $startx}]
}
}
set firstcol [expr {$opts(mode) == "column" ? $startx : 0}]
set x $startx
set y $starty
while {$y < $cony && $y < ($starty + $sizey)} {
if {$x < $conx} {
set max [expr {$conx-$x}]
if {[info exists attr]} {
FillConsoleOutputAttribute $conh $attr [expr {$sizex > $max ? $max : $sizex}] [list $x $y]
}
if {[info exists opts(fillchar)]} {
FillConsoleOutputCharacter $conh $opts(fillchar) [expr {$sizex > $max ? $max : $sizex}] [list $x $y]
}
}
incr y
set x $firstcol
}
return
}
interp alias {} twapi::fill_console {} twapi::_do_console_proc twapi::_fill_console stdout
proc twapi::_clear_console {conh args} {
array set opts [parseargs args {
{fillchar.arg " "}
{windowonly.bool 0}
} -maxleftover 0]
array set cinfo [get_console_screen_buffer_info $conh -size -windowpos -windowsize]
foreach {width height} $cinfo(-size) break
if {$opts(windowonly)} {
foreach {x y} $cinfo(-windowpos) break
foreach {w h} $cinfo(-windowsize) break
for {set i 0} {$i < $h} {incr i} {
FillConsoleOutputCharacter \
$conh \
$opts(fillchar)  \
$w \
[list $x [expr {$y+$i}]]
}
} else {
FillConsoleOutputCharacter \
$conh \
$opts(fillchar)  \
[expr {($width*$height) }] \
[list 0 0]
}
return
}
interp alias {} twapi::clear_console {} twapi::_do_console_proc twapi::_clear_console stdout
proc twapi::_flush_console_input {conh} {
FlushConsoleInputBuffer $conh
}
interp alias {} twapi::flush_console_input {} twapi::_do_console_proc twapi::_flush_console_input stdin
proc twapi::_get_console_pending_input_count {conh} {
return [GetNumberOfConsoleInputEvents $conh]
}
interp alias {} twapi::get_console_pending_input_count {} twapi::_do_console_proc twapi::_get_console_pending_input_count stdin
proc twapi::generate_console_control_event {event {procgrp 0}} {
switch -exact -- $event {
ctrl-c {set event 0}
ctrl-break {set event 1}
default {error "Invalid event definition '$event'"}
}
GenerateConsoleCtrlEvent $event $procgrp
}
proc twapi::num_console_mouse_buttons {} {
return [GetNumberOfConsoleMouseButtons]
}
proc twapi::get_console_title {} {
return [GetConsoleTitle]
}
proc twapi::set_console_title {title} {
return [SetConsoleTitle $title]
}
proc twapi::get_console_window {} {
return [GetConsoleWindow]
}
proc twapi::_get_console_window_maxsize {conh} {
return [GetLargestConsoleWindowSize $conh]
}
interp alias {} twapi::get_console_window_maxsize {} twapi::_do_console_proc twapi::_get_console_window_maxsize stdout
proc twapi::_set_console_active_screen_buffer {conh} {
SetConsoleActiveScreenBuffer $conh
}
interp alias {} twapi::set_console_active_screen_buffer {} twapi::_do_console_proc twapi::_set_console_active_screen_buffer stdout
proc twapi::_set_console_screen_buffer_size {conh size} {
SetConsoleScreenBufferSize $conh [_parse_integer_pair $size]
}
interp alias {} twapi::set_console_screen_buffer_size {} twapi::_do_console_proc twapi::_set_console_screen_buffer_size stdout
proc twapi::_set_console_default_attr {conh args} {
SetConsoleTextAttribute $conh [_switches_to_bitmask $args twapi::_console_output_attr_syms]
}
interp alias {} twapi::set_console_default_attr {} twapi::_do_console_proc twapi::_set_console_default_attr stdout
proc twapi::_set_console_window_location {conh rect args} {
array set opts [parseargs args {
{absolute.bool true}
} -maxleftover 0]
SetConsoleWindowInfo $conh $opts(absolute) $rect
}
interp alias {} twapi::set_console_window_location {} twapi::_do_console_proc twapi::_set_console_window_location stdout
proc twapi::get_console_output_codepage {} {
return [GetConsoleOutputCP]
}
proc twapi::set_console_output_codepage {cp} {
SetConsoleOutputCP $cp
}
proc twapi::get_console_input_codepage {} {
return [GetConsoleCP]
}
proc twapi::set_console_input_codepage {cp} {
SetConsoleCP $cp
}
proc twapi::_console_read {conh args} {
if {[llength $args]} {
set oldmode \
[eval modify_console_input_mode [list $conh] $args]
}
try {
return [ReadConsole $conh 1024]
} finally {
if {[info exists oldmode]} {
eval set_console_input_mode $conh $oldmode
}
}
}
interp alias {} twapi::console_gets {} twapi::_do_console_proc twapi::_console_gets stdin
proc twapi::set_console_control_handler {script {timeout 100}} {
if {[string length $script]} {
RegisterConsoleEventNotifier $script $timeout
} else {
UnregisterConsoleEventNotifier
}
}
proc twapi::_do_console_proc {proc default args} {
if {![llength $args]} {
set args [list $default]
}
set conh [lindex $args 0]
switch -exact -- [string tolower $conh] {
stdin  -
stdout -
stderr {
set real_handle [get_console_handle $conh]
try {
lset args 0 $real_handle
return [eval [list $proc] $args]
} finally {
close_handles $real_handle
}
}
}
return [eval [list $proc] $args]
}
#-- from crypto.tcl
namespace eval twapi {
array set _server_security_context_syms {
confidentiality      0x10
connection           0x800
delegate             0x1
extendederror        0x8000
integrity            0x20000
mutualauth           0x2
replaydetect         0x4
sequencedetect       0x8
stream               0x10000
}
array set _client_security_context_syms {
confidentiality      0x10
connection           0x800
delegate             0x1
extendederror        0x4000
integrity            0x10000
manualvalidation     0x80000
mutualauth           0x2
replaydetect         0x4
sequencedetect       0x8
stream               0x8000
usesessionkey        0x20
usesuppliedcreds     0x80
}
}
proc twapi::sspi_enumerate_packages {} {
set packages [list ]
foreach pkg [EnumerateSecurityPackages] {
lappend packages [kl_get $pkg Name]
}
return $packages
}
proc twapi::sspi_new_credentials {args} {
array set opts [parseargs args {
{principal.arg ""}
{package.arg NTLM}
{usage.arg both {inbound outbound both}}
getexpiration
user.arg
{domain.arg ""}
{password.arg ""}
} -maxleftover 0]
if {[info exists opts(user)]} {
set auth [Twapi_Allocate_SEC_WINNT_AUTH_IDENTITY $opts(user) $opts(domain) $opts(password)]
} else {
set auth NULL
}
try {
set creds [AcquireCredentialsHandle $opts(principal) $opts(package) \
[kl_get {inbound 1 outbound 2 both 3} $opts(usage)] \
"" $auth]
} finally {
Twapi_Free_SEC_WINNT_AUTH_IDENTITY $auth; # OK if NULL
}
if {$opts(getexpiration)} {
return [kl_create2 {-handle -expiration} $creds]
} else {
return [lindex $creds 0]
}
}
proc twapi::sspi_free_credentials {cred} {
FreeCredentialsHandle $cred
}
proc ::twapi::sspi_client_new_context {cred args} {
array set opts [parseargs args {
target.arg
{datarep.arg network {native network}}
confidentiality.bool
connection.bool
delegate.bool
extendederror.bool
integrity.bool
manualvalidation.bool
mutualauth.bool
replaydetect.bool
sequencedetect.bool
stream.bool
usesessionkey.bool
usesuppliedcreds.bool
} -maxleftover 0 -nulldefault]
set context_flags 0
foreach {opt flag} [array get ::twapi::_client_security_context_syms] {
if {$opts($opt)} {
set context_flags [expr {$context_flags | $flag}]
}
}
set drep [kl_get {native 0x10 network 0} $opts(datarep)]
return [_construct_sspi_security_context \
[InitializeSecurityContext \
$cred \
"" \
$opts(target) \
$context_flags \
0 \
$drep \
[list ] \
0] \
client \
$context_flags \
$opts(target) \
$cred \
$drep \
]
}
proc twapi::sspi_close_security_context {ctx} {
DeleteSecurityContext [kl_get $ctx -handle]
}
proc twapi::sspi_security_context_next {ctx {response ""}} {
switch -exact -- [kl_get $ctx -state] {
ok {
if {[string length $response]} {
error "Unexpected remote response data passed."
}
set data ""
foreach buf [kl_get $ctx -output] {
append data [lindex $buf 1]
}
return [list done $data [kl_set $ctx -output [list ]]]
}
continue {
set data ""
foreach buf [kl_get $ctx -output] {
append data [lindex $buf 1]
}
if {[string length $response] != 0} {
set inbuflist [list [list 2 $response]]
if {[kl_get $ctx -type] eq "client"} {
set rawctx [InitializeSecurityContext \
[kl_get $ctx -credentials] \
[kl_get $ctx -handle] \
[kl_get $ctx -target] \
[kl_get $ctx -inattr] \
0 \
[kl_get $ctx -datarep] \
$inbuflist \
0]
} else {
set rawctx [AcceptSecurityContext \
[kl_get $ctx -credentials] \
[kl_get $ctx -handle] \
$inbuflist \
[kl_get $ctx -inattr] \
[kl_get $ctx -datarep] \
]
}
set newctx [_construct_sspi_security_context \
$rawctx \
[kl_get $ctx -type] \
[kl_get $ctx -inattr] \
[kl_get $ctx -target] \
[kl_get $ctx -credentials] \
[kl_get $ctx -datarep] \
]
return [sspi_security_context_next $newctx]
} elseif {[string length $data] != 0} {
return [list continue $data [kl_set $ctx -output [list ]]]
} else {
error "No token data available to send to remote system"
}
}
complete -
complete_and_continue -
incomplete_message {
error "State '[kl_get $ctx -state]' handling not implemented."
}
}
}
proc ::twapi::sspi_server_new_context {cred clientdata args} {
array set opts [parseargs args {
{datarep.arg network {native network}}
confidentiality.bool
connection.bool
delegate.bool
extendederror.bool
integrity.bool
mutualauth.bool
replaydetect.bool
sequencedetect.bool
stream.bool
} -maxleftover 0 -nulldefault]
set context_flags 0
foreach {opt flag} [array get ::twapi::_server_security_context_syms] {
if {$opts($opt)} {
set context_flags [expr {$context_flags | $flag}]
}
}
set drep [kl_get {native 0x10 network 0} $opts(datarep)]
return [_construct_sspi_security_context \
[AcceptSecurityContext \
$cred \
"" \
[list [list 2 $clientdata]] \
$context_flags \
$drep] \
server \
$context_flags \
"" \
$cred \
$drep \
]
}
proc ::twapi::sspi_get_security_context_features {ctx} {
set flags [QueryContextAttributes [kl_get $ctx -handle] 14]
if {[kl_get $ctx -type] eq "client"} {
upvar 0 ::twapi::_client_security_context_syms syms
} else {
upvar 0 ::twapi::_server_security_context_syms syms
}
set result [list -raw $flags]
foreach {sym flag} [array get syms] {
lappend result -$sym [expr {($flag & $flags) != 0}]
}
return $result
}
proc twapi::sspi_get_security_context_username {ctx} {
return [QueryContextAttributes [kl_get $ctx -handle] 1]
}
proc twapi::sspi_get_security_context_sizes {ctx} {
if {![kl_vget $ctx -sizes sizes]} {
set sizes [QueryContextAttributes [kl_get $ctx -handle] 0]
}
return [kl_create2 {-maxtoken -maxsig -blocksize -trailersize} $sizes]
}
proc twapi::sspi_generate_signature {ctx data args} {
array set opts [parseargs args {
{seqnum.int 0}
{qop.int 0}
} -maxleftover 0]
return [MakeSignature \
[kl_get $ctx -handle] \
$opts(qop) \
$data \
$opts(seqnum)]
}
proc twapi::sspi_verify_signature {ctx data sig args} {
array set opts [parseargs args {
{seqnum.int 0}
} -maxleftover 0]
return [VerifySignature \
[kl_get $ctx -handle] \
[list [list 2 $sig] [list 1 $data]] \
$opts(seqnum)]
}
proc twapi::sspi_encrypt {ctx data args} {
array set opts [parseargs args {
{seqnum.int 0}
{qop.int 0}
} -maxleftover 0]
return [EncryptMessage \
[kl_get $ctx -handle] \
$opts(qop) \
$data \
$opts(seqnum)]
}
proc twapi::sspi_decrypt {ctx data sig padding args} {
array set opts [parseargs args {
{seqnum.int 0}
} -maxleftover 0]
set decrypted [DecryptMessage \
[kl_get $ctx -handle] \
[list [list 2 $sig] [list 1 $data] [list 9 $padding]] \
$opts(seqnum)]
set plaintext ""
foreach buf [lindex $decrypted 0] {
if {[lindex $buf 0] == 1} {
append plaintext [lindex $buf 1]
}
}
return $plaintext
}
proc twapi::_construct_sspi_security_context {ctx ctxtype inattr target credentials datarep} {
set result [kl_create2 \
{-state -handle -output -outattr -expiration} \
$ctx]
set result [kl_set $result -type $ctxtype]
set result [kl_set $result -inattr $inattr]
set result [kl_set $result -target $target]
set result [kl_set $result -datarep $datarep]
return [kl_set $result -credentials $credentials]
}
proc twapi::_sspi_sample {} {
set ccred [sspi_new_credentials -usage outbound]
set scred [sspi_new_credentials -usage inbound]
set cctx [sspi_client_new_context $ccred -target LUNA -confidentiality true -connection true]
foreach {step data cctx} [sspi_security_context_next $cctx] break
set sctx [sspi_server_new_context $scred $data]
foreach {step data sctx} [sspi_security_context_next $sctx] break
foreach {step data cctx} [sspi_security_context_next $cctx $data] break
foreach {step data sctx} [sspi_security_context_next $sctx $data] break
sspi_free_credentials $scred
sspi_free_credentials $ccred
return [list $cctx $sctx]
}
#-- from desktop.tcl
proc twapi::get_current_window_station_handle {} {
return [GetProcessWindowStation]
}
proc twapi::get_window_station_handle {winsta args} {
array set opts [parseargs args {
inherit.bool
{access.arg  GENERIC_READ}
} -nulldefault]
set access_rights [_access_rights_to_mask $opts(access)]
return [OpenWindowStation $winsta $opts(inherit) $access_rights]
}
proc twapi::close_window_station_handle {hwinsta} {
if {$hwinsta != [get_current_window_station_handle]} {
CloseWindowStation $hwinsta
}
return
}
proc twapi::find_window_stations {} {
return [EnumWindowStations]
}
proc twapi::find_desktops {args} {
array set opts [parseargs args {winsta.arg}]
if {[info exists opts(winsta)]} {
set hwinsta [get_window_station_handle $opts(winsta)]
} else {
set hwinsta [get_current_window_station_handle]
}
try {
return [EnumDesktops $hwinsta]
} finally {
close_window_station_handle $hwinsta
}
}
proc twapi::get_desktop_handle {desk args} {
array set opts [parseargs args {
inherit.bool
allowhooks.bool
{access.arg  GENERIC_READ}
} -nulldefault]
set access_mask [_access_rights_to_mask $opts(access)]
set access_rights [_access_mask_to_rights $access_mask]
if {[lsearch -exact $access_rights read_control] >= 0 ||
[lsearch -exact $access_rights write_dac] >= 0 ||
[lsearch -exact $access_rights write_owner] >= 0} {
lappend access_rights desktop_readobject desktop_writeobjects
set access_mask [_access_rights_to_mask $opts(access)]
}
return [OpenDesktop $desk $opts(allowhooks) $opts(inherit) $access_mask]
}
proc twapi::close_desktop_handle {hdesk} {
CloseDesktop $hdesk
}
proc twapi::set_process_window_station {hwinsta} {
SetProcessWindowStation $hwinsta
}
#-- from device.tcl
proc twapi::_device_change_callback {script args} {
set event [lindex $args 0]
if {[lindex $args 1] eq "devtyp_volume" &&
($event eq "deviceremovecomplete" || $event eq "devicearrival")} {
set args [lreplace $args 2 2 [_drivemask_to_drivelist [lindex $args 2]]]
set attrs [list ]
set flags [lindex $args 3]
if {$flags & 1} {
lappend attrs mediachange
}
if {$flags & 2} {
lappend attrs networkvolume
}
set args [lreplace $args 3 3 $attrs]
}
eval $script $args
}
proc twapi::start_device_change_monitor {script args} {
array set opts [parseargs args {
deviceinterface.arg
} -maxleftover 0 -nulldefault]
switch -exact -- $opts(deviceinterface) {
port            { set type 3 ; set opts(deviceinterface) "" }
volume          { set type 2 ; set opts(deviceinterface) "" }
default {
set type 5
}
}
set hwnd [Twapi_DeviceChangeNotifyStart [list ::twapi::_device_change_callback $script] $type $opts(deviceinterface)]
return $hwnd
}
interp alias {} ::twapi::stop_device_change_monitor {} ::twapi::Twapi_DeviceChangeNotifyStop
proc twapi::update_devinfoset {args} {
array set opts [parseargs args {
{guid.arg ""}
{classtype.arg setup {interface setup}}
{presentonly.bool false}
{currentprofileonly.bool false}
{deviceinfoset.arg NULL}
{hwin.int 0}
{system.arg ""}
{pnpname.arg ""}
} -maxleftover 0]
set flags [expr {$opts(guid) eq "" ? 0x4 : 0}]
if {$opts(classtype) eq "interface"} {
set flags [expr {$flags | 0x10}]
}
if {$opts(presentonly)} {
set flags [expr {$flags | 0x2}]
}
if {$opts(currentprofileonly)} {
set flags [expr {$flags | 0x8}]
}
return [SetupDiGetClassDevsEx \
$opts(guid) \
$opts(pnpname) \
$opts(hwin) \
$flags \
$opts(deviceinfoset) \
$opts(system)]
}
interp alias {} twapi::close_devinfoset {} twapi::SetupDiDestroyDeviceInfoList
proc twapi::get_devinfoset_elements {hdevinfo} {
set result [list ]
set i 0
set devinfo_data_buf [_alloc_SP_DEVINFO_DATA]
try {
while {true} {
SetupDiEnumDeviceInfo $hdevinfo $i $devinfo_data_buf
lappend result [_decode_SP_DEVINFO_DATA $devinfo_data_buf]
incr i
}
} onerror {TWAPI_WIN32 259} {
} finally {
free $devinfo_data_buf
}
return $result
}
proc twapi::get_devinfoset_registry_properties {hdevinfo args} {
set result [list ]
set devinfo_data_buf [_alloc_SP_DEVINFO_DATA]
try {
set propval_buf_sz 256
set propval_buf [malloc_and_cast $propval_buf_sz BYTE]
set i 0
while {true} {
SetupDiEnumDeviceInfo $hdevinfo $i $devinfo_data_buf
set item [list -deviceelement [_decode_SP_DEVINFO_DATA $devinfo_data_buf]]
foreach prop $args {
set prop [_device_registry_sym_to_code $prop]
try {
while {true} {
foreach {status regtype size} \
[SetupDiGetDeviceRegistryProperty \
$hdevinfo \
$devinfo_data_buf \
$prop \
$propval_buf \
$propval_buf_sz] \
break
if {$status} {
break
}
free $propval_buf
set propval_buf ""; # In case of exception, do not want to free in finally clause!
set propval_buf_sz $size
set propval_buf [malloc_and_cast $propval_buf_sz BYTE]
}
lappend item $prop [list success [_decode_mem_registry_value $regtype $propval_buf $size]]
} onerror {} {
lappend item $prop [list fail $errorCode]
}
}
lappend result $item
incr i
}
} onerror {TWAPI_WIN32 259} {
} finally {
free $devinfo_data_buf
if {[info exists propval_buf] && $propval_buf ne ""} {
free $propval_buf
}
}
return $result
}
proc twapi::get_devinfoset_interface_details {hdevinfo guid args} {
set result [list ]
array set opts [parseargs args {
matchdeviceelement.arg
interfaceclass
flags
devicepath
deviceelement
ignoreerrors
} -maxleftover 0]
if {[info exists opts(matchdeviceelement)]} {
set devinfo_data_buf [_alloc_SP_DEVINFO_DATA $opts(matchdeviceelement)]
} else {
set devinfo_data_buf NULL
}
set interface_data_buf [_alloc_SP_DEVICE_INTERFACE_DATA]
if {$opts(devicepath)} {
set device_path_buf_sz 256
set device_path_buf [malloc_and_cast $device_path_buf_sz SP_DEVICE_INTERFACE_DETAIL_DATA_W 6]
} else {
set device_path_buf_sz 0
set device_path_buf NULL
}
if {$opts(deviceelement)} {
set element_buf [_alloc_SP_DEVINFO_DATA]
} else {
set element_buf NULL
}
try {
set i 0
while {true} {
SetupDiEnumDeviceInterfaces $hdevinfo $devinfo_data_buf $guid $i $interface_data_buf
set item [list ]
if {$opts(interfaceclass)} {
lappend item -interfaceclass [_decode_mem_guid $interface_data_buf 4]
}
if {$opts(flags)} {
set flags    [Twapi_ReadMemoryInt $interface_data_buf 20]
set symflags [_make_symbolic_bitmask $flags {active 1 default 2 removed 4} false]
lappend item -flags [linsert $symflags 0 $flags]
}
if {$opts(devicepath) || $opts(deviceelement)} {
try {
while {true} {
foreach {status size} \
[SetupDiGetDeviceInterfaceDetail \
$hdevinfo \
$interface_data_buf \
$device_path_buf \
$device_path_buf_sz \
$element_buf] break
if {$status || ! $opts(devicepath)} {
break
}
free $device_path_buf
set device_path_buf NULL; # In case of exception
set device_path_buf_sz $size
set device_path_buf [malloc_and_cast $device_path_buf_sz SP_DEVICE_INTERFACE_DETAIL_DATA_W 6]
}
if {$opts(deviceelement)} {
lappend item -deviceelement [list [_decode_mem_guid $element_buf 4] [Twapi_ReadMemoryInt $element_buf 20]]
}
if {$opts(devicepath)} {
lappend item -devicepath [Twapi_ReadMemoryUnicode $device_path_buf 4 -1]
}
} onerror {} {
if {! $opts(ignoreerrors)} {
error $errorResult $errorInfo $errorCode
}
}
}
lappend result $item
incr i
}
} onerror {TWAPI_WIN32 259} {
} finally {
free $devinfo_data_buf; # OK to pass NULL
free $interface_data_buf
}
return $result
}
proc twapi::device_setup_class_name_to_guids {name} {
set n 8;                    # Assume at most 8 guids
try {
while {true} {
set p [malloc_and_cast [expr {16*$n}] GUID]
set count [twapi::SetupDiClassGuidsFromNameEx $name $p $n]
if {$count <= $n} {
set guids [list ]
set bin [Twapi_ReadMemoryBinary $p 0 [expr {16*$count}]]
for {set i 0} {$i < $count} {incr i} {
lappend guids [_binary_to_guid $bin [expr {16*$i}]]
}
return $guids;  # p is freed in finally clause below
} else {
free $p
unset p
set n $count
}
}
} finally {
if {[info exists p]} {
free $p
}
}
}
interp alias {} twapi::device_setup_class_guid_to_name {} twapi::SetupDiClassNameFromGuidEx
interp alias {} twapi::get_device_element_instance_id {} twapi::SetupDiGetDeviceInstanceId
proc twapi::_init_device_registry_code_maps {} {
variable _device_registry_syms
variable _device_registry_codes
set _device_registry_code_syms {
devicedesc hardwareid compatibleids unused0 service unused1
unused2 class classguid driver configflags mfg friendlyname
location physical capabilities ui upperfilters lowerfilters
bustypeguid legacybustype busnumber enumerator security
security devtype exclusive characteristics address ui device
removal removal removal install location
}
set i 0
foreach sym $_device_registry_code_syms {
set _device_registry_codes($sym) $i
incr i
}
}
proc twapi::_device_registry_code_to_sym {code} {
_init_device_registry_code_maps
proc ::twapi::_device_registry_code_to_sym {code} {
variable _device_registry_code_syms
if {$code >= [llength $_device_registry_code_syms]} {
return $code
} else {
return [lindex $_device_registry_code_syms $code]
}
}
return [_device_registry_code_to_sym $code]
}
proc twapi::_device_registry_sym_to_code {sym} {
_init_device_registry_code_maps
proc ::twapi::_device_registry_sym_to_code {sym} {
variable _device_registry_codes
if {[info exists _device_registry_codes($sym)]} {
return $_device_registry_codes($sym)
} elseif {[string is integer -strict $sym]} {
return $sym
} else {
error "Unknown or unsupported device registry property symbol '$sym'"
}
}
return [_device_registry_sym_to_code $sym]
}
proc twapi::_alloc_SP_DEVINFO_DATA {{deviceelement {}}} {
set buf [malloc_and_cast 28 SP_DEVINFO_DATA 28]; # Als inits cbSize
if {[llength $deviceelement]} {
if {[llength $deviceelement] != 3} {
error "Invalid device element."
}
Twapi_WriteMemoryBinary $buf 4 28 [_guid_to_binary [lindex $deviceelement 0]]
Twapi_WriteMemoryInt $buf 20 28 [lindex $deviceelement 1]
Twapi_WriteMemoryInt $buf 24 28 [lindex $deviceelement 2]
}
return $buf
}
proc twapi::_alloc_SP_DEVICE_INTERFACE_DATA {{interfaceclass ""} {flags 0}} {
set buf [malloc_and_cast 28 SP_DEVICE_INTERFACE_DATA 28]; # Also inits cbSize
if {$interfaceclass ne ""} {
Twapi_WriteMemoryBinary $buf 4 28 [_guid_to_binary $interfaceclass]; # InterfaceClassGuid
Twapi_WriteMemoryInt $buf 20 28 $flags; # Flags
Twapi_WriteMemoryInt $buf 24 28 0;      # Reserved
}
return $buf
}
proc twapi::_decode_SP_DEVINFO_DATA {mem} {
return [list [_decode_mem_guid $mem 4] [Twapi_ReadMemoryInt $mem 20] [Twapi_ReadMemoryInt $mem 24]]
}
proc twapi::device_ioctl {h code args} {
variable _ioctl_membuf;     # Memory buffer is reused so we do not allocate every time
variable _ioctl_membuf_size
array set opts [parseargs args {
{inputbuffer.arg NULL}
{inputcount.int 0}
} -maxleftover 0]
if {![info exists _ioctl_membuf]} {
set _ioctl_membuf_size 128
set _ioctl_membuf [malloc $_ioctl_membuf_size]
}
while {true} {
try {
set outcount [DeviceIoControl $h $code $opts(inputbuffer) $opts(inputcount) $_ioctl_membuf $_ioctl_membuf_size NULL]
} onerror {TWAPI_WIN32 122} {
set newsize [expr {$_ioctl_membuf_size * 2}]
set newbuf [malloc $newsize]
set _ioctl_membuf $newbuf
set _ioctl_membuf_size $newsize
continue
}
break
}
set bin [Twapi_ReadMemoryBinary $_ioctl_membuf 0 $outcount]
if {$_ioctl_membuf_size >= 1000} {
free $_ioctl_membuf
unset _ioctl_membuf
set _ioctl_membuf_size 0
}
return $bin
}
#-- from disk.tcl
proc twapi::get_volume_info {drive args} {
variable windefs
set drive [_drive_rootpath $drive]
array set opts [parseargs args {
all size freespace used useravail type serialnum label maxcomponentlen fstype attr device extents
} -maxleftover 0]
if {$opts(all)} {
set device_requested $opts(device)
set type_requested   $opts(type)
_array_set_all opts 1
set opts(device) $device_requested
set opts(type)   $type_requested
}
set result [list ]
if {$opts(size) || $opts(freespace) || $opts(used) || $opts(useravail)} {
foreach {useravail size freespace} [GetDiskFreeSpaceEx $drive] {break}
foreach opt {size freespace useravail}  {
if {$opts($opt)} {
lappend result -$opt [set $opt]
}
}
if {$opts(used)} {
lappend result -used [expr {$size - $freespace}]
}
}
if {$opts(type)} {
set drive_type [get_drive_type $drive]
lappend result -type $drive_type
}
if {$opts(device)} {
if {[_is_unc $drive]} {
lappend result -device ""
} else {
lappend result -device [QueryDosDevice [string range $drive 0 1]]
}
}
if {$opts(extents)} {
set extents {}
if {! [_is_unc $drive]} {
set device_handle [create_file "\\\\.\\[string range $drive 0 1]" -createdisposition open_existing]
try {
set bin [device_ioctl $device_handle 0x560000]
if {[binary scan $bin i nextents] != 1} {
error "Truncated information returned from ioctl 0x560000"
}
set off 8
for {set i 0} {$i < $nextents} {incr i} {
if {[binary scan $bin "@$off i x4 w w" extent(-disknumber) extent(-startingoffset) extent(-extentlength)] != 3} {
error "Truncated information returned from ioctl 0x560000"
}
lappend extents [array get extent]
incr off 24; # Size of one extent element
}
} finally {
close_handles $device_handle
}
}
lappend result -extents $extents
}
if {$opts(serialnum) || $opts(label) || $opts(maxcomponentlen)
|| $opts(fstype) || $opts(attr)} {
foreach {label serialnum maxcomponentlen attr fstype} \
[GetVolumeInformation $drive] { break }
foreach opt {label maxcomponentlen fstype}  {
if {$opts($opt)} {
lappend result -$opt [set $opt]
}
}
if {$opts(serialnum)} {
set low [expr {$serialnum & 0x0000ffff}]
set high [expr {($serialnum >> 16) & 0x0000ffff}]
lappend result -serialnum [format "%.4X-%.4X" $high $low]
}
if {$opts(attr)} {
set attrs [list ]
foreach val {
case_preserved_names
unicode_on_disk
persistent_acls
file_compression
volume_quotas
supports_sparse_files
supports_reparse_points
supports_remote_storage
volume_is_compressed
supports_object_ids
supports_encryption
named_streams
read_only_volume
} {
set cdef "FILE_[string toupper $val]"
if {$attr & $windefs($cdef)} {
lappend attrs $val
}
}
lappend result -attr $attrs
}
}
return $result
}
interp alias {} twapi::get_drive_info {} twapi::get_volume_info
proc twapi::user_drive_space_available {drv space} {
return [expr {$space <= [lindex [get_drive_info $drv -useravail] 1]}]
}
proc twapi::get_drive_type {drive} {
set type [GetDriveType [_drive_rootpath $drive]]
switch -exact -- $type {
0 { return unknown}
1 { return invalid}
2 { return removable}
3 { return fixed}
4 { return remote}
5 { return cdrom}
6 { return ramdisk}
}
}
proc twapi::find_logical_drives {args} {
array set opts [parseargs args {type.arg}]
set drives [list ]
foreach drive [_drivemask_to_drivelist [GetLogicalDrives]] {
if {(![info exists opts(type)]) ||
[lsearch -exact $opts(type) [get_drive_type $drive]] >= 0} {
lappend drives $drive
}
}
return $drives
}
interp alias {} twapi::get_logical_drives {} twapi::find_logical_drives
proc twapi::set_drive_label {drive label} {
SetVolumeLabel [_drive_rootpath $drive] $label
}
proc twapi::map_drive_local {drive path args} {
array set opts [parseargs args {raw}]
set drive [string range [_drive_rootpath $drive] 0 1]
set flags [expr {$opts(raw) ? 0x1 : 0}]
DefineDosDevice $flags $drive [file nativename $path]
}
proc twapi::unmap_drive_local {drive args} {
array set opts [parseargs args {
path.arg
raw
}]
set drive [string range [_drive_rootpath $drive] 0 1]
set flags [expr {$opts(raw) ? 0x1 : 0}]
setbits flags 0x2;                  # DDD_REMOVE_DEFINITION
if {[info exists opts(path)]} {
setbits flags 0x4;              # DDD_EXACT_MATCH_ON_REMOVE
}
DefineDosDevice $flags $drive [file nativename $opts(path)]
}
proc twapi::begin_filesystem_monitor {path script args} {
array set opts [parseargs args {
{subtree.bool false}
filename.bool
dirname.bool
attr.bool
size.bool
write.bool
access.bool
create.bool
secd.bool
{pattern.arg ""}
{patterns.arg ""}
} -maxleftover 0]
if {[string length $opts(pattern)] &&
[llength $opts(patterns)]} {
error "Options -pattern and -patterns are mutually exclusive. Note option -pattern is deprecated."
}
if {[string length $opts(pattern)]} {
set opts(patterns) [list "+$opts(pattern)"]
}
if {[llength $opts(patterns)]} {
foreach pat $opts(patterns) {
lappend pats [string map [list / \\\\] $pat]
}
set opts(patterns) $pats
}
set have_opts 0
set flags 0
foreach {opt val} {
filename 0x1
dirname  0x2
attr     0x4
size     0x8
write 0x10
access 0x20
create  0x40
secd      0x100
} {
if {[info exists opts($opt)]} {
if {$opts($opt)} {
setbits flags $val
}
set have_opts 1
}
}
if {! $have_opts} {
set flags 0x17f
}
return [RegisterDirChangeNotifier $path $opts(subtree) $flags $script $opts(patterns)]
}
proc twapi::cancel_filesystem_monitor {id} {
UnregisterDirChangeNotifier $id
}
proc twapi::find_volumes {} {
set vols [list ]
set found 1
foreach {handle vol} [FindFirstVolume] break
while {$found} {
lappend vols $vol
foreach {found vol} [FindNextVolume $handle] break
}
FindVolumeClose $handle
return $vols
}
proc twapi::find_volumes {} {
set vols [list ]
set found 1
foreach {handle vol} [FindFirstVolume] break
while {$found} {
lappend vols $vol
foreach {found vol} [FindNextVolume $handle] break
}
FindVolumeClose $handle
return $vols
}
proc twapi::find_volume_mount_points {vol} {
set mntpts [list ]
set found 1
try {
foreach {handle mntpt} [FindFirstVolumeMountPoint $vol] break
} onerror {TWAPI_WIN32 18} {
return [list ]
} onerror {TWAPI_WIN32 3} {
return [list ]
}
while {$found} {
lappend mntpts $mntpt
foreach {found mntpt} [FindNextVolumeMountPoint $handle] break
}
FindVolumeMountPointClose $handle
return $mntpts
}
proc twapi::mount_volume {volpt volname} {
SetVolumeMountPoint "[string trimright $volpt /\\]\\" "[string trimright $volname /\\]\\"
}
proc twapi::unmount_volume {volpt} {
DeleteVolumeMountPoint "[string trimright $volpt /\\]\\"
}
proc twapi::get_mounted_volume_name {volpt} {
return [GetVolumeNameForVolumeMountPoint "[string trimright $volpt /\\]\\"]
}
proc twapi::get_volume_mount_point_for_path {path} {
return [GetVolumePathName [file nativename $path]]
}
proc twapi::volume_properties_dialog {name args} {
array set opts [parseargs args {
{hwin.int 0}
{page.arg ""}
} -maxleftover 0]
shell_object_properties_dialog $name -type volume -hwin $opts(hwin) -page $opts(page)
}
proc twapi::file_properties_dialog {name args} {
array set opts [parseargs args {
{hwin.int 0}
{page.arg ""}
} -maxleftover 0]
shell_object_properties_dialog $name -type file -hwin $opts(hwin) -page $opts(page)
}
proc twapi::get_file_version_resource {path args} {
array set opts [parseargs args {
all
datetime
signature
structversion
fileversion
productversion
flags
fileos
filetype
foundlangid
foundcodepage
langid.arg
codepage.arg
}]
set ver [Twapi_GetFileVersionInfo $path]
try {
array set verinfo [Twapi_VerQueryValue_FIXEDFILEINFO $ver]
set result [list ]
if {$opts(all) || $opts(signature)} {
lappend result -signature [format 0x%x $verinfo(dwSignature)]
}
if {$opts(all) || $opts(structversion)} {
lappend result -structversion "[expr {0xffff & ($verinfo(dwStrucVersion) >> 16)}].[expr {0xffff & $verinfo(dwStrucVersion)}]"
}
if {$opts(all) || $opts(fileversion)} {
lappend result -fileversion "[expr {0xffff & ($verinfo(dwFileVersionMS) >> 16)}].[expr {0xffff & $verinfo(dwFileVersionMS)}].[expr {0xffff & ($verinfo(dwFileVersionLS) >> 16)}].[expr {0xffff & $verinfo(dwFileVersionLS)}]"
}
if {$opts(all) || $opts(productversion)} {
lappend result -productversion "[expr {0xffff & ($verinfo(dwProductVersionMS) >> 16)}].[expr {0xffff & $verinfo(dwProductVersionMS)}].[expr {0xffff & ($verinfo(dwProductVersionLS) >> 16)}].[expr {0xffff & $verinfo(dwProductVersionLS)}]"
}
if {$opts(all) || $opts(flags)} {
set flags [expr {$verinfo(dwFileFlags) & $verinfo(dwFileFlagsMask)}]
lappend result -flags \
[_make_symbolic_bitmask \
[expr {$verinfo(dwFileFlags) & $verinfo(dwFileFlagsMask)}] \
{
debug 1
prerelease 2
patched 4
privatebuild 8
infoinferred 16
specialbuild 32
} \
]
}
if {$opts(all) || $opts(fileos)} {
switch -exact -- [format %08x $verinfo(dwFileOS)] {
00010000 {set os dos}
00020000 {set os os216}
00030000 {set os os232}
00040000 {set os nt}
00050000 {set os wince}
00000001 {set os windows16}
00000002 {set os pm16}
00000003 {set os pm32}
00000004 {set os windows32}
00010001 {set os dos_windows16}
00010004 {set os dos_windows32}
00020002 {set os os216_pm16}
00030003 {set os os232_pm32}
00040004 {set os nt_windows32}
default {set os $verinfo(dwFileOS)}
}
lappend result -fileos $os
}
if {$opts(all) || $opts(filetype)} {
switch -exact -- [expr {0+$verinfo(dwFileType)}] {
1 {set type application}
2 {set type dll}
3 {
set type "driver."
switch -exact -- [expr {0+$verinfo(dwFileSubtype)}] {
1 {append type printer}
2 {append type keyboard}
3 {append type language}
4 {append type display}
5 {append type mouse}
6 {append type network}
7 {append type system}
8 {append type installable}
9  {append type sound}
10 {append type comm}
11 {append type inputmethod}
12 {append type versionedprinter}
default {append type $verinfo(dwFileSubtype)}
}
}
4 {
set type "font."
switch -exact -- [expr {0+$verinfo(dwFileSubtype)}] {
1 {append type raster}
2 {append type vector}
3 {append type truetype}
default {append type $verinfo(dwFileSubtype)}
}
}
5 { set type "vxd.$verinfo(dwFileSubtype)" }
7 {set type staticlib}
default {
set type "$verinfo(dwFileType).$verinfo(dwFileSubtype)"
}
}
lappend result -filetype $type
}
if {$opts(all) || $opts(datetime)} {
lappend result -datetime [expr {(wide($verinfo(dwFileDateMS)) << 32) + $verinfo(dwFileDateLS)}]
}
if {[llength $args] || $opts(foundlangid) || $opts(foundcodepage) || $opts(all)} {
set langid [expr {[info exists opts(langid)] ? $opts(langid) : [get_user_ui_langid]}]
set primary_langid [extract_primary_langid $langid]
set sub_langid     [extract_sublanguage_langid $langid]
set cp [expr {[info exists opts(codepage)] ? $opts(codepage) : 0}]
set match(7) "00000000";    # In case list is empty
foreach langcp [Twapi_VerQueryValue_TRANSLATIONS $ver] {
set verlangid 0x[string range $langcp 0 3]
set vercp 0x[string range $langcp 4 7]
if {$verlangid == $langid && $vercp == $cp} {
set match(0) $langcp
break;              # No need to look further
}
if {[info exists match(1)]} continue
if {$verlangid == $langid} {
set match(1) $langcp
continue;           # Continue to look for match(0)
}
if {[info exists match(2)]} continue
set verprimary [extract_primary_langid $verlangid]
if {$verprimary == $primary_langid && $vercp == $cp} {
set match(2) $langcp
continue;       # Continue to look for match(1) or better
}
if {[info exists match(3)]} continue
if {$verprimary == $primary_langid} {
set match(3) $langcp
continue;       # Continue to look for match(2) or better
}
if {[info exists match(4)]} continue
if {$verprimary == 0} {
set match(4) $langcp; # LANG_NEUTRAL
continue;       # Continue to look for match(3) or better
}
if {[info exists match(5)]} continue
if {$verprimary == 9} {
set match(5) $langcp; # English
continue;       # Continue to look for match(4) or better
}
if {![info exists match(6)]} {
set match(6) $langcp
}
}
for {set i 0} {$i <= 7} {incr i} {
if {[info exists match($i)]} {
break
}
}
if {$opts(foundlangid) || $opts(all)} {
set langid 0x[string range $match($i) 0 3] 
lappend result -foundlangid [list $langid [VerLanguageName $langid]]
}
if {$opts(foundcodepage) || $opts(all)} {
lappend result -foundcodepage 0x[string range $match($i) 4 7]
}
foreach sname $args {
lappend result $sname [Twapi_VerQueryValue_STRING $ver $match($i) $sname]
}
}
} finally {
Twapi_FreeFileVersionInfo $ver
}
return $result
}
proc twapi::get_file_times {fd args} {
variable windefs
array set opts [parseargs args {
all
mtime
ctime
atime
} -maxleftover 0]
set close_handle false
if {[file exists $fd]} {
set close_handle true
set h [create_file $fd -createdisposition open_existing]
set h [CastToHANDLE $h]
} elseif {[catch {fconfigure $fd}]} {
if {[_is_win32_handle $fd]} {
set h $fd
} else {
error "$fd is not an existing file, handle or Tcl channel."
}
} else {
set h [get_tcl_channel_handle $fd read]
}
set result [list ]
foreach opt {ctime atime mtime} time [GetFileTime $h] {
if {$opts(all) || $opts($opt)} {
lappend result -$opt $time
}
}
if {$close_handle} {
close_handles $h
}
return $result
}
proc twapi::set_file_times {fd args} {
variable windefs
array set opts [parseargs args {
mtime.arg
ctime.arg
atime.arg
preserveatime
} -maxleftover 0 -nulldefault]
if {$opts(atime) ne "" && $opts(preserveatime)} {
win32_error 87 "Cannot specify -atime and -preserveatime at the same time."
}
if {$opts(preserveatime)} {
set opts(atime) -1;             # Meaning preserve access to original
}
set close_handle false
if {[file exists $fd]} {
if {$opts(preserveatime)} {
win32_error 87 "Cannot specify -preserveatime unless file is specified as a Tcl channel or a Win32 handle."
}
set close_handle true
set h [create_file $fd -access {generic_write} -createdisposition open_existing]
set h [CastToHANDLE $h]
} elseif {[catch {fconfigure $fd}]} {
set h $fd
} else {
set h [get_tcl_channel_handle $fd read]
}
SetFileTime $h $opts(ctime) $opts(atime) $opts(mtime)
if {$close_handle} {
close_handles $h
}
return
}
proc twapi::find_physical_disks {} {
set guid {{53F56307-B6BF-11D0-94F2-00A0C91EFB8B}}
set hdevinfo [update_devinfoset \
-guid $guid \
-presentonly true \
-classtype interface]
try {
return [kl_flatten [get_devinfoset_interface_details $hdevinfo $guid -devicepath] -devicepath]
} finally {
close_devinfoset $hdevinfo
}
}
proc twapi::get_physical_disk_info {disk args} {
set result [list ]
array set opts [parseargs args {
geometry
layout
all
} -maxleftover 0]
if {$opts(all) || $opts(geometry) || $opts(layout)} {
set h [create_file $disk -createdisposition open_existing]
}
try {
if {$opts(all) || $opts(geometry)} {
if {[binary scan [device_ioctl $h 0x70000] "wiiii" geom(-cylinders) geom(-mediatype) geom(-trackspercylinder) geom(-sectorspertrack) geom(-bytespersector)] != 5} {
error "DeviceIoControl 0x70000 on disk '$disk' returned insufficient data."
}
lappend result -geometry [array get geom]
}
if {$opts(all) || $opts(layout)} {
if {[min_os_version 5 1] && ![info exists ::twapi::_use_win2k_disk_ioctls]} {
set data [device_ioctl $h 0x70050]
if {[binary scan $data "i i" partstyle layout(-partitioncount)] != 2} {
error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
}
set layout(-partitionstyle) [_partition_style_sym $partstyle]
switch -exact -- $layout(-partitionstyle) {
mbr {
if {[binary scan $data "@8 i" layout(-signature)] != 1} {
error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
}
}
gpt {
set pi(-diskid) [_binary_to_guid $data 32]
if {[binary scan $data "@8 w w i" layout(-startingusableoffset) layout(-usablelength) layout(-maxpartitioncount)] != 3} {
error "DeviceIoControl 0x70050 on disk '$disk' returned insufficient data."
}
}
raw -
unknown {
}
}
set layout(-partitions) [list ]
for {set i 0} {$i < $layout(-partitioncount)} {incr i} {
lappend layout(-partitions) [_decode_PARTITION_INFORMATION_EX_binary $data [expr {48 + (144*$i)}]]
}
} else {
set data [device_ioctl $h 0x7400c]
if {[binary scan $data "i i" layout(-partitioncount) layout(-signature)] != 2} {
error "DeviceIoControl 0x7400C on disk '$disk' returned insufficient data."
}
set layout(-partitions) [list ]
for {set i 0} {$i < $layout(-partitioncount)} {incr i} {
lappend layout(-partitions) [_decode_PARTITION_INFORMATION_binary $data [expr {8 + (32*$i)}]]
}
}
lappend result -layout [array get layout]
}
} finally {
if {[info exists h]} {
close_handles $h
}
}
return $result
}
proc twapi::create_file {path args} {
array set opts [parseargs args {
{access.arg {generic_read}}
{share.arg {read write delete}}
{inherit.bool 0}
{secd.arg ""}
{createdisposition.arg open_always}
{flags.int 0}
{templatefile.arg NULL}
} -maxleftover 0]
set access_mode [_access_rights_to_mask $opts(access)]
set share_mode [_share_mode_to_mask $opts(share)]
set create_disposition [_create_disposition_to_code $opts(createdisposition)]
return [CreateFile $path \
$access_mode \
$share_mode \
[_make_secattr $opts(secd) $opts(inherit)] \
$create_disposition \
$opts(flags) \
$opts(templatefile)]
}
proc twapi::_drive_rootpath {drive} {
if {[_is_unc $drive]} {
return "[string trimright $drive ]\\"
} else {
return "[string trimright $drive :/\\]:\\"
}
}
proc twapi::_is_unc {path} {
return [expr {[string match {\\\\*} $path] || [string match //* $path]}]
}
proc twapi::_drivemask_to_drivelist {drivebits} {
set drives [list ]
set i 0
foreach drive {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
if {[expr {$drivebits & (1 << $i)}]} {
lappend drives $drive:
}
incr i
}
return $drives
}
proc twapi::_decode_PARTITION_INFORMATION_binary {bin off} {
if {[binary scan $bin "@$off w w i i c c c c" \
pi(-startingoffset) \
pi(-partitionlength) \
pi(-hiddensectors) \
pi(-partitionnumber) \
pi(-partitiontype) \
pi(-bootindicator) \
pi(-recognizedpartition) \
pi(-rewritepartition)] != 8} {
error "Truncated partition structure."
}
set pi(-partitiontype) [format 0x%2.2x [expr {0xff & $pi(-partitiontype)}]]
return [array get pi]
}
proc twapi::_decode_PARTITION_INFORMATION_EX_binary {bin off} {
if {[binary scan $bin "@$off i x4 w w i c" \
pi(-partitionstyle) \
pi(-startingoffset) \
pi(-partitionlength) \
pi(-partitionnumber) \
pi(-rewritepartition)] != 5} {
error "Truncated partition structure."
}
set pi(-partitionstyle) [_partition_style_sym $pi(-partitionstyle)]
switch -exact -- $pi(-partitionstyle) {
mbr {
if {[binary scan $bin "@$off x32 c c c x i" pi(-partitiontype) pi(-bootindicator) pi(-recognizedpartition) pi(-hiddensectors)] != 4} {
error "Truncated partition structure."
}
set pi(-partitiontype) [format 0x%2.2x [expr {0xff & $pi(-partitiontype)}]]
}
gpt {
set pi(-partitiontype) [_binary_to_guid $bin [expr {$off+32}]]
set pi(-partitionif)   [_binary_to_guid $bin [expr {$off+48}]]
if {[binary scan $bin "@$off x64 w" pi(-attributes)] != 1} {
error "Truncated partition structure."
}
set pi(-name) [_ucs16_binary_to_string [string range $bin [expr {$off+72} end]]]
}
raw -
unknown {
}
}
return [array get pi]
}
proc twapi::_partition_style_sym {partstyle} {
set partstyle [lindex {mbr gpt raw} $partstyle]
if {$partstyle ne ""} {
return $partstyle
}
return "unknown"
}
proc twapi::_share_mode_to_mask {modelist} {
variable windefs
return [_parse_symbolic_bitmask $modelist {read 1 write 2 delete 4}]
}
proc twapi::_create_disposition_to_code {sym} {
if {[string is integer -strict $sym]} {
return $sym
}
set code [lsearch -exact {dummy create_new create_always open_existing open_always truncate_existing} $sym]
if {$code == -1} {
error "Invalid create disposition value '$sym'"
}
return $code
}
#-- from eventlog.tcl
namespace eval twapi {
variable eventlog_handles
array set eventlog_handles {}
}
proc twapi::eventlog_open {args} {
variable eventlog_handles
array set opts [parseargs args {
system.arg
source.arg
file.arg
write
} -nulldefault]
if {$opts(source) == ""} {
if {$opts(file) == ""} {
set opts(source) [file rootname [file tail [info nameofexecutable]]]
} else {
if {$opts(write)} {
error "Option -file may not be used with -write"
}
}
} else {
if {$opts(file) != ""} {
error "Option -file may not be used with -source"
}
}
if {$opts(write)} {
set handle [RegisterEventSource $opts(system) $opts(source)]
set mode write
} else {
if {$opts(source) != ""} {
set handle [OpenEventLog $opts(system) $opts(source)]
} else {
set handle [OpenBackupEventLog $opts(system) $opts(file)]
}
set mode read
}
set eventlog_handles($handle) $mode
return $handle
}
proc twapi::eventlog_close {hevl} {
variable eventlog_handles
if {[_eventlog_valid_handle $hevl read]} {
CloseEventLog $hevl
} else {
DeregisterEventSource $hevl
}
unset eventlog_handles($hevl)
}
proc twapi::eventlog_write {hevl id args} {
_eventlog_valid_handle $hevl write raise
array set opts [parseargs args {
{type.arg information {success error warning information auditsuccess auditfailure}}
{category.int 1}
loguser
params.arg
data.arg
} -nulldefault]
switch -exact -- $opts(type) {
success          {set opts(type) 0}
error            {set opts(type) 1}
warning          {set opts(type) 2}
information      {set opts(type) 4}
auditsuccess     {set opts(type) 8}
auditfailure     {set opts(type) 16}
default {error "Invalid value '$opts(type)' for option -type"}
}
if {$opts(loguser)} {
set user [get_current_user -sid]
} else {
set user ""
}
ReportEvent $hevl $opts(type) $opts(category) $id \
$user $opts(params) $opts(data)
}
proc twapi::eventlog_log {message args} {
array set opts [parseargs args {
system.arg
source.arg
{type.arg information}
{category.int 1}
} -nulldefault]
set hevl [eventlog_open -write -source $opts(source) -system $opts(system)]
try {
eventlog_write $hevl 1 -params [list $message] -type $opts(type) -category $opts(category)
} finally {
eventlog_close $hevl
}
return
}
proc twapi::eventlog_read {hevl args} {
_eventlog_valid_handle $hevl read raise
array set opts [parseargs args {
seek.int
{direction.arg forward}
}]
if {[info exists opts(seek)]} {
set flags 2;                    # Seek
set offset $opts(seek)
} else {
set flags 1;                    # Sequential read
set offset 0
}
switch -glob -- $opts(direction) {
""    -
forw* {
setbits flags 4
}
back* {
setbits flags 8
}
default {
error "Invalid value '$opts(direction)' for -direction option"
}
}
set results [list ]
try {
set recs [ReadEventLog $hevl $flags $offset]
} onerror {TWAPI_WIN32 38} {
set recs [list ]
}
foreach rec $recs {
foreach {fld index} {
-source 0 -system 1 -recordnum 3 -timegenerated 4 -timewritten 5
-eventid 6 -type 7 -category 8 -params 11 -sid 12 -data 13
} {
set event($fld) [lindex $rec $index]
}
set event(-type) [string map {0 success 1 error 2 warning 4 information 8 auditsuccess 16 auditfailure} $event(-type)]
lappend results [array get event]
}
return $results
}
proc twapi::eventlog_oldest {hevl} {
_eventlog_valid_handle $hevl read raise
return [GetOldestEventLogRecord $hevl]
}
proc twapi::eventlog_count {hevl} {
_eventlog_valid_handle $hevl read raise
return [GetNumberOfEventLogRecords $hevl]
}
proc twapi::eventlog_is_full {hevl} {
_eventlog_valid_handle $hevl read
return [Twapi_IsEventLogFull $hevl]
}
proc twapi::eventlog_backup {hevl file} {
_eventlog_valid_handle $hevl read raise
BackupEventLog $hevl $file
}
proc twapi::eventlog_clear {hevl args} {
_eventlog_valid_handle $hevl read raise
array set opts [parseargs args {backup.arg} -nulldefault]
ClearEventLog $hevl $opts(backup)
}
proc twapi::eventlog_format_message {event_record args} {
package require registry
array set opts [parseargs args {
width.int
langid.int
} -nulldefault]
array set rec $event_record
set regkey [_find_eventlog_regkey $rec(-source)]
set found 0
if {! [catch {registry get $regkey "EventMessageFile"} path]} {
foreach dll [split $path \;] {
set dll [expand_environment_strings $dll]
if {! [catch {
format_message -module $dll -messageid $rec(-eventid) -params $rec(-params) -width $opts(width) -langid $opts(langid)
} msg]} {
set found 1
break
}
}
}
if {$found} {
} else {
set fmt "The message file or event definition for event id $rec(-eventid) from source $rec(-source) was not found. The following information was part of the event: "
set flds [list ]
for {set i 1} {$i <= [llength $rec(-params)]} {incr i} {
lappend flds %$i
}
append fmt [join $flds ", "]
set msg [format_message -fmtstring $fmt  \
-params $rec(-params) -width $opts(width)]
}
return $msg
}
proc twapi::eventlog_format_category {event_record args} {
package require registry
array set opts [parseargs args {
width.int
langid.int
} -nulldefault]
array set rec $event_record
if {$rec(-category) == 0} {
return ""
}
set regkey [_find_eventlog_regkey $rec(-source)]
set found 0
if {! [catch {registry get $regkey "CategoryMessageFile"} path]} {
foreach dll [split $path \;] {
set dll [expand_environment_strings $dll]
if {! [catch {
format_message -module $dll -messageid $rec(-category) -params $rec(-params) -width $opts(width) -langid $opts(langid)
} msg]} {
return $msg
}
}
}
return "Category $rec(-category)"
}
proc twapi::_eventlog_valid_handle {hevl mode {raise_error ""}} {
variable eventlog_handles
if {![info exists eventlog_handles($hevl)]} {
error "Invalid event log handle '$hevl'"
}
if {[string compare $eventlog_handles($hevl) $mode]} {
if {$raise_error != ""} {
error "Eventlog handle '$hevl' not valid for $mode"
}
return 0
} else {
return 1
}
}
proc twapi::_find_eventlog_regkey {source} {
set topkey {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog}
foreach key [registry keys $topkey] {
foreach srckey [registry keys "${topkey}\\$key"] {
if {[string equal -nocase $srckey $source]} {
return "${topkey}\\${key}\\$srckey"
}
}
}
return "${topkey}\\Application"
}
#-- from msi.tcl
namespace eval twapi {
variable msiprotos_installer
variable msiprotos_database
variable msiprotos_record
}
proc twapi::init_msi {} {
foreach {name proto} {
AddSource            {43 {} 0 1 void {bstr bstr bstr}}
ApplyPatch           TBD
ApplyMultiplePatches TBD
ClearSourceList      {44 {} 0 1 void      {bstr bstr}}
CollectUserInfo      {21 {} 0 1 void      {bstr}}
ComponentClients     {38 {} 0 1 idispatch {bstr}}
ComponentPath        {31 {} 0 1 bstr      {bstr bstr}}
ComponentQualifiers  {34 {} 0 1 idispatch {bstr}}
Components           {37 {} 0 1 idispatch {bstr}}
ConfigureFeature     {28 {} 0 1 void      {bstr bstr bstr}}
ConfigureProduct     {19 {} 0 1 void      {bstr bstr bstr}}
CreateRecord         {1  {} 0 1 idispatch {i4}}
EnableLog            {7  {} 0 1 void      {bstr bstr}}
Environment          {12 {} 0 2 bstr      {bstr}}
Environment          {12 {} 0 4 void      {bstr bstr}}
ExtractPatchXMLData  {57 {} 0 1 void      {bstr}}
FeatureParent        {23 {} 0 2 bstr      {bstr bstr}}
Features             {36 {} 0 2 idispatch {bstr}}
FeatureState         {24 {} 0 2 i4        {bstr bstr}}
FeatureUsageCount    {26 {} 0 2 i4        {bstr bstr}}
FeatureUsageDate     {27 {} 0 2 date      {bstr bstr}}
FileAttributes       {13 {} 0 2 i4        {bstr}}
FileHash             TBD
FileSignatureInfo    TBD
FileSize             {15 {} 0 1 i4       {bstr}}
FileVersion          {16 {} 0 1 bstr     {bstr {bool {in 0}}}}
ForceSourceListResolution TBD
InstallProduct       {8  {} 0 1 void      {bstr bstr}}
LastErrorRecord      {10 {} 0 1 idispatch {}}
OpenPackage          {2  {} 0 1 idispatch {bstr i4}}
OpenDatabase         {4  {} 0 1 idispatch {bstr i4}}
OpenProduct          {3  {} 0 1 idispatch {bstr}}
Patches              {39 {} 0 2 idispatch {bstr}}
PatchesEx            {55 {} 0 2 idispatch {bstr bstr i4 i4}}
PatchInfo            TBD
PatchTransforms      TBD
ProductInfo          {18 {} 0 2 bstr      {bstr bstr}}
ProductsEx           {52 {} 0 2 idispatch {bstr bstr i4}}
Products             {35 {} 0 2 idispatch {}}
ProductState         {17 {} 0 2 bstr      {bstr}}
ProvideComponent     {30 {} 0 1 bstr      {bstr bstr bstr i4}}
ProvideQualifiedComponent     TBD
QualifierDescription TBD
RegistryValue        {11 {} 0 1 bstr      {bstr bstr bstr}}
ReinstallFeature     {29 {} 0 1 void      {bstr bstr bstr}}
ReinstallProduct     {20 {} 0 1 void      {bstr bstr}}
RelatedProducts      {40 {} 0 2 idispatch {bstr}}
RemovePatches        {49 {} 0 1 void      {bstr bstr i4 bstr}}
ShortcutTarget       {46 {} 0 2 idispatch {bstr}}
SummaryInformation   {5  {} 0 2 idispatch {bstr i4}}
UILevel              {6  {} 0 2 bstr      {}}
UILevel              {6  {} 0 4 void      {bstr}}
UseFeature           {25 {} 0 1 void      {bstr bstr bstr}}
Version              {9  {} 0 2 bstr      {}}
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_installer($name) $proto
}
}
foreach {name proto} {
ApplyTransform       {10 {} 0 1 void      {bstr i4}}
Commit               {4  {} 0 1 void      {}}
CreateTransformSummaryInfo TBD-13
DatabaseState        {1  {} 0 2 i4        {}}
EnableUIPreview      {11 {} 0 1 void      {}}
Export               {7  {} 0 1 void      {bstr bstr bstr}}
GenerateTransform    TBD-9
Import               {6  {} 0 1 void      {bstr bstr}}
Merge                TBD-8
OpenView             {3  {} 0 1 idispatch  {bstr}}
PrimaryKeys          {5  {} 0 2 idispatch {bstr}}
SummaryInformation   {2  {} 0 2 idispatch {i4}}
TablePersistent      {12 {} 0 2 i4       {bstr}}
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_database($name) $proto
}
}
foreach {name proto} {
ClearData    {7  {} 0 1 void      {}}
DataSize     {5  {} 0 2 i4        {}}
FieldCount   {0  {} 0 2 i4        {}}
FormatText   {8  {} 0 1 void      {}}
IntegerData  {2  {} 0 2 i4        {i4}}
IntegerData  {2  {} 0 4 void      {i4 i4}}
IsNull       {6  {} 0 2 bool      {i4}}
ReadStream   {4  {} 0 1 bstr      {i4 i4 i4}}
SetStream    {3  {} 0 1 void      {i4 bstr}}
StringData   {1  {} 0 2 bstr      {i4}}
StringData   {1  {} 0 4 void      {i4 bstr}}
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_record($name) $proto
}
}
foreach {name proto} {
Persist    {3  {} 0 1 void      {}}   
Property   {1  {} 0 2 bstr      {i4}}
Property   {1  {} 0 4 bstr      {i4}}
PropertyCount {2  {} 0 2 i4     {}}
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_summaryinfo($name) $proto
}
}
foreach {name proto} {
Count  {1 {} 0 2 i4   {}}
Item   {0 {} 0 2 bstr {i4}} 
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_stringlist($name) $proto
}
}
foreach {name proto} {
Close      {4  {} 0 1 void      {}}
ColumnInfo {5  {} 0 2 idispatch {i4}}
Execute    {1  {} 0 1 void      {{9 {0x11}}}}
Fetch      {2  {} 0 1 idispatch {}}
GetError   {6  {} 0 1 void      {}}
Modify     {3  {} 0 1 void      {i4 idispatch}}
} {
if {[llength $proto] > 1} {
set ::twapi::msiprotos_view($name) $proto
}
}
}
proc twapi::new_msi {} {
return [comobj WindowsInstaller.Installer]
}
proc twapi::delete_msi {obj} {
$obj -destroy
}
proc twapi::load_msi_prototypes {obj type} {
init_msi
proc ::twapi::load_msi_prototypes {obj type} {
variable msiprotos_[string tolower $type]
$obj -precache [array get msiprotos_[string tolower $type]]
}
return [load_msi_prototypes $obj $type]
}
#-- from mstask.tcl
namespace eval twapi {
variable CLSID_ITaskScheduler {{148BD52A-A2AB-11CE-B11F-00AA00530503}}
variable CLSID_ITask          {{148BD520-A2AB-11CE-B11F-00AA00530503}}
}
proc twapi::itaskscheduler_new {args} {
array set opts [parseargs args {
system.arg
} -maxleftover 0]
set its [Twapi_CoCreateInstance $twapi::CLSID_ITaskScheduler NULL 1 [name_to_iid ITaskScheduler] ITaskScheduler]
if {![info exists opts(system)]} {
return $its
}
try {
itaskscheduler_set_target_system $its $opts(system)
} onerror {} {
iunknown_release $its
error $errorResult $errorInfo $errorCode
}
return $its
}
interp alias {} ::twapi::itaskscheduler_release {} ::twapi::iunknown_release
proc twapi::itaskscheduler_new_itask {its taskname} {
set iid_itask [name_to_iid ITask]
set iunk [ITaskScheduler_NewWorkItem $its $taskname $twapi::CLSID_ITask $iid_itask]
try {
set itask [IUnknown_QueryInterface $iunk $iid_itask ITask]
} finally {
iunknown_release $iunk
}
return $itask
}
proc twapi::itaskscheduler_get_itask {its taskname} {
set iid_itask [name_to_iid ITask]
set iunk [ITaskScheduler_Activate $its $taskname $iid_itask]
try {
set itask [IUnknown_QueryInterface $iunk $iid_itask ITask]
} finally {
iunknown_release $iunk
}
return $itask
}
interp alias {} ::twapi::itaskscheduler_delete_task {} ::twapi::ITaskScheduler_Delete
proc twapi::itaskscheduler_task_exists {its taskname} {
return [expr {[ITaskScheduler_IsOfType $its $taskname [name_to_iid ITask]] == 0 ? true : false}]
}
interp alias {} ::twapi::itaskscheduler_set_target_system {} ::twapi::ITaskScheduler_SetTargetComputer
interp alias {} ::twapi::itaskscheduler_get_target_system {} ::twapi::ITaskScheduler_GetTargetComputer
proc twapi::itaskscheduler_get_tasks {its} {
set ienum [ITaskScheduler_Enum $its]
try {
set result [list ]
set more 1
while {$more} {
foreach {more items} [IEnumWorkItems_Next $ienum 20] break
set result [concat $result $items]
}
} finally {
iunknown_release $ienum
}
return $result
}
proc twapi::itask_configure {itask args} {
array set opts [parseargs args {
application.arg
maxruntime.int
params.arg
priority.arg
workingdir.arg
account.arg
password.arg
comment.arg
creator.arg
data.arg
idlewait.int
idlewaitdeadline.int
interactive.bool
deletewhendone.bool
disabled.bool
hidden.bool
runonlyifloggedon.bool
startonlyifidle.bool
resumesystem.bool
killonidleend.bool
restartonidleresume.bool
donstartonbatteries.bool
killifonbatteries.bool
} -maxleftover 0]
if {[info exists opts(priority)]} {
switch -exact -- $opts(priority) {
normal      {set opts(priority) 0x00000020}
abovenormal {set opts(priority) 0x00008000}
belownormal {set opts(priority) 0x00004000}
high        {set opts(priority) 0x00000080}
realtime    {set opts(priority) 0x00000100}
idle        {set opts(priority) 0x00000040}
default     {error "Unknown priority '$opts(priority)'. Must be one of 'normal', 'high', 'idle' or 'realtime'"}
}
}
foreach {opt fn} {
application ITask_SetApplicationName
maxruntime  ITask_SetMaxRunTime
params      ITask_SetParameters
workingdir  ITask_SetWorkingDirectory
priority    ITask_SetPriority
comment            IScheduledWorkItem_SetComment
creator            IScheduledWorkItem_SetCreator
data               IScheduledWorkItem_SetWorkItemData
errorretrycount    IScheduledWorkItem_SetErrorRetryCount
errorretryinterval IScheduledWorkItem_SetErrorRetryInterval
} {
if {[info exists opts($opt)]} {
$fn  $itask $opts($opt)
}
}
if {[info exists opts(account)]} {
if {$opts(account) ne ""} {
if {![info exists opts(password)]} {
error "Option -password must be specified if -account is specified"
}
} else {
set opts(password) $::twapi::nullptr
}
IScheduledWorkItem_SetAccountInformation $itask $opts(account) $opts(password)
}
if {[info exists opts(idlewait)] || [info exists opts(idlewaitdeadline)]} {
if {! ([info exists opts(idlewait)] &&
[info exists opts(idlewaitdeadline)]) } {
foreach {idle dead} [IScheduledWorkItem_GetIdleWait $itask] break
if {![info exists opts(idlewait)]} {
set opts(idlewait) $idle
}
if {![info exists opts(idlewaitdeadline)]} {
set opts(idlewaitdeadline) $dead
}
}
IScheduledWorkItem_SetIdleWait $itask $opts(idlewait) $opts(idlewaitdeadline)
}
if {[info exists opts(interactive)] ||
[info exists opts(deletewhendone)] ||
[info exists opts(disabled)] ||
[info exists opts(hidden)] ||
[info exists opts(runonlyifloggedon)] ||
[info exists opts(startonlyifidle)] ||
[info exists opts(resumesystem)] ||
[info exists opts(killonidleend)] ||
[info exists opts(restartonidleresume)] ||
[info exists opts(donstartonbatteries)] ||
[info exists opts(killifonbatteries)]} {
set flags [IScheduledWorkItem_GetFlags $itask]
foreach {opt val} {
interactive         0x1
deletewhendone      0x2
disabled            0x4
startonlyifidle     0x10
hidden              0x200
runonlyifloggedon   0x2000
resumesystem        0x1000
killonidleend       0x20
restartonidleresume 0x800
donstartonbatteries 0x40
killifonbatteries   0x80
} {
if {[info exists opts($opt)]} {
if {$opts($opt)} {
setbits flags $val
} else {
resetbits flags $val
}
}
}
IScheduledWorkItem_SetFlags $itask $flags
}
return
}
proc twapi::itask_get_info {itask args} {
array set opts [parseargs args {
all
application
maxruntime
params
priority
workingdir
account
comment
creator
data
idlewait
idlewaitdeadline
interactive
deletewhendone
disabled
hidden
runonlyifloggedon
startonlyifidle
resumesystem
killonidleend
restartonidleresume
donstartonbatteries
killifonbatteries
lastruntime
nextruntime
status
} -maxleftover 0]
set result [list ]
if {$opts(all) || $opts(priority)} {
switch -exact -- [twapi::ITask_GetPriority $itask] {
32    { set priority normal }
64    { set priority idle }
128   { set priority high }
256   { set priority realtime }
16384 { set priority belownormal }
32768 { set priority abovenormal }
default { set priority unknown }
}
lappend result -priority $priority
}
foreach {opt fn} {
application ITask_GetApplicationName
maxruntime  ITask_GetMaxRunTime
params      ITask_GetParameters
workingdir  ITask_GetWorkingDirectory
account            IScheduledWorkItem_GetAccountInformation
comment            IScheduledWorkItem_GetComment
creator            IScheduledWorkItem_GetCreator
data               IScheduledWorkItem_GetWorkItemData
} {
if {$opts(all) || $opts($opt)} {
try {
lappend result -$opt [$fn  $itask]
} onerror {TWAPI_WIN32 -2147216625} {
lappend result -$opt {}
}
}
}
if {$opts(all) || $opts(lastruntime)} {
try {
lappend result -lastruntime [_timelist_to_timestring [IScheduledWorkItem_GetMostRecentRunTime $itask]]
} onerror {TWAPI_WIN32 267011} {
lappend result -lastruntime {}
}
}
if {$opts(all) || $opts(nextruntime)} {
try {
lappend result -nextruntime [_timelist_to_timestring [IScheduledWorkItem_GetNextRunTime $itask]]
} onerror {TWAPI_WIN32 267010} {
lappend result -nextruntime disabled
} onerror {TWAPI_WIN32 267015} {
lappend result -nextruntime notriggers
} onerror {TWAPI_WIN32 267016} {
lappend result -nextruntime oneventonly
}
}
if {$opts(all) || $opts(status)} {
set status [IScheduledWorkItem_GetStatus $itask]
if {$status == 0x41300} {
set status ready
} elseif {$status == 0x41301} {
set status running
} elseif {$status == 0x41302} {
set status disabled
} elseif {$status == 0x41305} {
set status partiallydefined
} else {
set status unknown
}
lappend result -status $status
}
if {$opts(idlewait) || $opts(idlewaitdeadline)} {
foreach {idle dead} [IScheduledWorkItem_GetIdleWait $itask] break
if {$opts(idlewait)} {
lappend result -idlewait $idle
}
if {$opts(idlewaitdeadline)} {
lappend result -idlewaitdeadline $dead
}
}
if {$opts(interactive) ||
$opts(deletewhendone) ||
$opts(disabled) ||
$opts(hidden) ||
$opts(runonlyifloggedon) ||
$opts(startonlyifidle) ||
$opts(resumesystem) ||
$opts(killonidleend) ||
$opts(restartonidleresume) ||
$opts(donstartonbatteries) ||
$opts(killifonbatteries)} {
set flags [IScheduledWorkItem_GetFlags $itask]
foreach {opt val} {
interactive         0x1
deletewhendone      0x2
disabled            0x4
startonlyifidle     0x10
hidden              0x200
runonlyifloggedon   0x2000
resumesystem        0x1000
killonidleend       0x20
restartonidleresume 0x800
donstartonbatteries 0x40
killifonbatteries   0x80
} {
if {$opts($opt)} {
lappend result $opt [expr {($flags & $val) ? true : false}]
}
}
}
return $result
}
proc twapi::itask_get_runtimes_within_interval {itask args} {
array set opts [parseargs args {
start.arg
end.arg
{count.int 1}
statusvar.arg
} -maxleftover 0]
if {[info exists opts(start)]} {
set start [_timestring_to_timelist $opts(start)]
} else {
set start [_seconds_to_timelist [clock seconds]]
}
if {[info exists opts(end)]} {
set end [_timestring_to_timelist $opts(end)]
} else {
set end {2038 1 1 0 0 0 0}
}
set result [list ]
if {[info exists opts(statusvar)]} {
upvar $opts(statusvar) status
}
foreach {status timelist} [IScheduledWorkItem_GetRunTimes $itask $start $end $opts(count)] break
foreach time $timelist {
lappend result [_timelist_to_timestring $time]
}
return $result
}
interp alias {} ::twapi::itask_run {} ::twapi::IScheduledWorkItem_Run
interp alias {} ::twapi::itask_end {} ::twapi::IScheduledWorkItem_Terminate
proc twapi::itask_save {itask} {
set ipersist [iunknown_query_interface $itask IPersistFile]
try {
IPersistFile_Save $ipersist "" 1
} finally {
iunknown_release $ipersist
}
return
}
proc twapi::itask_edit_dialog {itask args} {
array set opts [parseargs args {
{hwin.arg 0}
} -maxleftover 0]
return [twapi::IScheduledWorkItem_EditWorkItem $itask $opts(hwin)]
}
interp alias {} ::twapi::itask_new_itasktrigger {} ::twapi::IScheduledWorkItem_CreateTrigger
interp alias {} ::twapi::itask_delete_itasktrigger {} ::twapi::IScheduledWorkItem_DeleteTrigger
interp alias {} ::twapi::itask_release {} ::twapi::iunknown_release
proc twapi::itask_get_itasktrigger {itask index} {
return [IScheduledWorkItem_GetTrigger $itask $index]
}
proc twapi::itask_get_itasktrigger_count {itask} {
return [IScheduledWorkItem_GetTriggerCount $itask]
}
interp alias {} ::twapi::itask_get_itasktrigger_string {} ::twapi::IScheduledWorkItem_GetTriggerString
proc twapi::itasktrigger_get_info {itt} {
array set data [ITaskTrigger_GetTrigger $itt]
set result(-begindate) "$data(wBeginYear)-$data(wBeginMonth)-$data(wBeginDay)"
set result(-starttime) "$data(wStartHour):$data(wStartMinute)"
if {$data(rgFlags) & 1} {
set result(-enddate) "$data(wEndYear)-$data(wEndMonth)-$data(wEndDay)"
} else {
set result(-enddate) ""
}
set result(-duration) $data(MinutesDuration)
set result(-interval) $data(MinutesInterval)
if {$data(rgFlags) & 2} {
set result(-killatdurationend) true
} else {
set result(-killatdurationend) false
}
if {$data(rgFlags) & 4} {
set result(-disabled) true
} else {
set result(-disabled) false
}
switch -exact -- [lindex $data(type) 0] {
0 {
set result(-type) once
}
1 {
set result(-type) daily
set result(-period) [lindex $data(type) 1]
}
2 {
set result(-type) weekly
set result(-period) [lindex $data(type) 1]
set result(-weekdays) [format 0x%x [lindex $data(type) 2]]
}
3 {
set result(-type) monthlydate
set result(-daysofmonth) [format 0x%x [lindex $data(type) 1]]
set result(-months) [format 0x%x [lindex $data(type) 2]]
}
4 {
set result(-type) monthlydow
set result(-weekofmonth) [lindex {first second third fourth last} [lindex $data(type) 2]]
set result(-weekdays) [format 0x%x [lindex $data(type) 2]]
set result(-months) [format 0x%x [lindex $data(type) 3]]
}
5 {
set result(-type) onidle
}
6 {
set result(-type) atsystemstart
}
7 {
set result(-type) atlogon
}
}
return [array get result]
}
proc twapi::itasktrigger_configure {itt args} {
array set opts [parseargs args {
begindate.arg
enddate.arg
starttime.arg
interval.int
duration.int
killatdurationend.bool
disabled.bool
type.arg
weekofmonth.int
{period.int 1}
{weekdays.int 0x7f}
{daysofmonth.int 0x7fffffff}
{months.int 0xfff}
} -maxleftover 0]
array set data [ITaskTrigger_GetTrigger $itt]
if {[info exists opts(begindate)]} {
foreach {year month day} [split $opts(begindate) -] break
set data(wBeginYear) [scan $year %d]
set data(wBeginMonth) [scan $month %d]
set data(wBeginDay) [scan $day %d]
}
if {[info exists opts(starttime)]} {
foreach {hour minute} [split $opts(starttime) :] break
set data(wStartHour) [scan $hour %d]
set data(wStartMinute) [scan $minute %d]
}
if {[info exists opts(enddate)]} {
if {$opts(enddate) ne ""} {
setbits data(rgFlags) 1;        # Indicate end date is present
foreach {year month day} [split $opts(enddate) -] break
set data(wEndYear) [scan $year %d]
set data(wEndMonth) [scan $month %d]
set data(wEndDay) [scan $day %d]
} else {
resetbits data(rgFlags) 1;  # Indicate no end date
}
}
if {[info exists opts(duration)]} {
set data(MinutesDuration) $opts(duration)
}
if {[info exists opts(interval)]} {
set data(MinutesInterval) $opts(interval)
}
if {[info exists opts(killatdurationend)]} {
if {$opts(killatdurationend)} {
setbits data(rgFlags) 2
} else {
resetbits data(rgFlags) 2
}
}
if {[info exists opts(disabled)]} {
if {$opts(disabled)} {
setbits data(rgFlags) 4
} else {
resetbits data(rgFlags) 4
}
}
if {[info exists opts(type)]} {
switch -exact -- $opts(type) {
once {
set data(type) [list 0]
}
daily {
set data(type) [list 1 $opts(period)]
}
weekly {
set data(type) [list 2 $opts(period) $opts(weekdays)]
}
monthlydate {
set data(type) [list 3 $opts(daysofmonth) $opts(months)]
}
monthlydow {
set data(type) [list 4 $opts(weekofmonth) $opts(weekdays) $opts(months)]
}
onidle {
set data(type) [list 5]
}
atsystemstart {
set data(type) [list 6]
}
atlogon {
set data(type) [list 7]
}
}
}
ITaskTrigger_SetTrigger $itt [array get data]
return
}
interp alias {} ::twapi::itasktrigger_release {} ::twapi::iunknown_release
proc twapi::mstask_create {taskname args} {
array set opts [parseargs args {
system.arg
application.arg
maxruntime.int
params.arg
priority.arg
workingdir.arg
account.arg
password.arg
comment.arg
creator.arg
data.arg
idlewait.int
idlewaitdeadline.int
interactive.bool
deletewhendone.bool
disabled.bool
hidden.bool
runonlyifloggedon.bool
startonlyifidle.bool
resumesystem.bool
killonidleend.bool
restartonidleresume.bool
donstartonbatteries.bool
killifonbatteries.bool
begindate.arg
enddate.arg
starttime.arg
interval.int
duration.int
killatdurationend.bool
type.arg
period.int
weekdays.int
daysofmonth.int
months.int
} -maxleftover 0]
set its [itaskscheduler_new]
try {
if {[info exists opts(system)]} {
itaskscheduler_set_target_system $opts(system)
}
set itask [itaskscheduler_new_itask $its $taskname]
set cmd [list itask_configure $itask]
foreach opt {
application
maxruntime
params
priority
workingdir
account
password
comment
creator
data
idlewait
idlewaitdeadline
interactive
deletewhendone
disabled
hidden
runonlyifloggedon
startonlyifidle
resumesystem
killonidleend
restartonidleresume
donstartonbatteries
killifonbatteries
} {
if {[info exists opts($opt)]} {
lappend cmd -$opt $opts($opt)
}
}
eval $cmd
set itt [lindex [itask_new_itasktrigger $itask] 1]
set cmd [list itasktrigger_configure $itt -disabled false]
foreach opt {
begindate
enddate
interval
starttime
duration
killatdurationend
type
period
weekdays
daysofmonth
months
} {
if {[info exists opts($opt)]} {
lappend cmd -$opt $opts($opt)
}
}
eval $cmd
itask_save $itask
} finally {
iunknown_release $its
if {[info exists itask]} {
iunknown_release $itask
}
if {[info exists itt]} {
iunknown_release $itt
}
}
return
}
proc twapi::mstask_delete {taskname args} {
array set opts [parseargs args {
system.arg
} -maxleftover 0]
set its [itaskscheduler_new]
try {
if {[info exists opts(system)]} {
itaskscheduler_set_target_system $opts(system)
}
itaskscheduler_delete_task $its $taskname
} finally {
iunknown_release $its
}
return
}
#-- from network.tcl
namespace eval twapi {
array set IfTypeTokens {
1  other
6  ethernet
9  tokenring
15 fddi
23 ppp
24 loopback
28 slip
}
array set IfOperStatusTokens {
0 nonoperational
1 wanunreachable
2 disconnected
3 wanconnecting
4 wanconnected
5 operational
}
array set GetIfEntry_opts {
type                2
mtu                 3
speed               4
physicaladdress     5
adminstatus         6
operstatus          7
laststatuschange    8
inbytes             9
inunicastpkts      10
innonunicastpkts   11
indiscards         12
inerrors           13
inunknownprotocols 14
outbytes           15
outunicastpkts     16
outnonunicastpkts  17
outdiscards        18
outerrors          19
outqlen            20
description        21
}
array set GetIpAddrTable_opts {
ipaddresses -1
ifindex     -1
reassemblysize -1
}
array set GetAdaptersInfo_opts {
adaptername     0
adapterdescription     1
adapterindex    3
dhcpenabled     5
defaultgateway  7
dhcpserver      8
havewins        9
primarywins    10
secondarywins  11
dhcpleasestart 12
dhcpleaseend   13
}
array set GetPerAdapterInfo_opts {
autoconfigenabled 0
autoconfigactive  1
dnsservers        2
}
array set GetInterfaceInfo_opts {
ifname  -1
}
}
proc twapi::get_ip_addresses {} {
set addrs [list ]
foreach entry [GetIpAddrTable] {
set addr [lindex $entry 0]
if {[string compare $addr "0.0.0.0"]} {
lappend addrs $addr
}
}
return $addrs
}
proc twapi::get_netif_indices {} {
set indices [list ]
foreach entry [GetIpAddrTable] {
lappend indices [lindex $entry 1]
}
return $indices
}
proc twapi::get_network_info {args} {
array set getnetworkparams_opts {
hostname     0
domain       1
dnsservers   2
dhcpscopeid  4
routingenabled  5
arpproxyenabled 6
dnsenabled      7
}
array set opts [parseargs args \
[concat [list all ipaddresses interfaces] \
[array names getnetworkparams_opts]]]
set result [list ]
foreach opt [array names getnetworkparams_opts] {
if {!$opts(all) && !$opts($opt)} continue
if {![info exists netparams]} {
set netparams [GetNetworkParams]
}
lappend result -$opt [lindex $netparams $getnetworkparams_opts($opt)]
}
if {$opts(all) || $opts(ipaddresses) || $opts(interfaces)} {
set addrs     [list ]
set interfaces [list ]
foreach entry [GetIpAddrTable] {
set addr [lindex $entry 0]
if {[string compare $addr "0.0.0.0"]} {
lappend addrs $addr
}
lappend interfaces [lindex $entry 1]
}
if {$opts(all) || $opts(ipaddresses)} {
lappend result -ipaddresses $addrs
}
if {$opts(all) || $opts(interfaces)} {
lappend result -interfaces $interfaces
}
}
return $result
}
proc twapi::get_netif_info {interface args} {
variable IfTypeTokens
variable GetIfEntry_opts
variable GetIpAddrTable_opts
variable GetAdaptersInfo_opts
variable GetPerAdapterInfo_opts
variable GetInterfaceInfo_opts
array set opts [parseargs args \
[concat [list all unknownvalue.arg] \
[array names GetIfEntry_opts] \
[array names GetIpAddrTable_opts] \
[array names GetAdaptersInfo_opts] \
[array names GetPerAdapterInfo_opts] \
[array names GetInterfaceInfo_opts]]]
array set result [list ]
if {![min_os_version 4 0 4]} {
if {[string length $opts(unknownvalue)]} {
foreach opt [array names opts] {
if {$opt == "all" || $opt == "unknownvalue"} continue
if {$opts($opt) || $opts(all)} {
set result(-$opt) $opts(unknownvalue)
}
}
return [array get result]
}
}
set nif $interface
if {![string is integer $nif]} {
if {![min_os_version 5]} {
error "Interfaces must be identified by integer index values on Windows NT 4.0"
}
set nif [GetAdapterIndex $nif]
}
if {$opts(all) || $opts(ifindex)} {
set result(-ifindex) $nif
}
if {$opts(all) ||
[_array_non_zero_entry opts [array names GetIfEntry_opts]]} {
set values [GetIfEntry $nif]
foreach opt [array names GetIfEntry_opts] {
if {$opts(all) || $opts($opt)} {
set result(-$opt) [lindex $values $GetIfEntry_opts($opt)]
}
}
}
if {$opts(all) ||
[_array_non_zero_entry opts [array names GetIpAddrTable_opts]]} {
foreach entry [GetIpAddrTable] {
foreach {addr ifindex netmask broadcast reasmsize} $entry break
lappend ipaddresses($ifindex) [list $addr $netmask $broadcast]
set reassemblysize($ifindex) $reasmsize
}
foreach opt {ipaddresses reassemblysize} {
if {$opts(all) || $opts($opt)} {
if {![info exists ${opt}($nif)]} {
error "No interface exists with index $nif"
}
set result(-$opt) [set ${opt}($nif)]
}
}
}
if {![min_os_version 5]} {
if {[string length $opts(unknownvalue)]} {
set win2kopts [concat [array names GetAdaptersInfo_opts] \
[array names GetPerAdapterInfo_opts] \
[array names GetInterfaceInfo_opts]]
foreach opt $win2kopts {
if {$opts($opt) || $opts(all)} {
set result(-$opt) $opts(unknownvalue)
}
}
return [array get result]
}
}
if {$opts(all) ||
[_array_non_zero_entry opts [array names GetAdaptersInfo_opts]]} {
foreach entry [GetAdaptersInfo] {
if {$nif != [lindex $entry 3]} continue; # Different interface
foreach opt [array names GetAdaptersInfo_opts] {
if {$opts(all) || $opts($opt)} {
set result(-$opt) [lindex $entry $GetAdaptersInfo_opts($opt)]
}
}
}
}
if {$opts(all) ||
[_array_non_zero_entry opts [array names GetPerAdapterInfo_opts]]} {
if {$result(-type) == 24} {
set values {0 0 {}}
} else {
set values [GetPerAdapterInfo $nif]
}
foreach opt [array names GetPerAdapterInfo_opts] {
if {$opts(all) || $opts($opt)} {
set result(-$opt) [lindex $values $GetPerAdapterInfo_opts($opt)]
}
}
}
if {$opts(all) || $opts(ifname)} {
array set ifnames [eval concat [GetInterfaceInfo]]
if {$result(-type) == 24} {
set result(-ifname) "loopback"
} else {
if {![info exists ifnames($nif)]} {
error "No interface exists with index $nif"
}
set result(-ifname) $ifnames($nif)
}
}
if {[info exists result(-type)]} {
if {[info exists IfTypeTokens($result(-type))]} {
set result(-type) $IfTypeTokens($result(-type))
} else {
set result(-type) "other"
}
}
if {[info exists result(-physicaladdress)]} {
set result(-physicaladdress) [_hwaddr_binary_to_string $result(-physicaladdress)]
}
foreach opt {-primarywins -secondarywins} {
if {[info exists result($opt)]} {
if {[string equal $result($opt) "0.0.0.0"]} {
set result($opt) ""
}
}
}
if {[info exists result(-operstatus)] &&
[info exists twapi::IfOperStatusTokens($result(-operstatus))]} {
set result(-operstatus) $twapi::IfOperStatusTokens($result(-operstatus))
}
return [array get result]
}
proc twapi::get_netif_count {} {
return [GetNumberOfInterfaces]
}
proc twapi::get_arp_table {args} {
array set opts [parseargs args {
sort
ifindex.int
validonly
}]
set arps [list ]
foreach arp [GetIpNetTable $opts(sort)] {
foreach {ifindex hwaddr ipaddr type} $arp break
if {$opts(validonly) && $type == 2} continue
if {[info exists opts(ifindex)] && $opts(ifindex) != $ifindex} continue
set type [lindex {other other invalid dynamic static} $type]
if {$type == ""} {
set type other
}
lappend arps [list $ifindex [_hwaddr_binary_to_string $hwaddr] $ipaddr $type]
}
return $arps
}
proc twapi::ipaddr_to_hwaddr {ipaddr {varname ""}} {
foreach arp [GetIpNetTable] {
if {[lindex $arp 3] == 2} continue;       # Invalid entry type
if {[string equal $ipaddr [lindex $arp 2]]} {
set result [_hwaddr_binary_to_string [lindex $arp 1]]
break
}
}
if {![info exists result]} {
foreach ifindex [get_netif_indices] {
catch {
array set netifinfo [get_netif_info $ifindex -ipaddresses -physicaladdress]
foreach elem $netifinfo(-ipaddresses) {
if {[lindex $elem 0] eq $ipaddr} {
set result $netifinfo(-physicaladdress)
break
}
}
}
if {[info exists result]} {
break
}
}
}
if {[info exists result]} {
if {$varname == ""} {
return $result
}
upvar $varname var
set var $result
return 1
} else {
if {$varname == ""} {
error "Could not map IP address $ipaddr to a hardware address"
}
return 0
}
}
proc twapi::hwaddr_to_ipaddr {hwaddr {varname ""}} {
set hwaddr [string map {- "" : ""} $hwaddr]
foreach arp [GetIpNetTable] {
if {[lindex $arp 3] == 2} continue;       # Invalid entry type
if {[string equal $hwaddr [_hwaddr_binary_to_string [lindex $arp 1] ""]]} {
set result [lindex $arp 2]
break
}
}
if {![info exists result]} {
foreach ifindex [get_netif_indices] {
catch {
array set netifinfo [get_netif_info $ifindex -ipaddresses -physicaladdress]
set ifhwaddr [string map {- ""} $netifinfo(-physicaladdress)]
if {[string equal -nocase $hwaddr $ifhwaddr]} {
set result [lindex [lindex $netifinfo(-ipaddresses) 0] 0]
break
}
}
if {[info exists result]} {
break
}
}
}
if {[info exists result]} {
if {$varname == ""} {
return $result
}
upvar $varname var
set var $result
return 1
} else {
if {$varname == ""} {
error "Could not map hardware address $hwaddr to an IP address"
}
return 0
}
}
proc twapi::flush_arp_table {if_index} {
FlushIpNetTable $if_index
}
proc twapi::get_tcp_connections {args} {
variable tcp_statenames
variable tcp_statevalues
if {![info exists tcp_statevalues]} {
array set tcp_statevalues {
closed            1
listen            2
syn_sent          3
syn_rcvd          4
estab             5
fin_wait1         6
fin_wait2         7
close_wait        8
closing           9
last_ack         10
time_wait        11
delete_tcb       12
}
foreach {name val} [array get tcp_statevalues] {
set tcp_statenames($val) $name
}
}
array set opts [parseargs args {
state
localaddr
remoteaddr
localport
remoteport
pid
modulename
modulepath
bindtime
all
matchstate.arg
matchlocaladdr.arg
matchremoteaddr.arg
matchlocalport.int
matchremoteport.int
matchpid.int
} -maxleftover 0]
if {! ($opts(state) || $opts(localaddr) || $opts(remoteaddr) || $opts(localport) || $opts(remoteport) || $opts(pid) || $opts(modulename) || $opts(modulepath) || $opts(bindtime))} {
set opts(all) 1
}
if {[info exists opts(matchstate)]} {
set matchstates [list ]
foreach stateval $opts(matchstate) {
if {[info exists tcp_statevalues($stateval)]} {
lappend matchstates $stateval
continue
}
if {[info exists tcp_statenames($stateval)]} {
lappend matchstates $tcp_statenames($stateval)
continue
}
error "Unrecognized connection state '$stateval' specified for option -matchstate"
}
}
foreach opt {matchlocaladdr matchremoteaddr} {
if {[info exists opts($opt)]} {
set $opt [_hosts_to_ip_addrs $opts($opt)]
if {[llength [set $opt]] == 0} {
return [list ]; # No addresses, so no connections will match
}
}
}
if {$opts(modulename) || $opts(modulepath) || $opts(bindtime) || $opts(all)} {
set level 8
} else {
set level 5
}
set conns [list ]
foreach entry [_get_all_tcp 0 $level] {
foreach {state localaddr localport remoteaddr remoteport pid bindtime modulename modulepath} $entry {
break
}
if {[string equal $remoteaddr 0.0.0.0]} {
set remoteport 0
}
if {[info exists opts(matchpid)]} {
if {$pid == ""} {
error "Connection process id not available on this system."
}
if {$pid != $opts(matchpid)} {
continue
}
}
if {[info exists matchlocaladdr] &&
[lsearch -exact $matchlocaladdr $localaddr] < 0} {
continue
}
if {[info exists matchremoteaddr] &&
[lsearch -exact $matchremoteaddr $remoteaddr] < 0} {
continue
}
if {[info exists opts(matchlocalport)] &&
$opts(matchlocalport) != $localport} {
continue
}
if {[info exists opts(matchremoteport)] &&
$opts(matchremoteport) != $remoteport} {
continue
}
if {[info exists tcp_statenames($state)]} {
set state $tcp_statenames($state)
}
if {[info exists matchstates] && [lsearch -exact $matchstates $state] < 0} {
continue
}
set conn [list ]
foreach opt {localaddr localport remoteaddr remoteport state pid bindtime modulename modulepath} {
if {$opts(all) || $opts($opt)} {
lappend conn -$opt [set $opt]
}
}
lappend conns $conn
}
return $conns
}
proc twapi::get_udp_connections {args} {
array set opts [parseargs args {
localaddr
localport
pid
modulename
modulepath
bindtime
all
matchlocaladdr.arg
matchlocalport.int
matchpid.int
} -maxleftover 0]
if {! ($opts(localaddr) || $opts(localport) || $opts(pid) || $opts(modulename) || $opts(modulepath) || $opts(bindtime))} {
set opts(all) 1
}
if {[info exists opts(matchlocaladdr)]} {
set matchlocaladdr [_hosts_to_ip_addrs $opts(matchlocaladdr)]
if {[llength $matchlocaladdr] == 0} {
return [list ]; # No addresses, so no connections will match
}
}
if {$opts(modulename) || $opts(modulepath) || $opts(bindtime) || $opts(all)} {
set level 2
} else {
set level 1
}
set conns [list ]
foreach entry [_get_all_udp 0 $level] {
foreach {localaddr localport pid bindtime modulename modulepath} $entry {
break
}
if {[info exists opts(matchpid)]} {
if {$pid == ""} {
error "Connection process id not available on this system."
}
if {$pid != $opts(matchpid)} {
continue
}
}
if {[info exists matchlocaladdr] &&
[lsearch -exact $matchlocaladdr $localaddr] < 0} {
continue
}
if {[info exists opts(matchlocalport)] &&
$opts(matchlocalport) != $localport} {
continue
}
set conn [list ]
foreach opt {localaddr localport pid bindtime modulename modulepath} {
if {$opts(all) || $opts($opt)} {
lappend conn -$opt [set $opt]
}
}
lappend conns $conn
}
return $conns
}
proc twapi::terminate_tcp_connections {args} {
array set opts [parseargs args {
matchstate.int
matchlocaladdr.arg
matchremoteaddr.arg
matchlocalport.int
matchremoteport.int
matchpid.int
} -maxleftover 0]
if {[info exists opts(matchlocaladdr)] && [info exists opts(matchlocalport)] &&
[info exists opts(matchremoteaddr)] && [info exists opts(matchremoteport)] &&
! [info exists opts(matchpid)]} {
SetTcpEntry [list 12 $opts(matchlocaladdr) $opts(matchlocalport) $opts(matchremoteaddr) $opts(matchremoteport)]
return
}
foreach conn [eval get_tcp_connections [get_array_as_options opts]] {
array set aconn $conn
if {[info exists opts(matchstate)] &&
$opts(matchstate) != $aconn(-state)} {
continue
}
if {[info exists opts(matchlocaladdr)] &&
$opts(matchlocaladdr) != $aconn(-localaddr)} {
continue
}
if {[info exists opts(matchlocalport)] &&
$opts(matchlocalport) != $aconn(-localport)} {
continue
}
if {[info exists opts(matchremoteaddr)] &&
$opts(matchremoteaddr) != $aconn(-remoteaddr)} {
continue
}
if {[info exists opts(remoteport)] &&
$opts(matchremoteport) != $aconn(-remoteport)} {
continue
}
if {[info exists opts(matchpid)] &&
$opts(matchpid) != $aconn(-pid)} {
continue
}
SetTcpEntry [list 12 $aconn(-localaddr) $aconn(-localport) $aconn(-remoteaddr) $aconn(-remoteport)]
}
}
proc twapi::flush_network_name_cache {} {
array unset ::twapi::port2name
array unset ::twapi::addr2name
array unset ::twapi::name2port
array unset ::twapi::name2addr
}
proc twapi::address_to_hostname {addr args} {
variable addr2name
array set opts [parseargs args {
flushcache
async.arg
} -maxleftover 0]
if {$addr eq "0.0.0.0"} {
set addr2name($addr) $addr
set opts(flushcache) 0
}
if {[info exists addr2name($addr)]} {
if {$opts(flushcache)} {
unset addr2name($addr)
} else {
if {[info exists opts(async)]} {
after idle [list after 0 $opts(async) [list $addr success $addr2name($addr)]]
return ""
} else {
return $addr2name($addr)
}
}
}
if {[info exists opts(async)]} {
Twapi_ResolveAddressAsync $addr "::twapi::_ResolveAddress_handler [list $opts(async)]"
return ""
}
set name [lindex [twapi::getnameinfo [list $addr] 8] 0]
if {$name eq $addr} {
set name ""
}
set addr2name($addr) $name
return $name
}
proc twapi::hostname_to_address {name args} {
variable name2addr
set name [string tolower $name]
array set opts [parseargs args {
flushcache
async.arg
} -maxleftover 0]
if {[info exists name2addr($name)]} {
if {$opts(flushcache)} {
unset name2addr($name)
} else {
if {[info exists opts(async)]} {
after idle [list after 0 $opts(async) [list $name success $name2addr($name)]]
return ""
} else {
return $name2addr($name)
}
}
}
if {[info exists opts(async)]} {
Twapi_ResolveHostnameAsync $name "::twapi::_ResolveHostname_handler [list $opts(async)]"
return ""
}
set addrs [list ]
catch {
foreach endpt [twapi::getaddrinfo $name 0 0] {
foreach {addr port} $endpt break
lappend addrs $addr
}
}
set name2addr($name) $addrs
return $addrs
}
proc twapi::port_to_service {port} {
variable port2name
if {[info exists port2name($port)]} {
return $port2name($port)
}
try {
set name [lindex [twapi::getnameinfo [list 0.0.0.0 $port] 2] 1]
} onerror {TWAPI_WIN32 11004} {
set name ""
}
if {$name eq ""} {
foreach {p n} {
123 ntp
137 netbios-ns
138 netbios-dgm
500 isakmp
1900 ssdp
4500 ipsec-nat-t
} {
if {$port == $p} {
set name $n
break
}
}
}
set port2name($port) $name
return $name
}
proc twapi::service_to_port {name} {
variable name2port
set protocol 0
if {[info exists name2port($name)]} {
return $name2port($name)
}
if {[string is integer $name]} {
return $name
}
if {[catch {
set port [lindex [lindex [twapi::getaddrinfo "" $name $protocol] 0] 1]
}]} {
set port ""
}
set name2port($name) $port
return $port
}
proc twapi::get_routing_table {args} {
array set opts [parseargs args {
sort
} -maxleftover 0]
set routes [list ]
foreach route [twapi::GetIpForwardTable $opts(sort)] {
lappend routes [_format_route $route]
}
return $routes
}
proc twapi::get_route {args} {
array set opts [parseargs args {
{dest.arg 0.0.0.0}
{source.arg 0.0.0.0}
} -maxleftover 0]
return [_format_route [GetBestRoute $opts(dest) $opts(source)]]
}
proc twapi::get_outgoing_interface {{dest 0.0.0.0}} {
return [GetBestInterface $dest]
}
proc twapi::_format_route {route} {
foreach fld {
addr
mask
policy
nexthop
ifindex
type
protocol
age
nexthopas
metric1
metric2
metric3
metric4
metric5
} val $route {
set r(-$fld) $val
}
switch -exact -- $r(-type) {
2       { set r(-type) invalid }
3       { set r(-type) local }
4       { set r(-type) remote }
1       -
default { set r(-type) other }
}
switch -exact -- $r(-protocol) {
2 { set r(-protocol) local }
3 { set r(-protocol) netmgmt }
4 { set r(-protocol) icmp }
5 { set r(-protocol) egp }
6 { set r(-protocol) ggp }
7 { set r(-protocol) hello }
8 { set r(-protocol) rip }
9 { set r(-protocol) is_is }
10 { set r(-protocol) es_is }
11 { set r(-protocol) cisco }
12 { set r(-protocol) bbn }
13 { set r(-protocol) ospf }
14 { set r(-protocol) bgp }
1       -
default { set r(-protocol) other }
}
return [array get r]
}
proc twapi::_hwaddr_binary_to_string {b {joiner -}} {
if {[binary scan $b H* str]} {
set s ""
foreach {x y} [split $str ""] {
lappend s $x$y
}
return [join $s $joiner]
} else {
error "Could not convert binary hardware address"
}
}
proc twapi::_ResolveAddress_handler {script addr status hostname} {
if {$status eq "success"} {
set ::twapi::addr2name($addr) $hostname
}
eval $script [list $addr $status $hostname]
return
}
proc twapi::_ResolveHostname_handler {script name status addrs} {
if {$status eq "success"} {
set ::twapi::name2addr($name) $addrs
} elseif {$addrs == 11001} {
set status success
set addrs [list ]
}
eval $script [list $name $status $addrs]
return
}
proc twapi::_get_all_tcp {{sort 0} {level 5}} {
if {[catch {twapi::GetExtendedTcpTable NULL 0 $sort 2 $level} bufsz]} {
return [AllocateAndGetTcpExTableFromStack $sort 0]
}
set buf [twapi::malloc $bufsz]
try {
while {true} {
set reqsz [twapi::GetExtendedTcpTable $buf $bufsz $sort 2 $level]
if {$reqsz <= $bufsz} {
return [Twapi_FormatExtendedTcpTable $buf 2 $level]
}
set bufsz $reqsz
twapi::free $buf
unset buf;          # So if malloc fails, we do not free buf again
set buf [twapi::malloc $bufsz]
}
} finally {
if {[info exists buf]} {
twapi::free $buf
}
}
}
proc twapi::_get_all_udp {{sort 0} {level 1}} {
if {[catch {twapi::GetExtendedUdpTable NULL 0 $sort 2 $level} bufsz]} {
return [AllocateAndGetUdpExTableFromStack $sort 0]
}
set buf [twapi::malloc $bufsz]
try {
while {true} {
set reqsz [twapi::GetExtendedUdpTable $buf $bufsz $sort 2 $level]
if {$reqsz <= $bufsz} {
return [Twapi_FormatExtendedUdpTable $buf 2 $level]
}
set bufsz $reqsz
twapi::free $buf
unset buf;          # So if malloc fails, we do not free buf again
set buf [twapi::malloc $bufsz]
}
} finally {
if {[info exists buf]} {
twapi::free $buf
}
}
}
proc twapi::_valid_ipaddr_format {ipaddr} {
set sub {([01]?\d\d?|2[0-4]\d|25[0-5])}
return [regexp "^$sub\.$sub\.$sub\.$sub\$" $ipaddr]
}
proc twapi::_hosts_to_ip_addrs hosts {
set addrs [list ]
foreach host $hosts {
if {[_valid_ipaddr_format $host]} {
lappend addrs $host
} else {
if {![catch {hostname_to_address $host -flushcache} hostaddrs]} {
set addrs [concat $addrs $hostaddrs]
}
}
}
return $addrs
}
#-- from nls.tcl
namespace eval twapi {
}
proc twapi::get_user_default_lcid {} {return [GetUserDefaultLCID]}
proc twapi::get_system_default_lcid {} {return [GetSystemDefaultLCID]}
proc twapi::get_user_langid {} {return [GetUserDefaultLangID]}
interp alias {} twapi::get_user_default_langid {} twapi::get_user_langid
proc twapi::get_system_langid {} {return [GetSystemDefaultLangID]}
interp alias {} twapi::get_system_default_langid {} twapi::get_system_langid
proc twapi::get_user_ui_langid {} {
try {
return [GetUserDefaultUILanguage]
} onerror {TWAPI_WIN32 127} {
return [get_user_langid]
}
}
proc twapi::get_system_ui_langid {} {
try {
return [GetSystemDefaultUILanguage]
} onerror {TWAPI_WIN32 127} {
return [get_system_langid]
}
}
proc twapi::get_lcid {} {
return [GetThreadLocale]
}
proc twapi::format_number {number lcid args} {
set number [_verify_number_format $number]
set lcid [_map_default_lcid_token $lcid]
if {[llength $args] == 0} {
return [GetNumberFormat 1 $lcid 0 $number 0 0 0 . "" 0]
}
array set opts [parseargs args {
idigits.int
ilzero.bool
sgrouping.int
sdecimal.arg
sthousand.arg
inegnumber.int
}]
foreach opt {idigits ilzero sgrouping sdecimal sthousand inegnumber} {
if {![info exists opts($opt)]} {
set opts($opt) [lindex [get_locale_info $lcid -$opt] 1]
}
}
if {$opts(idigits) == -1} {
foreach {whole frac} [split $number .] break
set opts(idigits) [string length $frac]
}
if {![string is integer $opts(sgrouping)]} {
set grouping 0
foreach n [split $opts(sgrouping) {;}] {
if {$n == 0} break
set grouping [expr {$n + 10*$grouping}]
}
set opts(sgrouping) $grouping
}
set flags 0
if {[info exists opts(nouseroverride)] && $opts(nouseroverride)} {
setbits flags 0x80000000
}
return [GetNumberFormat 0 $lcid $flags $number $opts(idigits) \
$opts(ilzero) $opts(sgrouping) $opts(sdecimal) \
$opts(sthousand) $opts(inegnumber)]
}
proc twapi::format_currency {number lcid args} {
set number [_verify_number_format $number]
set number [expr {$number+0}];
set lcid [_map_default_lcid_token $lcid]
if {[llength $args] == 0} {
return [GetCurrencyFormat 1 $lcid 0 $number 0 0 0 . "" 0 0 ""]
}
array set opts [parseargs args {
idigits.int
ilzero.bool
sgrouping.int
sdecimal.arg
sthousand.arg
inegcurr.int
icurrency.int
scurrency.arg
}]
foreach opt {idigits ilzero sgrouping sdecimal sthousand inegcurr icurrency scurrency} {
if {![info exists opts($opt)]} {
set opts($opt) [lindex [get_locale_info $lcid -$opt] 1]
}
}
if {$opts(idigits) == -1} {
foreach {whole frac} [split $number .] break
set opts(idigits) [string length $frac]
}
if {![string is integer $opts(sgrouping)]} {
set grouping 0
foreach n [split $opts(sgrouping) {;}] {
if {$n == 0} break
set grouping [expr {$n + 10*$grouping}]
}
set opts(sgrouping) $grouping
}
set flags 0
if {[info exists opts(nouseroverride)] && $opts(nouseroverride)} {
setbits flags 0x80000000
}
return [GetCurrencyFormat 0 $lcid $flags $number $opts(idigits) \
$opts(ilzero) $opts(sgrouping) $opts(sdecimal) \
$opts(sthousand) $opts(inegcurr) \
$opts(icurrency) $opts(scurrency)]
}
proc twapi::get_locale_info {lcid args} {
set lcid [_map_default_lcid_token $lcid]
variable locale_info_class_map
if {![info exists locale_info_class_map]} {
array set locale_info_class_map {
ilanguage              0x00000001
slanguage              0x00000002
senglanguage           0x00001001
sabbrevlangname        0x00000003
snativelangname        0x00000004
icountry               0x00000005
scountry               0x00000006
sengcountry            0x00001002
sabbrevctryname        0x00000007
snativectryname        0x00000008
idefaultlanguage       0x00000009
idefaultcountry        0x0000000A
idefaultcodepage       0x0000000B
idefaultansicodepage   0x00001004
idefaultmaccodepage    0x00001011
slist                  0x0000000C
imeasure               0x0000000D
sdecimal               0x0000000E
sthousand              0x0000000F
sgrouping              0x00000010
idigits                0x00000011
ilzero                 0x00000012
inegnumber             0x00001010
snativedigits          0x00000013
scurrency              0x00000014
sintlsymbol            0x00000015
smondecimalsep         0x00000016
smonthousandsep        0x00000017
smongrouping           0x00000018
icurrdigits            0x00000019
iintlcurrdigits        0x0000001A
icurrency              0x0000001B
inegcurr               0x0000001C
sdate                  0x0000001D
stime                  0x0000001E
sshortdate             0x0000001F
slongdate              0x00000020
stimeformat            0x00001003
idate                  0x00000021
ildate                 0x00000022
itime                  0x00000023
itimemarkposn          0x00001005
icentury               0x00000024
itlzero                0x00000025
idaylzero              0x00000026
imonlzero              0x00000027
s1159                  0x00000028
s2359                  0x00000029
icalendartype          0x00001009
ioptionalcalendar      0x0000100B
ifirstdayofweek        0x0000100C
ifirstweekofyear       0x0000100D
sdayname1              0x0000002A
sdayname2              0x0000002B
sdayname3              0x0000002C
sdayname4              0x0000002D
sdayname5              0x0000002E
sdayname6              0x0000002F
sdayname7              0x00000030
sabbrevdayname1        0x00000031
sabbrevdayname2        0x00000032
sabbrevdayname3        0x00000033
sabbrevdayname4        0x00000034
sabbrevdayname5        0x00000035
sabbrevdayname6        0x00000036
sabbrevdayname7        0x00000037
smonthname1            0x00000038
smonthname2            0x00000039
smonthname3            0x0000003A
smonthname4            0x0000003B
smonthname5            0x0000003C
smonthname6            0x0000003D
smonthname7            0x0000003E
smonthname8            0x0000003F
smonthname9            0x00000040
smonthname10           0x00000041
smonthname11           0x00000042
smonthname12           0x00000043
smonthname13           0x0000100E
sabbrevmonthname1      0x00000044
sabbrevmonthname2      0x00000045
sabbrevmonthname3      0x00000046
sabbrevmonthname4      0x00000047
sabbrevmonthname5      0x00000048
sabbrevmonthname6      0x00000049
sabbrevmonthname7      0x0000004A
sabbrevmonthname8      0x0000004B
sabbrevmonthname9      0x0000004C
sabbrevmonthname10     0x0000004D
sabbrevmonthname11     0x0000004E
sabbrevmonthname12     0x0000004F
sabbrevmonthname13     0x0000100F
spositivesign          0x00000050
snegativesign          0x00000051
ipossignposn           0x00000052
inegsignposn           0x00000053
ipossymprecedes        0x00000054
ipossepbyspace         0x00000055
inegsymprecedes        0x00000056
inegsepbyspace         0x00000057
fontsignature          0x00000058
siso639langname        0x00000059
siso3166ctryname       0x0000005A
idefaultebcdiccodepage 0x00001012
ipapersize             0x0000100A
sengcurrname           0x00001007
snativecurrname        0x00001008
syearmonth             0x00001006
ssortname              0x00001013
idigitsubstitution     0x00001014
}
}
array set opts [parseargs args [array names locale_info_class_map]]
set result [list ]
foreach opt [array names opts] {
if {$opts($opt)} {
lappend result -$opt [GetLocaleInfo $lcid $locale_info_class_map($opt)]
}
}
return $result
}
proc twapi::map_code_page_to_name {cp} {
variable code_page_names
if {![info exists code_page_names]} {
array set code_page_names {
0   "System ANSI default"
1   "System OEM default"
37 "IBM EBCDIC - U.S./Canada"
437 "OEM - United States"
500 "IBM EBCDIC - International"
708 "Arabic - ASMO 708"
709 "Arabic - ASMO 449+, BCON V4"
710 "Arabic - Transparent Arabic"
720 "Arabic - Transparent ASMO"
737 "OEM - Greek (formerly 437G)"
775 "OEM - Baltic"
850 "OEM - Multilingual Latin I"
852 "OEM - Latin II"
855 "OEM - Cyrillic (primarily Russian)"
857 "OEM - Turkish"
858 "OEM - Multlingual Latin I + Euro symbol"
860 "OEM - Portuguese"
861 "OEM - Icelandic"
862 "OEM - Hebrew"
863 "OEM - Canadian-French"
864 "OEM - Arabic"
865 "OEM - Nordic"
866 "OEM - Russian"
869 "OEM - Modern Greek"
870 "IBM EBCDIC - Multilingual/ROECE (Latin-2)"
874 "ANSI/OEM - Thai (same as 28605, ISO 8859-15)"
875 "IBM EBCDIC - Modern Greek"
932 "ANSI/OEM - Japanese, Shift-JIS"
936 "ANSI/OEM - Simplified Chinese (PRC, Singapore)"
949 "ANSI/OEM - Korean (Unified Hangeul Code)"
950 "ANSI/OEM - Traditional Chinese (Taiwan; Hong Kong SAR, PRC)"
1026 "IBM EBCDIC - Turkish (Latin-5)"
1047 "IBM EBCDIC - Latin 1/Open System"
1140 "IBM EBCDIC - U.S./Canada (037 + Euro symbol)"
1141 "IBM EBCDIC - Germany (20273 + Euro symbol)"
1142 "IBM EBCDIC - Denmark/Norway (20277 + Euro symbol)"
1143 "IBM EBCDIC - Finland/Sweden (20278 + Euro symbol)"
1144 "IBM EBCDIC - Italy (20280 + Euro symbol)"
1145 "IBM EBCDIC - Latin America/Spain (20284 + Euro symbol)"
1146 "IBM EBCDIC - United Kingdom (20285 + Euro symbol)"
1147 "IBM EBCDIC - France (20297 + Euro symbol)"
1148 "IBM EBCDIC - International (500 + Euro symbol)"
1149 "IBM EBCDIC - Icelandic (20871 + Euro symbol)"
1200 "Unicode UCS-2 Little-Endian (BMP of ISO 10646)"
1201 "Unicode UCS-2 Big-Endian"
1250 "ANSI - Central European"
1251 "ANSI - Cyrillic"
1252 "ANSI - Latin I"
1253 "ANSI - Greek"
1254 "ANSI - Turkish"
1255 "ANSI - Hebrew"
1256 "ANSI - Arabic"
1257 "ANSI - Baltic"
1258 "ANSI/OEM - Vietnamese"
1361 "Korean (Johab)"
10000 "MAC - Roman"
10001 "MAC - Japanese"
10002 "MAC - Traditional Chinese (Big5)"
10003 "MAC - Korean"
10004 "MAC - Arabic"
10005 "MAC - Hebrew"
10006 "MAC - Greek I"
10007 "MAC - Cyrillic"
10008 "MAC - Simplified Chinese (GB 2312)"
10010 "MAC - Romania"
10017 "MAC - Ukraine"
10021 "MAC - Thai"
10029 "MAC - Latin II"
10079 "MAC - Icelandic"
10081 "MAC - Turkish"
10082 "MAC - Croatia"
12000 "Unicode UCS-4 Little-Endian"
12001 "Unicode UCS-4 Big-Endian"
20000 "CNS - Taiwan"
20001 "TCA - Taiwan"
20002 "Eten - Taiwan"
20003 "IBM5550 - Taiwan"
20004 "TeleText - Taiwan"
20005 "Wang - Taiwan"
20105 "IA5 IRV International Alphabet No. 5 (7-bit)"
20106 "IA5 German (7-bit)"
20107 "IA5 Swedish (7-bit)"
20108 "IA5 Norwegian (7-bit)"
20127 "US-ASCII (7-bit)"
20261 "T.61"
20269 "ISO 6937 Non-Spacing Accent"
20273 "IBM EBCDIC - Germany"
20277 "IBM EBCDIC - Denmark/Norway"
20278 "IBM EBCDIC - Finland/Sweden"
20280 "IBM EBCDIC - Italy"
20284 "IBM EBCDIC - Latin America/Spain"
20285 "IBM EBCDIC - United Kingdom"
20290 "IBM EBCDIC - Japanese Katakana Extended"
20297 "IBM EBCDIC - France"
20420 "IBM EBCDIC - Arabic"
20423 "IBM EBCDIC - Greek"
20424 "IBM EBCDIC - Hebrew"
20833 "IBM EBCDIC - Korean Extended"
20838 "IBM EBCDIC - Thai"
20866 "Russian - KOI8-R"
20871 "IBM EBCDIC - Icelandic"
20880 "IBM EBCDIC - Cyrillic (Russian)"
20905 "IBM EBCDIC - Turkish"
20924 "IBM EBCDIC - Latin-1/Open System (1047 + Euro symbol)"
20932 "JIS X 0208-1990 & 0121-1990"
20936 "Simplified Chinese (GB2312)"
21025 "IBM EBCDIC - Cyrillic (Serbian, Bulgarian)"
21027 "Extended Alpha Lowercase"
21866 "Ukrainian (KOI8-U)"
28591 "ISO 8859-1 Latin I"
28592 "ISO 8859-2 Central Europe"
28593 "ISO 8859-3 Latin 3"
28594 "ISO 8859-4 Baltic"
28595 "ISO 8859-5 Cyrillic"
28596 "ISO 8859-6 Arabic"
28597 "ISO 8859-7 Greek"
28598 "ISO 8859-8 Hebrew"
28599 "ISO 8859-9 Latin 5"
28605 "ISO 8859-15 Latin 9"
29001 "Europa 3"
38598 "ISO 8859-8 Hebrew"
50220 "ISO 2022 Japanese with no halfwidth Katakana"
50221 "ISO 2022 Japanese with halfwidth Katakana"
50222 "ISO 2022 Japanese JIS X 0201-1989"
50225 "ISO 2022 Korean"
50227 "ISO 2022 Simplified Chinese"
50229 "ISO 2022 Traditional Chinese"
50930 "Japanese (Katakana) Extended"
50931 "US/Canada and Japanese"
50933 "Korean Extended and Korean"
50935 "Simplified Chinese Extended and Simplified Chinese"
50936 "Simplified Chinese"
50937 "US/Canada and Traditional Chinese"
50939 "Japanese (Latin) Extended and Japanese"
51932 "EUC - Japanese"
51936 "EUC - Simplified Chinese"
51949 "EUC - Korean"
51950 "EUC - Traditional Chinese"
52936 "HZ-GB2312 Simplified Chinese"
54936 "Windows XP: GB18030 Simplified Chinese (4 Byte)"
57002 "ISCII Devanagari"
57003 "ISCII Bengali"
57004 "ISCII Tamil"
57005 "ISCII Telugu"
57006 "ISCII Assamese"
57007 "ISCII Oriya"
57008 "ISCII Kannada"
57009 "ISCII Malayalam"
57010 "ISCII Gujarati"
57011 "ISCII Punjabi"
65000 "Unicode UTF-7"
65001 "Unicode UTF-8"
}
}
set cp [expr {0+$cp}]
if {[info exists code_page_names($cp)]} {
return $code_page_names($cp)
} else {
return "Code page $cp"
}
}
proc twapi::map_langid_to_name {langid} {
return [VerLanguageName $langid]
}
proc twapi::extract_primary_langid {langid} {
return [expr {$langid & 0x3ff}]
}
proc twapi::extract_sublanguage_langid {langid} {
return [expr {($langid >> 10) & 0x3f}]
}
proc twapi::_map_default_lcid_token {lcid} {
if {$lcid == "systemdefault"} {
return 2048
} elseif {$lcid == "userdefault"} {
return 1024
}
return $lcid
}
proc twapi::_verify_number_format {n} {
set n [string trimleft $n 0]
if {[regexp {^[+-]?[[:digit:]]*(\.)?[[:digit:]]*$} $n]} {
return $n
} else {
error "Invalid numeric format. Must be of a sequence of digits with an optional decimal point and leading plus/minus sign"
}
}
#-- from osinfo.tcl
namespace eval twapi {
}
proc twapi::get_os_info {} {
variable windefs
set vers_info [new_OSVERSIONINFOEXW]
set info_sz             276
set extended_info_sz    284
set have_extended_info  1
$vers_info configure -dwOSVersionInfoSize $extended_info_sz
if {[catch {GetVersionEx $vers_info}]} {
$vers_info configure -dwOSVersionInfoSize $info_sz
GetVersionEx $vers_info
set have_extended_info 0
}
set osinfo(os_major_version) [$vers_info cget -dwMajorVersion]
set osinfo(os_minor_version) [$vers_info cget -dwMinorVersion]
set osinfo(os_build_number)  [$vers_info cget -dwBuildNumber]
set osinfo(platform)         "NT"
if {$have_extended_info} {
set osinfo(sp_major_version) [$vers_info cget -wServicePackMajor]
set osinfo(sp_minor_version) [$vers_info cget -wServicePackMinor]
set osinfo(suites) [list ]
set suites [$vers_info cget -wSuiteMask]
foreach suite {
backoffice blade datacenter enterprise smallbusiness
smallbusiness_restricted terminal personal
} {
set def "VER_SUITE_[string toupper $suite]"
if {$suites & $windefs($def)} {
lappend osinfo(suites) $suite
}
}
set system_type [$vers_info cget -wProductType]
if {$system_type == $windefs(VER_NT_WORKSTATION)} {
set osinfo(system_type) "workstation"
} elseif {$system_type == $windefs(VER_NT_SERVER)} {
set osinfo(system_type) "server"
} elseif {$system_type == $windefs(VER_NT_DOMAIN_CONTROLLER)} {
set osinfo(system_type) "domain_controller"
} else {
set osinfo(system_type) "unknown"
}
} else {
package require registry
set osinfo(suites) [list ]
set product_type [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\ProductOptions" "ProductType"]
switch -exact -- [string toupper $product_type] {
"WINNT" {
set osinfo(system_type) "workstation"
}
"LANMANNT" {
set osinfo(system_type) "server"
}
"SERVERNT" {
set osinfo(system_type) "server"
lappend osinfo(suites)  "enterprise"
}
}
set sp_text [registry get "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" "CSDVersion"]
set sp_major 0
regexp -nocase {Service Pack ([0-9]+)} $sp_text dummy sp_major
set osinfo(sp_major_version) $sp_major
set osinfo(sp_minor_version) 0; # Always 0
if {[catch {
registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\ProductOptions" "ProductSuite"
} ts] == 0} {
if {[string equal -nocase $ts "Terminal Server"]} {
lappend osinfo(suites) "terminal"
}
}
}
return [array get osinfo]
}
proc twapi::get_os_description {} {
array set osinfo [get_os_info]
set tserver ""
set osversion "$osinfo(os_major_version).$osinfo(os_minor_version)"
if {$osinfo(os_major_version) < 5} {
set osname "Windows NT"
if {[string equal $osinfo(system_type) "workstation"]} {
set systype "Workstation"
} else {
if {[lsearch -exact $osinfo(suites) "terminal"] >= 0} {
set systype "Terminal Server Edition"
} elseif {[lsearch -exact $osinfo(suites) "enterprise"] >= 0} {
set systype "Advanced Server"
} else {
set systype "Server"
}
}
} else {
switch -exact -- $osversion {
"5.0" {
set osname "Windows 2000"
if {[string equal $osinfo(system_type) "workstation"]} {
set systype "Professional"
} else {
if {[lsearch -exact $osinfo(suites) "datacenter"] >= 0} {
set systype "Datacenter Server"
} elseif {[lsearch -exact $osinfo(suites) "enterprise"] >= 0} {
set systype "Advanced Server"
} else {
set systype "Server"
}
}
}
"5.1" {
set osname "Windows XP"
if {[lsearch -exact $osinfo(suites) "personal"] >= 0} {
set systype "Home Edition"
} else {
set systype "Professional"
}
}
"5.2" {
set osname "Windows Server 2003"
if {[string equal $osinfo(system_type) "workstation"]} {
set systype "Professional"
} else {
if {[lsearch -exact $osinfo(suites) "datacenter"] >= 0} {
set systype "Datacenter Edition"
} elseif {[lsearch -exact $osinfo(suites) "enterprise"] >= 0} {
set systype "Enterprise Edition"
} elseif {[lsearch -exact $osinfo(suites) "blade"] >= 0} {
set systype "Web Edition"
} else {
set systype "Standard Edition"
}
}
}
default {
set osname "Windows"
if {[string equal $osinfo(system_type) "workstation"]} {
set systype "Professional"
} else {
set systype "Server"
}
}
}
if {[lsearch -exact $osinfo(suites) "terminal"] >= 0} {
set tserver " with Terminal Services"
}
}
if {$osinfo(sp_major_version) != 0} {
set spver " Service Pack $osinfo(sp_major_version)"
} else {
set spver ""
}
return "$osname $systype ${osversion} (Build $osinfo(os_build_number))${spver}${tserver}"
}
proc twapi::get_os_version {} {
if {[info exists ::twapi::_osversion]} {
return $::twapi::_osversion
}
array set osinfo [get_os_info]
set ::twapi::_osversion \
[list $osinfo(os_major_version) $osinfo(os_minor_version) \
$osinfo(sp_major_version) $osinfo(sp_minor_version)]
return $::twapi::_osversion
}
proc twapi::min_os_version {major {minor 0} {spmajor 0} {spminor 0}} {
foreach {osmajor osminor osspmajor osspminor} [twapi::get_os_version] {break}
if {$osmajor > $major} {return 1}
if {$osmajor < $major} {return 0}
if {$osminor > $minor} {return 1}
if {$osminor < $minor} {return 0}
if {$osspmajor > $spmajor} {return 1}
if {$osspmajor < $spmajor} {return 0}
if {$osspminor > $spminor} {return 1}
if {$osspminor < $spminor} {return 0}
return 1
}
proc twapi::get_processor_info {processor args} {
if {![info exists ::twapi::get_processor_info_base_opts]} {
array set ::twapi::get_processor_info_base_opts {
idletime    IdleTime
privilegedtime  KernelTime
usertime    UserTime
dpctime     DpcTime
interrupttime InterruptTime
interrupts    InterruptCount
}
}
set pdh_opts {
dpcutilization
interruptutilization
privilegedutilization
processorutilization
userutilization
dpcrate
dpcqueuerate
interruptrate
}
set sysinfo_opts {
arch
processorlevel
processorrev
processorname
processormodel
processorspeed
}
array set opts [parseargs args \
[concat [list all \
currentprocessorspeed \
[list interval.int 100]] \
[array names ::twapi::get_processor_info_base_opts] \
$pdh_opts $sysinfo_opts]]
set reg_hwkey "HKEY_LOCAL_MACHINE\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\[expr {$processor == "" ? 0 : $processor}]"
set results [list ]
set processordata [Twapi_SystemProcessorTimes]
if {$processor ne ""} {
if {[llength $processordata] <= $processor} {
error "Invalid processor number '$processor'"
}
array set times [lindex $processordata $processor]
foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
if {$opts(all) || $opts($opt)} {
lappend results -$opt $times($field)
}
}
} else {
foreach instancedata $processordata {
foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
if {[info exists times($field)]} {
set times($field) [expr {wide($times($field)) + [kl_get $instancedata $field]}]
} else {
set times($field) [kl_get $instancedata $field]
}
}
foreach {opt field} [array get ::twapi::get_processor_info_base_opts] {
if {$opts(all) || $opts($opt)} {
lappend results -$opt $times($field)
}
}
}
}
if {$opts(all) || $opts(currentprocessorspeed)} {
if {[catch {
set ctr_path [make_perf_counter_path ProcessorPerformance "Processor Frequency" -instance Processor_Number_$processor -localize true]
lappend results -currentprocessorspeed [get_counter_path_value $ctr_path -interval $opts(interval)]
}]} {
if {[catch {registry get $reg_hwkey "~MHz"} val]} {
set val "unknown"
}
lappend results -currentprocessorspeed $val
}
}
set requested_opts [list ]
foreach pdh_opt $pdh_opts {
if {$opts(all) || $opts($pdh_opt)} {
lappend requested_opts "-$pdh_opt"
}
}
if {[llength $requested_opts]} {
set counter_list [eval [list get_perf_processor_counter_paths $processor] \
$requested_opts]
foreach {opt processor value} [get_perf_values_from_metacounter_info $counter_list -interval $opts(interval)] {
lappend results -$opt $value
}
}
if {$opts(all) || $opts(arch) || $opts(processorlevel) || $opts(processorrev)} {
set sysinfo [GetSystemInfo]
if {$opts(all) || $opts(arch)} {
switch -exact -- [lindex $sysinfo 0] {
0 {set arch intel}
6 {set arch ia64}
9 {set arch amd64}
10 {set arch ia32_win64}
default {set arch unknown}
}
lappend results -arch $arch
}
if {$opts(all) || $opts(processorlevel)} {
lappend results -processorlevel [lindex $sysinfo 8]
}
if {$opts(all) || $opts(processorrev)} {
lappend results -processorrev [format %x [lindex $sysinfo 9]]
}
}
if {$opts(all) || $opts(processorname)} {
if {[catch {registry get $reg_hwkey "ProcessorNameString"} val]} {
set val "unknown"
}
lappend results -processorname $val
}
if {$opts(all) || $opts(processormodel)} {
if {[catch {registry get $reg_hwkey "Identifier"} val]} {
set val "unknown"
}
lappend results -processormodel $val
}
if {$opts(all) || $opts(processorspeed)} {
if {[catch {registry get $reg_hwkey "~MHz"} val]} {
set val "unknown"
}
lappend results -processorspeed $val
}
return $results
}
proc twapi::get_processor_count {} {
return [lindex [GetSystemInfo] 5]
}
proc twapi::get_active_processor_mask {} {
return [format 0x%x [lindex [GetSystemInfo] 4]]
}
proc twapi::get_memory_info {args} {
array set opts [parseargs args {
all
allocationgranularity
availcommit
availphysical
minappaddr
maxappaddr
pagesize
swapfiles
swapfiledetail
totalcommit
totalphysical
}]
set results [list ]
if {$opts(all) || $opts(totalphysical) || $opts(availphysical) ||
$opts(totalcommit) || $opts(availcommit)} {
foreach {totalphysical availphysical totalcommit availcommit} [GlobalMemoryStatus] break
foreach opt {totalphysical availphysical totalcommit availcommit} {
if {$opts(all) || $opts($opt)} {
lappend results -$opt [set $opt]
}
}
}
if {$opts(all) || $opts(swapfiles) || $opts(swapfiledetail)} {
set swapfiles [list ]
set swapdetail [list ]
foreach item [Twapi_SystemPagefileInformation] {
array set swap $item
set swap(FileName) [_normalize_path $swap(FileName)]
lappend swapfiles $swap(FileName)
lappend swapdetail $swap(FileName) [list $swap(CurrentSize) $swap(TotalUsed) $swap(PeakUsed)]
}
if {$opts(all) || $opts(swapfiles)} {
lappend results -swapfiles $swapfiles
}
if {$opts(all) || $opts(swapfiledetail)} {
lappend results -swapfiledetail $swapdetail
}
}
if {$opts(all) || $opts(allocationgranularity) ||
$opts(minappaddr) || $opts(maxappaddr) || $opts(pagesize)} {
set sysinfo [twapi::GetSystemInfo]
foreach {opt fmt index} {
pagesize %u 1 minappaddr 0x%x 2 maxappaddr 0x%x 3 allocationgranularity %u 7} {
if {$opts(all) || $opts($opt)} {
lappend results -$opt [format $fmt [lindex $sysinfo $index]]
}
}
}
return $results
}
proc twapi::get_computer_netbios_name {} {
return [GetComputerName]
}
proc twapi::get_computer_name {{typename netbios}} {
if {[string is integer $typename]} {
set type $typename
} else {
set type [lsearch -exact {netbios dnshostname dnsdomain dnsfullyqualified physicalnetbios physicaldnshostname physicaldnsdomain physicaldnsfullyqualified} $typename]
if {$type < 0} {
error "Unknown computer name type '$typename' specified"
}
}
return [GetComputerNameEx $type]
}
proc twapi::shutdown_system {args} {
array set opts [parseargs args {
system.arg
{message.arg "System shutdown has been initiated"}
{timeout.int 60}
force
restart
} -nulldefault]
eval_with_privileges {
InitiateSystemShutdown $opts(system) $opts(message) \
$opts(timeout) $opts(force) $opts(restart)
} SeShutdownPrivilege
}
proc twapi::abort_system_shutdown {args} {
array set opts [parseargs args {system.arg} -nulldefault]
eval_with_privileges {
AbortSystemShutdown $opts(system)
} SeShutdownPrivilege
}
proc twapi::get_system_uptime {} {
set ctr_path [make_perf_counter_path System "System Up Time" -localize true]
return [get_counter_path_value $ctr_path -interval 0]
}
proc twapi::get_system_info {args} {
array set opts [parseargs args {
all
sid
uptime
handlecount
eventcount
mutexcount
processcount
sectioncount
semaphorecount
threadcount
} -maxleftover 0]
set result [list ]
if {$opts(all) || $opts(uptime)} {
lappend result -uptime [get_system_uptime]
}
if {$opts(all) || $opts(sid)} {
set lsah [get_lsa_policy_handle -access policy_view_local_information]
try {
lappend result -sid [lindex [Twapi_LsaQueryInformationPolicy $lsah 5] 1]
} finally {
close_lsa_policy_handle $lsah
}
}
if {! ($opts(all) || $opts(handlecount) || $opts(processcount) || $opts(threadcount) || $opts(eventcount) || $opts(mutexcount) || $opts(sectioncount) || $opts(semaphorecount))} {
return $result
}
set hquery [open_perf_query]
try {
if {$opts(all) || $opts(handlecount)} {
set handlecount_ctr [add_perf_counter $hquery [make_perf_counter_path Process "Handle Count" -instance _Total -localize true]]
}
foreach {opt ctrname} {
eventcount   Events
mutexcount   Mutexes
processcount Processes
sectioncount Sections
semaphorecount Semaphores
threadcount  Threads
} {
if {$opts(all) || $opts($opt)} {
set ${opt}_ctr [add_perf_counter $hquery [make_perf_counter_path Objects $ctrname -localize true]]
}
}
collect_perf_query_data $hquery
foreach opt {
handlecount
eventcount
mutexcount
processcount
sectioncount
semaphorecount
threadcount
} {
if {[info exists ${opt}_ctr]} {
lappend result -$opt [get_hcounter_value [set ${opt}_ctr] -format long -scale "" -full 0]
}
}
} finally {
foreach opt {
handlecount
eventcount
mutexcount
processcount
sectioncount
semaphorecount
threadcount
} {
if {[info exists ${opt}_ctr]} {
remove_perf_counter [set ${opt}_ctr]
}
}
close_perf_query $hquery
}
return $result
}
proc twapi::XXXget_open_handles {args} {
variable handle_type_names
array set opts [parseargs args {
{pid.int  -1}
{type.arg -1}
{ignoreerrors.bool 1}
}]
if {![info exists handle_type_values]} {
if {[min_os_version 5 1]} {
array set handle_type_values {
desktop       18
directory     2
event         9
file          28
iocompletion  27
key           20
keyedevent    16
mutant        11
port          21
process       5
section       19
semaphore     13
thread        6
timer         14
token         4
windowstation 17
wmiguid       29
}
} else {
array set handle_type_values {
desktop       16
directory     2
event         8
file          26
iocompletion  25
key           18
mutant        10
port          19
process       5
section       17
semaphore     12
thread        6
timer         13
token         4
windowstation 15
}
}
}
if {![string is integer -strict $opts(type)]} {
set opts(type) $handle_type_values($opts(type))
}
set result [list ]
eval_with_privileges {
foreach hl [Twapi_GetHandleInformation $opts(pid) $opts(ignoreerrors) 10 $opts(type)] {
lappend result [list \
-handle [lindex $hl 0] \
-pid    [lindex $hl 1] \
-name   [lindex $hl 7] \
-type   [string tolower [lindex $hl 9]] \
]
}
} [list SeDebugPrivilege] -besteffort
return $result
}
proc twapi::XXXget_open_handle_pids {pat args} {
array set opts [parseargs args {
{type.arg file}
{match.arg string}
}]
switch -exact -- $opts(match) {
string {set op equal}
glob   {set op match}
default {error "Invalid value '$opts(match)' specified for option -match"}
}
array set names {}
foreach elem [XXXget_open_handles -type $opts(type)] {
array set handleinfo $elem
lappend names($handleinfo(-name)) $handleinfo(-pid)
}
set matches [list ]
if {$op == "equal" && [info exists names($pat)]} {
lappend matches $pat [lsort -unique $names($pat)]
unset names($pat);              # So we don't include it again
}
foreach {index val} [array get names] {
if {[string $op -nocase $pat $index]} {
lappend matches $index [lsort -unique $val]
unset names($index);              # So we don't include it again
}
}
switch -exact -- $opts(type) {
file -
directory {
set native_name      [file nativename $pat]
set norm_name        [file nativename [file normalize $pat]]
set volrelative_name [lrange [file split $norm_name] 1 end]
set volrelative_name [eval [list file join /] $volrelative_name]
set volrelative_name [file nativename $volrelative_name]
}
default {
return $matches
}
}
foreach {index val} [array get names] {
if {[string $op -nocase $native_name $index]} {
lappend matches $index [lsort -unique $val]
continue
}
if {[string $op -nocase $norm_name $index]} {
lappend matches $index [lsort -unique $val]
continue
}
if {[string $op -nocase $volrelative_name $index]} {
lappend matches $index [lsort -unique $val]
continue
}
}
return $matches
if {0} {
Old code
if {[info exists norm_index]} {
return [list $norm_index [lsort -unique $names($norm_index)]]
}
if {[info exists volrelative_name_index]} {
return [list $volrelative_name_index [lsort -unique $names($volrelative_name_index)]]
}
return [list ]
}
}
proc twapi::map_windows_error {code} {
return [string trimright [twapi::Twapi_MapWindowsErrorToString $code] "\r\n"]
}
proc twapi::expand_environment_strings {s} {
return [ExpandEnvironmentStrings $s]
}
proc twapi::load_library {path args} {
array set opts [parseargs args {
dontresolverefs
datafile
alteredpath
}]
set flags 0
if {$opts(dontresolverefs)} {
setbits flags 1;                # DONT_RESOLVE_DLL_REFERENCES
}
if {$opts(datafile)} {
setbits flags 2;                # LOAD_LIBRARY_AS_DATAFILE
}
if {$opts(alteredpath)} {
setbits flags 8;                # LOAD_WITH_ALTERED_SEARCH_PATH
}
set path [file nativename $path]
return [LoadLibraryEx $path $flags]
}
proc twapi::free_library {libh} {
FreeLibrary $libh
}
proc twapi::format_message {args} {
if {[catch {eval _unsafe_format_message $args} result]} {
set erinfo $::errorInfo
set ercode $::errorCode
if {[lindex $ercode 0] == "POSIX" && [lindex $ercode 1] == "EFAULT"} {
return [eval _unsafe_format_message -ignoreinserts $args]
} else {
error $result $erinfo $ercode
}
}
return $result
}
proc twapi::read_inifile_key {section key args} {
array set opts [parseargs args {
{default.arg ""}
inifile.arg
} -maxleftover 0]
if {[info exists opts(inifile)]} {
return [GetPrivateProfileString $section $key $opts(default) $opts(inifile)]
} else {
return [GetProfileString $section $key $opts(default)]
}
}
proc twapi::write_inifile_key {section key value args} {
array set opts [parseargs args {
inifile.arg
} -maxleftover 0]
if {[info exists opts(inifile)]} {
WritePrivateProfileString $section $key $value $opts(inifile)
} else {
WriteProfileString $section $key $value
}
}
proc twapi::delete_inifile_key {section key args} {
array set opts [parseargs args {
inifile.arg
} -maxleftover 0]
if {[info exists opts(inifile)]} {
WritePrivateProfileString $section $key $twapi::nullptr $opts(inifile)
} else {
WriteProfileString $section $key $twapi::nullptr
}
}
proc twapi::read_inifile_section_names {args} {
array set opts [parseargs args {
inifile.arg
} -nulldefault -maxleftover 0]
return [GetPrivateProfileSectionNames $opts(inifile)]
}
proc twapi::read_inifile_section {section args} {
array set opts [parseargs args {
inifile.arg
} -nulldefault -maxleftover 0]
set result [list ]
foreach line [GetPrivateProfileSection $section $opts(inifile)] {
set pos [string first "=" $line]
if {$pos >= 0} {
lappend result [string range $line 0 [expr {$pos-1}]] [string range $line [incr pos] end]
}
}
return $result
}
proc twapi::delete_inifile_section {section args} {
variable nullptr
array set opts [parseargs args {
inifile.arg
}]
if {[info exists opts(inifile)]} {
WritePrivateProfileString $section $nullptr $nullptr $opts(inifile)
} else {
WriteProfileString $section $nullptr $nullptr
}
}
proc twapi::get_primary_domain_controller {args} {
array set opts [parseargs args {system.arg domain.arg} -nulldefault -maxleftover 0]
if {[string length $opts(system)]} {
set opts(system) "\\\\[string trimleft \\]"
}
return [NetGetDCName $opts(system) $opts(domain)]
}
proc twapi::find_domain_controller {args} {
array set opts [parseargs args {
system.arg
avoidself.bool
domain.arg
domainguid.arg
site.arg
rediscover.bool
allowstale.bool
require.arg
prefer.arg
justldap.bool
{inputnameformat.arg any {dns flat any}}
{outputnameformat.arg any {dns flat any}}
{outputaddrformat.arg any {ip netbios any}}
getdetails
} -maxleftover 0 -nulldefault]
set flags 0
if {$opts(outputaddrformat) eq "ip"} {
setbits flags 0x200
}
foreach req $opts(require) {
if {[string is integer $req]} {
setbits flags $req
} else {
switch -exact -- $req {
directoryservice { setbits flags 0x10 }
globalcatalog    { setbits flags 0x40 }
pdc              { setbits flags 0x80 }
kdc              { setbits flags 0x400 }
timeserver       { setbits flags 0x800 }
writable         { setbits flags 0x1000 }
default {
error "Invalid token '$req' specified in value for option '-require'"
}
}
}
}
foreach req $opts(prefer) {
if {[string is integer $req]} {
setbits flags $req
} else {
switch -exact -- $req {
directoryservice {
if {! ($flags & 0x10)} {
setbits flags 0x20
}
}
timeserver {
if {! ($flags & 0x800)} {
setbits flags 0x2000
}
}
default {
error "Invalid token '$req' specified in value for option '-prefer'"
}
}
}
}
if {$opts(rediscover)} {
setbits flags 0x1
} else {
if {$opts(allowstale)} {
setbits flags 0x100
}
}
if {$opts(avoidself)} {
setbits flags 0x4000
}
if {$opts(justldap)} {
setbits flags 0x8000
}
switch -exact -- $opts(inputnameformat) {
any  { }
flat { setbits flags 0x10000 }
dns  { setbits flags 0x20000 }
default {
error "Invalid value '$opts(inputnameformat)' for option '-inputnameformat'"
}
}
switch -exact -- $opts(outputnameformat) {
any  { }
flat { setbits flags 0x80000000 }
dns  { setbits flags 0x40000000 }
default {
error "Invalid value '$opts(outputnameformat)' for option '-outputnameformat'"
}
}
array set dcinfo [DsGetDcName $opts(system) $opts(domain) $opts(domainguid) $opts(site) $flags]
if {! $opts(getdetails)} {
return $dcinfo(DomainControllerName)
}
set result [list \
-dcname $dcinfo(DomainControllerName) \
-dcaddr [string trimleft $dcinfo(DomainControllerAddress) \\] \
-domainguid $dcinfo(DomainGuid) \
-domain $dcinfo(DomainName) \
-dnsforest $dcinfo(DnsForestName) \
-dcsite $dcinfo(DcSiteName) \
-clientsite $dcinfo(ClientSiteName) \
]
if {$dcinfo(DomainControllerAddressType) == 1} {
lappend result -dcaddrformat ip
} else {
lappend result -dcaddrformat netbios
}
if {$dcinfo(Flags) & 0x20000000} {
lappend result -dcnameformat dns
} else {
lappend result -dcnameformat netbios
}
if {$dcinfo(Flags) & 0x40000000} {
lappend result -domainformat dns
} else {
lappend result -domainformat netbios
}
if {$dcinfo(Flags) & 0x80000000} {
lappend result -dnsforestformat dns
} else {
lappend result -dnsforestformat netbios
}
set features [list ]
foreach {flag feature} {
0x1    pdc
0x4    globalcatalog
0x8    ldap
0x10   directoryservice
0x20   kdc
0x40   timeserver
0x80   closest
0x100  writable
0x200  goodtimeserver
} {
if {$dcinfo(Flags) & $flag} {
lappend features $feature
}
}
lappend result -features $features
return $result
}
proc twapi::get_primary_domain_info {args} {
array set opts [parseargs args {
all
name
dnsdomainname
dnsforestname
domainguid
sid
type
} -maxleftover 0]
set result [list ]
set lsah [get_lsa_policy_handle -access policy_view_local_information]
try {
foreach {name dnsdomainname dnsforestname domainguid sid} [Twapi_LsaQueryInformationPolicy $lsah 12] break
if {[string length $sid] == 0} {
set type workgroup
set domainguid ""
} else {
set type domain
}
foreach opt {name dnsdomainname dnsforestname domainguid sid type} {
if {$opts(all) || $opts($opt)} {
lappend result -$opt [set $opt]
}
}
} finally {
close_lsa_policy_handle $lsah
}
return $result
}
proc twapi::get_tcl_channel_handle {chan direction} {
set direction [expr {[string equal $direction "write"] ? 1 : 0}]
return [Tcl_GetChannelHandle $chan $direction]
}
proc twapi::duplicate_handle {h args} {
variable my_process_handle
array set opts [parseargs args {
sourcepid.int
targetpid.int
access.arg
inherit
closesource
} -maxleftover 0]
set source_ph $my_process_handle
set target_ph $my_process_handle
if {![string is integer $h]} {
set h [HANDLE2ADDRESS_LITERAL $h]
}
try {
set me [pid]
if {[info exists opts(sourcepid)] && $opts(sourcepid) != $me} {
set source_ph [get_process_handle $opts(sourcepid) -access process_dup_handle]
}
if {[info exists opts(targetpid)] && $opts(targetpid) != $me} {
set target_ph [get_process_handle $opts(targetpid) -access process_dup_handle]
}
set flags [expr {$opts(closesource) ? 0x1: 0}]
if {[info exists opts(access)]} {
set access [_access_rights_to_mask $opts(access)]
} else {
set access 0
set flags [expr {$flags | 0x2}]; # DUPLICATE_SAME_ACCESS
}
set dup [DuplicateHandle $source_ph $h $target_ph $access $opts(inherit) $flags]
if {![info exists opts(targetpid)]} {
set dup [ADDRESS_LITERAL2HANDLE $dup]
}
} finally {
if {$source_ph != $my_process_handle} {
close_handles $source_ph
}
if {$target_ph != $my_process_handle} {
close_handles $source_ph
}
}
return $dup
}
proc twapi::get_system_parameters_info {uiaction} {
variable SystemParametersInfo_uiactions_get
if {![info exists SystemParametersInfo_uiactions_get]} {
array set SystemParametersInfo_uiactions_get {
SPI_GETDESKWALLPAPER {0x0073 2048 unicode 4096}
SPI_GETBEEP  {0x0001 0 i 4}
SPI_GETMOUSE {0x0003 0 i3 12}
SPI_GETBORDER {0x0005 0 i 4}
SPI_GETKEYBOARDSPEED {0x000A 0 i 4}
SPI_ICONHORIZONTALSPACING {0x000D 0 i 4}
SPI_GETSCREENSAVETIMEOUT {0x000E 0 i 4}
SPI_GETSCREENSAVEACTIVE {0x0010 0 i 4}
SPI_GETKEYBOARDDELAY {0x0016 0 i 4}
SPI_ICONVERTICALSPACING {0x0018 0 i 4}
SPI_GETICONTITLEWRAP {0x0019 0 i 4}
SPI_GETMENUDROPALIGNMENT {0x001B 0 i 4}
SPI_GETDRAGFULLWINDOWS {0x0026 0 i 4}
SPI_GETMINIMIZEDMETRICS {0x002B sz i5 20 cbsize}
SPI_GETWORKAREA {0x0030 0 i4 16}
SPI_GETKEYBOARDPREF {0x0044 0 i 4 }
SPI_GETSCREENREADER {0x0046 0 i 4}
SPI_GETANIMATION {0x0048 sz i2 8 cbsize}
SPI_GETFONTSMOOTHING {0x004A 0 i 4}
SPI_GETLOWPOWERTIMEOUT {0x004F 0 i 4}
SPI_GETPOWEROFFTIMEOUT {0x0050 0 i 4}
SPI_GETLOWPOWERACTIVE {0x0053 0 i 4}
SPI_GETPOWEROFFACTIVE {0x0054 0 i 4}
SPI_GETMOUSETRAILS {0x005E 0 i 4}
SPI_GETSCREENSAVERRUNNING {0x0072 0 i 4}
SPI_GETFILTERKEYS {0x0032 sz i6 24 cbsize}
SPI_GETTOGGLEKEYS {0x0034 sz i2 8 cbsize}
SPI_GETMOUSEKEYS {0x0036 sz i7 28 cbsize}
SPI_GETSHOWSOUNDS {0x0038 0 i 4}
SPI_GETSTICKYKEYS {0x003A sz i2 8 cbsize}
SPI_GETACCESSTIMEOUT {0x003C 12 i3 12 cbsize}
SPI_GETSNAPTODEFBUTTON {0x005F 0 i 4}
SPI_GETMOUSEHOVERWIDTH {0x0062 0 i 4}
SPI_GETMOUSEHOVERHEIGHT {0x0064 0 i 4 }
SPI_GETMOUSEHOVERTIME {0x0066 0 i 4}
SPI_GETWHEELSCROLLLINES {0x0068 0 i 4}
SPI_GETMENUSHOWDELAY {0x006A 0 i 4}
SPI_GETSHOWIMEUI {0x006E 0 i 4}
SPI_GETMOUSESPEED {0x0070 0 i 4}
SPI_GETACTIVEWINDOWTRACKING {0x1000 0 i 4}
SPI_GETMENUANIMATION {0x1002 0 i 4}
SPI_GETCOMBOBOXANIMATION {0x1004 0 i 4}
SPI_GETLISTBOXSMOOTHSCROLLING {0x1006 0 i 4}
SPI_GETGRADIENTCAPTIONS {0x1008 0 i 4}
SPI_GETKEYBOARDCUES {0x100A 0 i 4}
SPI_GETMENUUNDERLINES            {0x100A 0 i 4}
SPI_GETACTIVEWNDTRKZORDER {0x100C 0 i 4}
SPI_GETHOTTRACKING {0x100E 0 i 4}
SPI_GETMENUFADE {0x1012 0 i 4}
SPI_GETSELECTIONFADE {0x1014 0 i 4}
SPI_GETTOOLTIPANIMATION {0x1016 0 i 4}
SPI_GETTOOLTIPFADE {0x1018 0 i 4}
SPI_GETCURSORSHADOW {0x101A 0 i 4}
SPI_GETMOUSESONAR {0x101C 0 i 4 }
SPI_GETMOUSECLICKLOCK {0x101E 0 i 4}
SPI_GETMOUSEVANISH {0x1020 0 i 4}
SPI_GETFLATMENU {0x1022 0 i 4}
SPI_GETDROPSHADOW {0x1024 0 i 4}
SPI_GETBLOCKSENDINPUTRESETS {0x1026 0 i 4}
SPI_GETUIEFFECTS {0x103E 0 i 4}
SPI_GETFOREGROUNDLOCKTIMEOUT {0x2000 0 i 4}
SPI_GETACTIVEWNDTRKTIMEOUT {0x2002 0 i 4}
SPI_GETFOREGROUNDFLASHCOUNT {0x2004 0 i 4}
SPI_GETCARETWIDTH {0x2006 0 i 4}
SPI_GETMOUSECLICKLOCKTIME {0x2008 0 i 4}
SPI_GETFONTSMOOTHINGTYPE {0x200A 0 i 4}
SPI_GETFONTSMOOTHINGCONTRAST {0x200C 0 i 4}
SPI_GETFOCUSBORDERWIDTH {0x200E 0 i 4}
SPI_GETFOCUSBORDERHEIGHT {0x2010 0 i 4}
}
}
set key [string toupper $uiaction]
if {![info exists SystemParametersInfo_uiactions_get($key)]} {
set key SPI_$key
if {![info exists SystemParametersInfo_uiactions_get($key)]} {
error "Unknown SystemParametersInfo index symbol '$uiaction'"
}
}
foreach {index uiparam fmt sz modifiers} $SystemParametersInfo_uiactions_get($key) break
if {$uiparam eq "sz"} {
set uiparam $sz
}
set mem [malloc $sz]
try {
if {[lsearch -exact $modifiers cbsize] >= 0} {
Twapi_WriteMemoryBinary $mem 0 $sz [binary format i $sz]
}
SystemParametersInfo $index $uiparam $mem 0
if {$fmt eq "unicode"} {
set val [Twapi_ReadMemoryUnicode $mem 0]
} else {
binary scan [Twapi_ReadMemoryBinary $mem 0 $sz] $fmt val
}
} finally {
free $mem
}
return $val
}
proc twapi::set_system_parameters_info {uiaction val args} {
variable SystemParametersInfo_uiactions_set
if {![info exists SystemParametersInfo_uiactions_set]} {
array set SystemParametersInfo_uiactions_set {
SPI_SETBEEP                 {0x0002 bool}
SPI_SETMOUSE                {0x0004 unsupported}
SPI_SETBORDER               {0x0006 int}
SPI_SETKEYBOARDSPEED        {0x000B int}
SPI_ICONHORIZONTALSPACING   {0x000D int}
SPI_SETSCREENSAVETIMEOUT    {0x000F int}
SPI_SETSCREENSAVEACTIVE     {0x0011 bool}
SPI_SETDESKWALLPAPER        {0x0014 unsupported}
SPI_SETDESKPATTERN          {0x0015 int}
SPI_SETKEYBOARDDELAY        {0x0017 int}
SPI_ICONVERTICALSPACING     {0x0018 int}
SPI_SETICONTITLEWRAP        {0x001A bool}
SPI_SETMENUDROPALIGNMENT    {0x001C bool}
SPI_SETDOUBLECLKWIDTH       {0x001D int}
SPI_SETDOUBLECLKHEIGHT      {0x001E int}
SPI_SETDOUBLECLICKTIME      {0x0020 int}
SPI_SETMOUSEBUTTONSWAP      {0x0021 bool}
SPI_SETICONTITLELOGFONT     {0x0022 LOGFONT}
SPI_SETDRAGFULLWINDOWS      {0x0025 bool}
SPI_SETNONCLIENTMETRICS     {0x002A NONCLIENTMETRICS}
SPI_SETMINIMIZEDMETRICS     {0x002C MINIMIZEDMETRICS}
SPI_SETICONMETRICS          {0x002E ICONMETRICS}
SPI_SETWORKAREA             {0x002F RECT}
SPI_SETPENWINDOWS           {0x0031}
SPI_SETHIGHCONTRAST         {0x0043 HIGHCONTRAST}
SPI_SETKEYBOARDPREF         {0x0045 bool}
SPI_SETSCREENREADER         {0x0047 bool}
SPI_SETANIMATION            {0x0049 ANIMATIONINFO}
SPI_SETFONTSMOOTHING        {0x004B bool}
SPI_SETDRAGWIDTH            {0x004C int}
SPI_SETDRAGHEIGHT           {0x004D int}
SPI_SETHANDHELD             {0x004E}
SPI_SETLOWPOWERTIMEOUT      {0x0051 int}
SPI_SETPOWEROFFTIMEOUT      {0x0052 int}
SPI_SETLOWPOWERACTIVE       {0x0055 bool}
SPI_SETPOWEROFFACTIVE       {0x0056 bool}
SPI_SETCURSORS              {0x0057 int}
SPI_SETICONS                {0x0058 int}
SPI_SETDEFAULTINPUTLANG     {0x005A HKL}
SPI_SETLANGTOGGLE           {0x005B int}
SPI_SETMOUSETRAILS          {0x005D int}
SPI_SETFILTERKEYS          {0x0033 FILTERKEYS}
SPI_SETTOGGLEKEYS          {0x0035 TOGGLEKEYS}
SPI_SETMOUSEKEYS           {0x0037 MOUSEKEYS}
SPI_SETSHOWSOUNDS          {0x0039 bool}
SPI_SETSTICKYKEYS          {0x003B STICKYKEYS}
SPI_SETACCESSTIMEOUT       {0x003D ACCESSTIMEOUT}
SPI_SETSERIALKEYS          {0x003F SERIALKEYS}
SPI_SETSOUNDSENTRY         {0x0041 SOUNDSENTRY}
SPI_SETSNAPTODEFBUTTON     {0x0060 bool}
SPI_SETMOUSEHOVERWIDTH     {0x0063 int}
SPI_SETMOUSEHOVERHEIGHT    {0x0065 int}
SPI_SETMOUSEHOVERTIME      {0x0067 int}
SPI_SETWHEELSCROLLLINES    {0x0069 int}
SPI_SETMENUSHOWDELAY       {0x006B int}
SPI_SETSHOWIMEUI          {0x006F bool}
SPI_SETMOUSESPEED         {0x0071 castint}
SPI_SETACTIVEWINDOWTRACKING         {0x1001 castbool}
SPI_SETMENUANIMATION                {0x1003 castbool}
SPI_SETCOMBOBOXANIMATION            {0x1005 castbool}
SPI_SETLISTBOXSMOOTHSCROLLING       {0x1007 castbool}
SPI_SETGRADIENTCAPTIONS             {0x1009 castbool}
SPI_SETKEYBOARDCUES                 {0x100B castbool}
SPI_SETMENUUNDERLINES               {0x100B castbool}
SPI_SETACTIVEWNDTRKZORDER           {0x100D castbool}
SPI_SETHOTTRACKING                  {0x100F castbool}
SPI_SETMENUFADE                     {0x1013 castbool}
SPI_SETSELECTIONFADE                {0x1015 castbool}
SPI_SETTOOLTIPANIMATION             {0x1017 castbool}
SPI_SETTOOLTIPFADE                  {0x1019 castbool}
SPI_SETCURSORSHADOW                 {0x101B castbool}
SPI_SETMOUSESONAR                   {0x101D castbool}
SPI_SETMOUSECLICKLOCK               {0x101F bool}
SPI_SETMOUSEVANISH                  {0x1021 castbool}
SPI_SETFLATMENU                     {0x1023 castbool}
SPI_SETDROPSHADOW                   {0x1025 castbool}
SPI_SETBLOCKSENDINPUTRESETS         {0x1027 bool}
SPI_SETUIEFFECTS                    {0x103F castbool}
SPI_SETFOREGROUNDLOCKTIMEOUT        {0x2001 castint}
SPI_SETACTIVEWNDTRKTIMEOUT          {0x2003 castint}
SPI_SETFOREGROUNDFLASHCOUNT         {0x2005 castint}
SPI_SETCARETWIDTH                   {0x2007 castint}
SPI_SETMOUSECLICKLOCKTIME           {0x2009 int}
SPI_SETFONTSMOOTHINGTYPE            {0x200B castint}
SPI_SETFONTSMOOTHINGCONTRAST        {0x200D unsupported}
SPI_SETFOCUSBORDERWIDTH             {0x200F castint}
SPI_SETFOCUSBORDERHEIGHT            {0x2011 castint}
}
}
array set opts [parseargs args {
persist
notify
} -nulldefault]
set flags 0
if {$opts(persist)} {
setbits flags 1
}
if {$opts(notify)} {
setbits flags 2
}
set key [string toupper $uiaction]
if {![info exists SystemParametersInfo_uiactions_set($key)]} {
set key SPI_$key
if {![info exists SystemParametersInfo_uiactions_set($key)]} {
error "Unknown SystemParametersInfo index symbol '$uiaction'"
}
}
foreach {index fmt} $SystemParametersInfo_uiactions_set($key) break
switch -exact -- $fmt {
int  { SystemParametersInfo $index $val NULL $flags }
bool {
set val [expr {$val ? 1 : 0}]
SystemParametersInfo $index $val NULL $flags
}
castint {
SystemParametersInfo $index 0 [Twapi_AddressToPointer $val] $flags
}
castbool {
set val [expr {$val ? 1 : 0}]
SystemParametersInfo $index 0 [Twapi_AddressToPointer $val] $flags
}
default {
error "The data format for $uiaction is not currently supported"
}
}
return
}
proc twapi::_unsafe_format_message {args} {
array set opts [parseargs args {
module.arg
fmtstring.arg
messageid.arg
langid.arg
params.arg
includesystem
ignoreinserts
width.int
} -nulldefault]
set flags 0
if {$opts(module) == ""} {
if {$opts(fmtstring) == ""} {
set opts(module) null
setbits flags 0x1000;       # FORMAT_MESSAGE_FROM_SYSTEM
} else {
setbits flags 0x400;        # FORMAT_MESSAGE_FROM_STRING
if {$opts(includesystem) || $opts(messageid) != "" || $opts(langid) != ""} {
error "Options -includesystem, -messageid and -langid cannot be used with -fmtstring"
}
}
} else {
if {$opts(fmtstring) != ""} {
error "Options -fmtstring and -module cannot be used together"
}
setbits flags 0x800;        # FORMAT_MESSAGE_FROM_HMODULE
if {$opts(includesystem)} {
setbits flags 0x1000;       # FORMAT_MESSAGE_FROM_SYSTEM
}
}
if {$opts(ignoreinserts)} {
setbits flags 0x200;            # FORMAT_MESSAGE_IGNORE_INSERTS
}
if {$opts(width) > 254} {
error "Invalid value for option -width. Must be -1, 0, or a positive integer less than 255"
}
if {$opts(width) < 0} {
set opts(width) 255;                  # 255 -> no restrictions
}
incr flags $opts(width);                  # Width goes in low byte of flags
if {$opts(fmtstring) != ""} {
return [FormatMessageFromString $flags $opts(fmtstring) $opts(params)]
} else {
if {![string is integer -strict $opts(messageid)]} {
error "Unspecified or invalid value for -messageid option. Must be an integer value"
}
if {$opts(langid) == ""} { set opts(langid) 0 }
if {![string is integer -strict $opts(langid)]} {
error "Unspecfied or invalid value for -langid option. Must be an integer value"
}
if {[_is_swig_ptr $opts(module)]} {
return  [FormatMessageFromModule $flags $opts(module) \
$opts(messageid) $opts(langid) $opts(params)]
} else {
set hmod [load_library $opts(module) -datafile]
try {
set message  [FormatMessageFromModule $flags $hmod \
$opts(messageid) $opts(langid) $opts(params)]
} finally {
free_library $hmod
}
return $message
}
}
}
#-- from pdh.tcl
namespace eval twapi {
}
proc twapi::get_perf_objects {args} {
variable windefs
array set opts [parseargs args {
datasource.arg
machine.arg
{detail.arg wizard}
refresh
} -nulldefault]
if {[string length $opts(datasource)] && ![min_os_version 5 0]} {
error "Option -datasource is invalid on Windows NT 4.0 platforms"
}
set detail_index "PERF_DETAIL_[string toupper $opts(detail)]"
if {![info exists windefs($detail_index)]} {
error "Invalid value '$opts(detail)' specified for -detail option"
}
return [PdhEnumObjects $opts(datasource) $opts(machine) \
$windefs($detail_index) $opts(refresh)]
}
proc twapi::get_perf_object_items {objname args} {
variable windefs
array set opts [parseargs args {
datasource.arg
machine.arg
{detail.arg wizard}
refresh
} -nulldefault]
if {[string length $opts(datasource)] && ![min_os_version 5 0]} {
error "Option -datasource is invalid on Windows NT 4.0 platforms"
}
set detail_index "PERF_DETAIL_[string toupper $opts(detail)]"
if {![info exists windefs($detail_index)]} {
error "Invalid value '$opts(detail)' specified for -detail option"
}
if {$opts(refresh)} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
return [PdhEnumObjectItems $opts(datasource) $opts(machine) \
$objname $windefs($detail_index) 0]
}
proc twapi::connect_perf {machine} {
PdhConnectMachine($machine)
}
proc twapi::make_perf_counter_path {object counter args} {
array set opts [parseargs args {
machine.arg
instance.arg
parent.arg
instanceindex.int
{localize.bool false}
} -nulldefault]
if {$opts(instanceindex) < -1} {
error "Invalid value '$opts(instanceindex)' specified for -instanceindex option"
}
if {$opts(localize)} {
set object [_localize_perf_counter $object]
set counter [_localize_perf_counter $counter]
set opts(parent) [_localize_perf_counter $opts(parent)]
}
return [PdhMakeCounterPath $opts(machine) $object $opts(instance) \
$opts(parent) $opts(instanceindex) $counter 0]
}
proc twapi::parse_perf_counter_path {counter_path} {
array set counter_elems [PdhParseCounterPath $counter_path 0]
lappend result machine       $counter_elems(szMachineName)
lappend result object        $counter_elems(szObjectName)
lappend result instance      $counter_elems(szInstanceName)
lappend result instanceindex $counter_elems(dwInstanceIndex)
lappend result parent        $counter_elems(szParentInstance)
lappend result counter       $counter_elems(szCounterName)
return $result
}
proc twapi::validate_perf_counter_path {counter_path} {
PdhValidatePath $counter_path
}
proc twapi::open_perf_query {args} {
array set opts [parseargs args {
datasource.arg
cookie.int
} -nulldefault]
if {[string length $opts(datasource)] && ![min_os_version 5 0]} {
error "Option -datasource is invalid on Windows NT 4.0 platforms"
}
if {! [string is integer -strict $opts(cookie)]} {
error "Non-integer value '$opts(cookie)' specified for -cookie option"
}
return [PdhOpenQuery $opts(datasource) $opts(cookie)]
}
proc twapi::close_perf_query {hquery} {
PdhCloseQuery $hquery
}
proc twapi::add_perf_counter {hquery counter_path args} {
array set opts [parseargs args {
cookie.int
} -nulldefault]
set hcounter [PdhAddCounter $hquery $counter_path $opts(cookie)]
return $hcounter
}
proc twapi::remove_perf_counter {hcounter} {
PdhRemoveCounter $hcounter
}
proc twapi::collect_perf_query_data {hquery} {
PdhCollectQueryData $hquery
}
proc twapi::get_hcounter_value {hcounter args} {
variable windefs
array set opts [parseargs args {
{format.arg long {long large double}}
scale.arg
var.arg
full.bool
} -nulldefault]
set format $windefs(PDH_FMT_[string toupper $opts(format)])
switch -exact -- $opts(scale) {
""        { set scale 0 }
none      { set scale $windefs(PDH_FMT_NOSCALE) }
nocap     { set scale $windefs(PDH_FMT_NOCAP) }
x1000     { set scale $windefs(PDH_FMT_1000) }
default {
error "Invalid value '$opts(scale)' specified for -scale option"
}
}
set flags [expr {$format | $scale}]
set status 1
set result ""
try {
set result [PdhGetFormattedCounterValue $hcounter $flags]
} onerror {TWAPI_WIN32 0x800007d1} {
if {[string length $opts(var)] == 0} {
error $errorResult $errorInfo $errorCode
}
set status 0
}
if {! $opts(full)} {
set result [lindex $result 0]
}
if {[string length $opts(var)]} {
uplevel [list set $opts(var) $result]
return $status
} else {
return $result
}
}
proc twapi::get_counter_path_value {counter_path args} {
variable windefs
array set opts [parseargs args {
interval.int
{format.arg long}
scale.arg
datasource.arg
var.arg
full.bool
} -nulldefault]
if {$opts(interval) < 0} {
error "Negative value '$opts(interval)' specified for option -interval"
}
set hquery [open_perf_query -datasource $opts(datasource)]
try {
set hcounter [add_perf_counter $hquery $counter_path]
collect_perf_query_data $hquery
if {$opts(interval)} {
after $opts(interval)
collect_perf_query_data $hquery
}
if {[string length $opts(var)]} {
upvar $opts(var) myvar
set opts(var) myvar
}
set value [get_hcounter_value $hcounter -format $opts(format) \
-scale $opts(scale) -full $opts(full) \
-var $opts(var)]
} finally {
if {[info exists hcounter]} {
remove_perf_counter $hcounter
}
close_perf_query $hquery
}
return $value
}
proc twapi::get_perf_process_counter_paths {pids args} {
variable _process_counter_opt_map
if {![info exists _counter_opt_map]} {
array set _process_counter_opt_map {
privilegedutilization {"% Privileged Time"   double 1}
processorutilization  {"% Processor Time"    double 1}
userutilization       {"% User Time"         double 1}
parent                {"Creating Process ID" long   0}
elapsedtime           {"Elapsed Time"        large  0}
handlecount           {"Handle Count"        long   0}
pid                   {"ID Process"          long   0}
iodatabytesrate       {"IO Data Bytes/sec"   large  1}
iodataopsrate         {"IO Data Operations/sec"  large 1}
iootherbytesrate      {"IO Other Bytes/sec"      large 1}
iootheropsrate        {"IO Other Operations/sec" large 1}
ioreadbytesrate       {"IO Read Bytes/sec"       large 1}
ioreadopsrate         {"IO Read Operations/sec"  large 1}
iowritebytesrate      {"IO Write Bytes/sec"      large 1}
iowriteopsrate        {"IO Write Operations/sec" large 1}
pagefaultrate         {"Page Faults/sec"         large 0}
pagefilebytes         {"Page File Bytes"         large 0}
pagefilebytespeak     {"Page File Bytes Peak"    large 0}
poolnonpagedbytes     {"Pool Nonpaged Bytes"     large 0}
poolpagedbytes        {"Pool Paged Bytes"        large 1}
basepriority          {"Priority Base"           large 1}
privatebytes          {"Private Bytes"           large 1}
threadcount           {"Thread Count"            large 1}
virtualbytes          {"Virtual Bytes"           large 1}
virtualbytespeak      {"Virtual Bytes Peak"      large 1}
workingset            {"Working Set"             large 1}
workingsetpeak        {"Working Set Peak"        large 1}
}
}
set optdefs {
machine.arg
datasource.arg
all
refresh
}
foreach cntr [array names _process_counter_opt_map] {
lappend optdefs $cntr
}
array set opts [parseargs args $optdefs -nulldefault]
if {$opts(refresh)} {
if {0} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
}
set pid_paths [get_perf_counter_paths \
[_localize_perf_counter "Process"] \
[list [_localize_perf_counter "ID Process"]] \
$pids \
-machine $opts(machine) -datasource $opts(datasource) \
-all]
if {[llength $pid_paths] == 0} {
return [list ]
}
set counter_paths [list ]
foreach {pid pid_path} $pid_paths {
if {$pid == 0 && [string match -nocase *_Total\#0* $pid_path]} {
continue
}
array set path_components [parse_perf_counter_path $pid_path]
foreach {opt counter_info} [array get _process_counter_opt_map] {
if {$opts(all) || $opts($opt)} {
lappend counter_paths \
[list -$opt $pid [lindex $counter_info 1] \
[make_perf_counter_path $path_components(object) \
[_localize_perf_counter [lindex $counter_info 0]] \
-machine $path_components(machine) \
-parent $path_components(parent) \
-instance $path_components(instance) \
-instanceindex $path_components(instanceindex)] \
[lindex $counter_info 2] \
]
}
}                        
}
return $counter_paths
}
proc twapi::get_perf_process_id_path {pid args} {
return [get_unique_counter_path \
[_localize_perf_counter "Process"] \
[_localize_perf_counter "ID Process"] $pid]
}
proc twapi::get_perf_thread_counter_paths {tids args} {
variable _thread_counter_opt_map
if {![info exists _thread_counter_opt_map]} {
array set _thread_counter_opt_map {
privilegedutilization {"% Privileged Time"       double 1}
processorutilization  {"% Processor Time"        double 1}
userutilization       {"% User Time"             double 1}
contextswitchrate     {"Context Switches/sec"    long 1}
elapsedtime           {"Elapsed Time"            large 0}
pid                   {"ID Process"              long 0}
tid                   {"ID Thread"               long 0}
basepriority          {"Priority Base"           long 0}
priority              {"Priority Current"        long 0}
startaddress          {"Start Address"           large 0}
state                 {"Thread State"            long 0}
waitreason            {"Thread Wait Reason"      long 0}
}
}
set optdefs {
machine.arg
datasource.arg
all
refresh
}
foreach cntr [array names _thread_counter_opt_map] {
lappend optdefs $cntr
}
array set opts [parseargs args $optdefs -nulldefault]
if {$opts(refresh)} {
if {0} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
}
set tid_paths [get_perf_counter_paths \
[_localize_perf_counter "Thread"] \
[list [_localize_perf_counter "ID Thread"]] \
$tids \
-machine $opts(machine) -datasource $opts(datasource) \
-all]
if {[llength $tid_paths] == 0} {
return [list ]
}
set counter_paths [list ]
foreach {tid tid_path} $tid_paths {
array set path_components [parse_perf_counter_path $tid_path]
foreach {opt counter_info} [array get _thread_counter_opt_map] {
if {$opts(all) || $opts($opt)} {
lappend counter_paths \
[list -$opt $tid [lindex $counter_info 1] \
[make_perf_counter_path $path_components(object) \
[_localize_perf_counter [lindex $counter_info 0]] \
-machine $path_components(machine) \
-parent $path_components(parent) \
-instance $path_components(instance) \
-instanceindex $path_components(instanceindex)] \
[lindex $counter_info 2]
]
}
}                            
}
return $counter_paths
}
proc twapi::get_perf_thread_id_path {tid args} {
return [get_unique_counter_path [_localize_perf_counter"Thread"] [_localize_perf_counter "ID Thread"] $tid]
}
proc twapi::get_perf_processor_counter_paths {processor args} {
variable _processor_counter_opt_map
if {![string is integer -strict $processor]} {
if {[string length $processor]} {
error "Processor id must be an integer or null to retrieve information for all processors"
}
set processor "_Total"
}
if {![info exists _processor_counter_opt_map]} {
array set _processor_counter_opt_map {
dpcutilization        {"% DPC Time"              double 1}
interruptutilization  {"% Interrupt Time"        double 1}
privilegedutilization {"% Privileged Time"       double 1}
processorutilization  {"% Processor Time"        double 1}
userutilization       {"% User Time"             double 1}
apcbypassrate         {"APC Bypasses/sec"        double 1}
dpcbypassrate         {"DPC Bypasses/sec"        double 1}
dpcrate               {"DPC Rate"                double 1}
dpcqueuerate          {"DPCs Queued/sec"         double 1}
interruptrate         {"Interrupts/sec"          double 1}
}
}
set optdefs {
machine.arg
datasource.arg
all
refresh
}
foreach cntr [array names _processor_counter_opt_map] {
lappend optdefs $cntr
}
array set opts [parseargs args $optdefs -nulldefault -maxleftover 0]
if {$opts(refresh)} {
if {0} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
}
set counter_paths [list ]
foreach {opt counter_info} [array get _processor_counter_opt_map] {
if {$opts(all) || $opts($opt)} {
lappend counter_paths \
[list $opt $processor [lindex $counter_info 1] \
[make_perf_counter_path \
[_localize_perf_counter "Processor"] \
[_localize_perf_counter [lindex $counter_info 0]] \
-machine $opts(machine) \
-instance $processor] \
[lindex $counter_info 2] \
]
}
}
return $counter_paths
}
proc twapi::get_perf_instance_counter_paths {object counters
key_counter key_counter_values
args} {
array set opts [parseargs args {
machine.arg
datasource.arg
{matchop.arg "exact"}
skiptotal.bool
refresh
} -nulldefault]
if {$opts(refresh)} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
set instance_paths [get_perf_counter_paths $object \
[list $key_counter] $key_counter_values \
-machine $opts(machine) \
-datasource $opts(datasource) \
-matchop $opts(matchop) \
-skiptotal $opts(skiptotal) \
-all]
array set counter_paths {}
foreach {key_counter_value instance_path} $instance_paths {
array set path_components [parse_perf_counter_path $instance_path]
foreach counter $counters {
set counter_path \
[make_perf_counter_path $path_components(object) \
$counter \
-machine $path_components(machine) \
-parent $path_components(parent) \
-instance $path_components(instance) \
-instanceindex $path_components(instanceindex)]
set counter_paths($counter_path) ""
}                            
}
return [array names counter_paths]
}
proc twapi::get_perf_counter_paths {object counters counter_values args} {
array set opts [parseargs args {
machine.arg
datasource.arg
{matchop.arg "exact"}
skiptotal.bool
all
refresh
} -nulldefault]
if {$opts(refresh)} {
_refresh_perf_objects $opts(machine) $opts(datasource)
}
set items [get_perf_object_items $object \
-machine $opts(machine) \
-datasource $opts(datasource)]
foreach {object_counters object_instances} $items {break}
if {[llength $counters]} {
set object_counters $counters
}
set paths [_make_counter_path_list \
$object $object_instances $object_counters \
-skiptotal $opts(skiptotal) -machine $opts(machine)]
set result_paths [list ]
try {
set hquery [open_perf_query -datasource $opts(datasource)]
foreach path $paths {
set hcounter [add_perf_counter $hquery $path]
set lookup($hcounter) $path
}
collect_perf_query_data $hquery
foreach hcounter [array names lookup] {
if {! [get_hcounter_value $hcounter -var value]} {
continue
}
set match_pos [lsearch -$opts(matchop) $counter_values $value]
if {$match_pos >= 0} {
lappend result_paths \
[lindex $counter_values $match_pos] $lookup($hcounter)
if {! $opts(all)} {
break
}
}
}
} finally {
foreach hcounter [array names lookup] {
remove_perf_counter $hcounter
}
close_perf_query $hquery
}
return $result_paths
}
proc twapi::get_unique_counter_path {object counter value args} {
set matches [eval [list get_perf_counter_paths $object [list $counter ] [list $value]] $args -all]
if {[llength $matches] > 1} {
error "Multiple counter paths found matching criteria object='$object' counter='$counter' value='$value"
}
return [lindex $matches 0]
}
proc twapi::_refresh_perf_objects {machine datasource} {
get_perf_objects -refresh
return
}
proc twapi::_localize_perf_counter {name} {
variable _perf_counter_ids
variable _localized_perf_counter_names
set name_index [string tolower $name]
if {[info exists _localized_perf_counter_names($name_index)]} {
return $_localized_perf_counter_names($name_index)
}
if {! [min_os_version 5]} {
set _localized_perf_counter_names($name_index) $name
return $name
}
if {![info exists _perf_counter_ids]} {
foreach {id label} [registry get {HKEY_PERFORMANCE_DATA} {Counter 009}] {
set _perf_counter_ids([string tolower $label]) $id
}
}
if {! [info exists _perf_counter_ids($name_index)]} {
return [set _localized_perf_counter_names($name_index) $name]
}
if {[catch {PdhLookupPerfNameByIndex "" $_perf_counter_ids($name_index)} xname]} {
set _localized_perf_counter_names($name_index) $name
} else {
set _localized_perf_counter_names($name_index) $xname
}
return $_localized_perf_counter_names($name_index)
}
proc twapi::_make_counter_path_list {object instance_list counter_list args} {
array set opts [parseargs args {
machine.arg
skiptotal.bool
} -nulldefault]
array set instances {}
foreach instance $instance_list {
if {![info exists instances($instance)]} {
set instances($instance) 1
} else {
incr instances($instance)
}
}
if {$opts(skiptotal)} {
catch {array unset instances "*_Total"}
}
set counter_paths [list ]
foreach {instance count} [array get instances] {
while {$count} {
incr count -1
foreach counter $counter_list {
lappend counter_paths [make_perf_counter_path \
$object $counter \
-machine $opts(machine) \
-instance $instance \
-instanceindex $count]
}
}
}
return $counter_paths
}
proc twapi::get_perf_values_from_metacounter_info {metacounters args} {
array set opts [parseargs args {{interval.int 100}}]
set result [list ]
set counters [list ]
if {[llength $metacounters]} {
set hquery [open_perf_query]
try {
set counter_info [list ]
set need_wait 0
foreach counter_elem $metacounters {
foreach {pdh_opt key data_type counter_path wait} $counter_elem {break}
incr need_wait $wait
set hcounter [add_perf_counter $hquery $counter_path]
lappend counters $hcounter
lappend counter_info $pdh_opt $key $counter_path $data_type $hcounter
}
collect_perf_query_data $hquery
if {$need_wait} {
after $opts(interval)
collect_perf_query_data $hquery
}
foreach {pdh_opt key counter_path data_type hcounter} $counter_info {
if {[get_hcounter_value $hcounter -format $data_type -var value]} {
lappend result $pdh_opt $key $value
}
}
} onerror {} {
} finally {
foreach hcounter $counters {
remove_perf_counter $hcounter
}
close_perf_query $hquery
}
}
return $result
}
#-- from power.tcl
proc twapi::suspend_system {args} {
array set opts [parseargs args {
{state.arg standby {standby hibernate}}
force.bool
disablewakeevents.bool
} -maxleftover 0 -nulldefault]
eval_with_privileges {
SetSuspendState [expr {$opts(state) eq "hibernate"}] $opts(force) $opts(disablewakeevents)
} SeShutdownPrivilege
}
interp alias {} twapi::get_device_power_state {} twapi::GetDevicePowerState
proc twapi::get_power_status {} {
foreach {ac battery lifepercent reserved lifetime fulllifetime} [GetSystemPowerStatus] break
set acstatus unknown
if {$ac == 0} {
set acstatus off
} elseif {$ac == 1} {
set acstatus on
}
set batterycharging unknown
if {$battery == -1} {
set batterystate unknown
} elseif {$battery & 128} {
set batterystate notpresent;  # No battery
} else {
if {$battery & 8} {
set batterycharging true
} else {
set batterycharging false
}
if {$battery & 4} {
set batterystate critical
} elseif {$battery & 2} {
set batterystate low
} else {
set batterystate high
}
}
set batterylifepercent unknown
if {$lifepercent >= 0 && $lifepercent <= 100} {
set batterylifepercent $lifepercent
}
set batterylifetime $lifetime
if {$lifetime == -1} {
set batterylifetime unknown
}
set batteryfulllifetime $fulllifetime
if {$fulllifetime == -1} {
set batteryfulllifetime unknown
}
return [kl_create2 {
-acstatus
-batterystate
-batterycharging
-batterylifepercent
-batterylifetime
-batteryfulllifetime
} [list $acstatus $batterystate $batterycharging $batterylifepercent $batterylifetime $batteryfulllifetime]]
}
#-- from printer.tcl
namespace eval twapi {
}
proc twapi::enumerate_printers {args} {
array set opts [parseargs args {
{location.arg all {local remote all any}}
} -maxleftover 0]
set result [list ]
foreach elem [Twapi_EnumPrinters_Level4 \
[string map {all 6 any 6 local 2 remote 4} $opts(location)] \
] {
lappend result [list \
name [kl_get $elem pPrinterName] \
server [kl_get $elem pServerName] \
attrs [_symbolize_printer_attributes \
[kl_get $elem Attributes]] \
]
}
return $result
}
proc twapi::printer_properties_dialog {name args} {
array set opts [parseargs args {
{hwin.int 0}
{page.arg ""}
} -maxleftover 0]
shell_object_properties_dialog $name -type printer -hwin $opts(hwin) -page $opts(page)
}
proc twapi::_symbolize_printer_attributes {attr} {
return [_make_symbolic_bitmask $attr {
queued         0x00000001
direct         0x00000002
default        0x00000004
shared         0x00000008
network        0x00000010
hidden         0x00000020
local          0x00000040
enabledevq       0x00000080
keepprintedjobs   0x00000100
docompletefirst 0x00000200
workoffline   0x00000400
enablebidi    0x00000800
rawonly       0x00001000
published      0x00002000
fax            0x00004000
ts             0x00008000
}]
}
#-- from process.tcl
namespace eval twapi {
}
proc twapi::get_current_process_id {} {
return [::pid]
}
proc twapi::get_current_thread_id {} {
return [GetCurrentThreadId]
}
proc twapi::process_waiting_for_input {pid args} {
array set opts [parseargs args {{wait.int 0}}]
set hpid [get_process_handle $pid]
try {
set status [WaitForInputIdle $hpid $opts(wait)]
} finally {
CloseHandle $hpid
}
return $status
}
proc twapi::create_process {path args} {
array set opts [parseargs args \
[list \
[list cmdline.arg ""] \
[list inheritablechildprocess.bool 0] \
[list inheritablechildthread.bool 0] \
[list childprocesssecd.arg ""] \
[list childthreadsecd.arg ""] \
[list inherithandles.bool 0] \
[list env.arg ""] \
[list startdir.arg ""] \
[list inheriterrormode.bool 1] \
[list newconsole.bool 0] \
[list detached.bool 0] \
[list newprocessgroup.bool 0] \
[list noconsole.bool 0] \
[list separatevdm.bool 0] \
[list sharedvdm.bool 0] \
[list createsuspended.bool 0] \
[list debugchildtree.bool 0] \
[list debugchild.bool 0] \
[list priority.arg "normal" [list normal abovenormal belownormal high realtime idle]] \
[list desktop.arg "__null__"] \
[list title.arg ""] \
windowpos.arg \
windowsize.arg \
screenbuffersize.arg \
[list feedbackcursoron.bool false] \
[list feedbackcursoroff.bool false] \
background.arg \
foreground.arg \
[list fullscreen.bool false] \
[list showwindow.arg ""] \
[list stdhandles.arg ""] \
[list stdchannels.arg ""] \
[list returnhandles.bool 0]\
]]
set process_sec_attr [_make_secattr $opts(childprocesssecd) $opts(inheritablechildprocess)]
set thread_sec_attr [_make_secattr $opts(childthreadsecd) $opts(inheritablechildthread)]
foreach {opt1 opt2} {
newconsole detached
sharedvdm  separatevdm
} {
if {$opts($opt1) && $opts($opt2)} {
error "Options -$opt1 and -$opt2 cannot be specified together"
}
}
set si_flags 0
if {[info exists opts(windowpos)]} {
foreach {xpos ypos} [_parse_integer_pair $opts(windowpos)] break
setbits si_flags 0x4
} else {
set xpos 0
set ypos 0
}
if {[info exists opts(windowsize)]} {
foreach {xsize ysize} [_parse_integer_pair $opts(windowsize)] break
setbits si_flags 0x2
} else {
set xsize 0
set ysize 0
}
if {[info exists opts(screenbuffersize)]} {
foreach {xscreen yscreen} [_parse_integer_pair $opts(screenbuffersize)] break
setbits si_flags 0x8
} else {
set xscreen 0
set yscreen 0
}
set fg 7;                           # Default to white
set bg 0;                           # Default to black
if {[info exists opts(foreground)]} {
set fg [_map_console_color $opts(foreground) 0]
setbits si_flags 0x10
}
if {[info exists opts(background)]} {
set bg [_map_console_color $opts(background) 1]
setbits si_flags 0x10
}
if {$opts(feedbackcursoron)} {
setbits si_flags 0x40
}
if {$opts(feedbackcursoron)} {
setbits si_flags 0x80
}
if {$opts(fullscreen)} {
setbits si_flags 0x20
}
switch -exact -- $opts(showwindow) {
""        { }
hidden    {set opts(showwindow) 0}
normal    {set opts(showwindow) 1}
minimized {set opts(showwindow) 2}
maximized {set opts(showwindow) 3}
default   {error "Invalid value '$opts(showwindow)' for -showwindow option"}
}
if {[string length $opts(showwindow)]} {
setbits si_flags 0x1
}
if {[llength $opts(stdhandles)] && [llength $opts(stdchannels)]} {
error "Options -stdhandles and -stdchannels cannot be used together"
}
if {[llength $opts(stdhandles)]} {
if {! $opts(inherithandles)} {
error "Cannot specify -stdhandles option if option -inherithandles is specified as 0"
}
setbits si_flags 0x100
}
if {[llength $opts(stdchannels)]} {
if {! $opts(inherithandles)} {
error "Cannot specify -stdhandles option if option -inherithandles is specified as 0"
}
if {[llength $opts(stdchannels)] != 3} {
error "Must specify 3 channels for -stdchannels option corresponding stdin, stdout and stderr"
}
setbits si_flags 0x100
lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 0] read] -inherit]
lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 1] write] -inherit]
lappend opts(stdhandles) [duplicate_handle [get_tcl_channel_handle [lindex $opts(stdchannels) 2] write] -inherit]
}
set startup [list $opts(desktop) $opts(title) $xpos $ypos \
$xsize $ysize $xscreen $yscreen \
[expr {$fg|$bg}] $si_flags $opts(showwindow) \
$opts(stdhandles)]
set flags 0x00000400;               # CREATE_UNICODE_ENVIRONMENT
foreach {opt flag} {
debugchildtree       0x00000001
debugchild           0x00000002
createsuspended      0x00000004
detached             0x00000008
newconsole           0x00000010
newprocessgroup      0x00000200
separatevdm          0x00000800
sharedvdm            0x00001000
inheriterrormode     0x04000000
noconsole            0x08000000
} {
if {$opts($opt)} {
setbits flags $flag
}
}
switch -exact -- $opts(priority) {
normal      {set priority 0x00000020}
abovenormal {set priority 0x00008000}
belownormal {set priority 0x00004000}
""          {set priority 0}
high        {set priority 0x00000080}
realtime    {set priority 0x00000100}
idle        {set priority 0x00000040}
default     {error "Unknown priority '$priority'"}
}
setbits flags $priority
if {[llength $opts(env)]} {
set child_env [list ]
foreach {envvar envval} $opts(env) {
lappend child_env "$envvar=$envval"
}
} else {
set child_env "__null__"
}
try {
foreach {ph th pid tid} [CreateProcess [file nativename $path] \
$opts(cmdline) \
$process_sec_attr $thread_sec_attr \
$opts(inherithandles) $flags $child_env \
[file normalize $opts(startdir)] $startup] {
break
}
} finally {
if {[llength $opts(stdchannels)]} {
eval close_handles $opts(stdhandles)
}
}
if {$opts(returnhandles)} {
return [list $pid $tid $ph $th]
} else {
CloseHandle $th
CloseHandle $ph
return [list $pid $tid]
}
}
proc twapi::get_process_handle {pid args} {
if {($pid & 3) && [min_os_version 5]} {
win32_error 87;         # "The parameter is incorrect"
}
array set opts [parseargs args {
{access.arg process_query_information}
{inherit.bool 0}
}]
return [OpenProcess [_access_rights_to_mask $opts(access)] $opts(inherit) $pid]
}
proc twapi::get_process_exit_code {hpid} {
set code [GetExitCodeProcess $hpid]
return [expr {$code == 259 ? "" : $code}]
}
proc twapi::get_command_line {} {
return [GetCommandLineW]
}
proc twapi::get_command_line_args {cmdline} {
if {[string length $cmdline] == 0} {
return [list ]
}
return [CommandLineToArgv $cmdline]
}
proc twapi::is_system_pid {pid} {
foreach {major minor} [get_os_version] break
if {$major == 4 } {
set syspid 2
} elseif {$major == 5 && $minor == 0} {
set syspid 8
} else {
set syspid 4
}
proc ::twapi::is_system_pid pid "expr \$pid==$syspid"
return [is_system_pid $pid]
}
proc twapi::is_idle_pid {pid} {
return [expr {$pid == 0}]
}
proc twapi::_get_token_info {type id optlist} {
array set opts [parseargs optlist {
user
groups
primarygroup
privileges
logonsession
{noexist.arg "(no such process)"}
{noaccess.arg "(unknown)"}
} -maxleftover 0]
if {$type == "thread"} {
set tok [open_thread_token -tid $id -access [list token_query]]
} else {
set tok [open_process_token -pid $id -access [list token_query]]
}
set result [list ]
try {
if {$opts(user)} {
lappend result -user [get_token_user $tok -name]
}
if {$opts(groups)} {
lappend result -groups [get_token_groups $tok -name]
}
if {$opts(primarygroup)} {
lappend result -primarygroup [get_token_primary_group $tok -name]
}
if {$opts(privileges)} {
lappend result -privileges [get_token_privileges $tok -all]
}
if {$opts(logonsession)} {
array set stats [get_token_statistics $tok]
lappend result -logonsession $stats(authluid)
}
} finally {
close_token $tok
}
return $result
}
#-- from process2.tcl
proc twapi::get_process_ids {args} {
set save_args $args;                # Need to pass to process_exists
array set opts [parseargs args {
user.arg
path.arg
name.arg
logonsession.arg
glob} -maxleftover 0]
if {[info exists opts(path)] && [info exists opts(name)]} {
error "Options -path and -name are mutually exclusive"
}
if {$opts(glob)} {
set match_op match
} else {
set match_op equal
}
set process_pids [list ]
if {[info exists opts(user)] == 0 &&
[info exists opts(logonsession)] == 0 &&
[info exists opts(path)] == 0} {
if {[info exists opts(name)] == 0} {
return [Twapi_GetProcessList -1 0]
}
foreach {pid piddata} [Twapi_GetProcessList -1 2] {
if {[string $match_op -nocase $opts(name) [kl_get $piddata ProcessName]]} {
lappend process_pids $pid
}
}
return $process_pids
}
if {[info exists opts(path)] == 0 &&
[info exists opts(logonsession)] == 0} {
if {[info exists opts(user)]} {
if {[catch {map_account_to_sid $opts(user)} sid]} {
return [list ]
}
}
if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
foreach wtselem $wtslist {
array set procinfo $wtselem
if {[info exists sid] &&
$procinfo(pUserSid) ne $sid} {
continue;           # User does not match
}
if {[info exists opts(name)]} {
if {![string $match_op -nocase $opts(name) $procinfo(pProcessName)]} {
continue
}
}
lappend process_pids $procinfo(ProcessId)
}
return $process_pids
}
}
if {[info exists opts(path)]} {
set opts(path) [file join $opts(path)]
}
set process_pids [list ]
if {[info exists opts(name)]} {
foreach {pid piddata} [Twapi_GetProcessList -1 2] {
if {[string $match_op -nocase $opts(name) [kl_get $piddata ProcessName]]} {
lappend all_pids $pid
}
}
} else {
set all_pids [Twapi_GetProcessList -1 0]
}
set popts [list ]
foreach opt {path user logonsession} {
if {[info exists opts($opt)]} {
lappend popts -$opt
}
}
foreach {pid piddata} [eval [list get_multiple_process_info $all_pids] $popts] {
array set pidvals $piddata
if {[info exists opts(path)] &&
![string $match_op -nocase $opts(path) [file join $pidvals(-path)]]} {
continue
}
if {[info exists opts(user)] && $pidvals(-user) ne $opts(user)} {
continue
}
if {[info exists opts(logonsession)] &&
$pidvals(-logonsession) ne $opts(logonsession)} {
continue
}
lappend process_pids $pid
}
return $process_pids
}
proc twapi::get_process_modules {pid args} {
variable windefs
array set opts [parseargs args {handle name path imagedata all}]
if {$opts(all)} {
foreach opt {handle name path imagedata} {
set opts($opt) 1
}
}
set noopts [expr {($opts(name) || $opts(path) || $opts(imagedata) || $opts(handle)) == 0}]
set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
set results [list ]
try {
foreach module [EnumProcessModules $hpid] {
if {$noopts} {
lappend results $module
continue
}
set module_data [list ]
if {$opts(handle)} {
lappend module_data -handle $module
}
if {$opts(name)} {
if {[catch {GetModuleBaseName $hpid $module} name]} {
set name ""
}
lappend module_data -name $name
}
if {$opts(path)} {
if {[catch {GetModuleFileNameEx $hpid $module} path]} {
set path ""
}
lappend module_data -path [_normalize_path $path]
}
if {$opts(imagedata)} {
if {[catch {GetModuleInformation $hpid $module} imagedata]} {
set base ""
set size ""
set entry ""
} else {
array set temp $imagedata
set base $temp(lpBaseOfDll)
set size $temp(SizeOfImage)
set entry $temp(EntryPoint)
}
lappend module_data -imagedata [list $base $size $entry]
}
lappend results $module_data
}
} finally {
CloseHandle $hpid
}
return $results
}
proc twapi::end_process {pid args} {
array set opts [parseargs args {
{exitcode.int 1}
force
{wait.int 0}
}]
set process_path [get_process_path $pid]
set toplevels [concat [get_toplevel_windows -pid $pid] [find_windows -pids [list $pid] -messageonlywindow true]]
if {[llength $toplevels]} {
foreach toplevel $toplevels {
if {0} {
catch {PostMessage $toplevel 0x10 0 0}
} else {
catch {SendNotifyMessage $toplevel 0x10 0 0}
}
}
set gone [twapi::wait {process_exists $pid -path $process_path} 0 $opts(wait)]
if {$gone || ! $opts(force)} {
return $gone
}
if {$opts(wait)} {
set opts(wait) 10
}
}
try {
set hpid [get_process_handle $pid -access process_terminate]
} onerror {TWAPI_WIN32 5} {
eval_with_privileges {
set hpid [get_process_handle $pid -access process_terminate]
} SeDebugPrivilege
}
try {
TerminateProcess $hpid $opts(exitcode)
} finally {
CloseHandle $hpid
}
if {0} {
While the process is being terminated, we can get access denied
if we try to get the path so this if branch is commented out
return [twapi::wait {process_exists $pid -path $process_path} 0 $opts(wait)]
} else {
return [twapi::wait {process_exists $pid} 0 $opts(wait)]
}
}
proc twapi::get_process_path {pid args} {
return [eval [list twapi::_get_process_name_path_helper $pid path] $args]
}
proc twapi::get_process_name {pid args} {
return [eval [list twapi::_get_process_name_path_helper $pid name] $args]
}
proc twapi::get_device_drivers {args} {
variable windefs
array set opts [parseargs args {name path base all}]
set results [list ]
foreach module [EnumDeviceDrivers] {
catch {unset module_data}
if {$opts(base) || $opts(all)} {
set module_data [list -base $module]
}
if {$opts(name) || $opts(all)} {
if {[catch {GetDeviceDriverBaseName $module} name]} {
set name ""
}
lappend module_data -name $name
}
if {$opts(path) || $opts(all)} {
if {[catch {GetDeviceDriverFileName $module} path]} {
set path ""
}
lappend module_data -path [_normalize_path $path]
}
if {[info exists module_data]} {
lappend results $module_data
}
}
return $results
}
proc twapi::process_exists {pid args} {
array set opts [parseargs args { path.arg name.arg glob}]
if {! ([info exists opts(path)] || [info exists opts(name)])} {
if {[llength [Twapi_GetProcessList $pid 0]] == 0} {
return 0
} else {
return 1
}
}
if {[info exists opts(path)] && [info exists opts(name)]} {
error "Options -path and -name are mutually exclusive"
}
if {$opts(glob)} {
set string_cmd match
} else {
set string_cmd equal
}
if {[info exists opts(name)]} {
set piddata [Twapi_GetProcessList $pid 2]
if {[llength $piddata] &&
[string $string_cmd -nocase $opts(name) [kl_get [lindex $piddata 1] ProcessName]]} {
return 1
} else {
return 0
}
}
set process_path [get_process_path $pid -noexist "" -noaccess "(unknown)"]
if {[string length $process_path] == 0} {
return 0
}
if {[string equal $process_path "(unknown)"]} {
return -1
}
return [string $string_cmd -nocase [file join $opts(path)] [file join $process_path]]
}
proc twapi::get_thread_parent_process_id {tid} {
set status [catch {
set th [get_thread_handle $tid]
try {
set pid [lindex [lindex [Twapi_NtQueryInformationThreadBasicInformation $th] 2] 0]
} finally {
close_handles [list $th]
}
}]
if {$status == 0} {
return $pid
}
set pid_paths [get_perf_thread_counter_paths $tid -pid]
if {[llength $pid_paths] == 0} {
return ""
}
if {[get_counter_path_value [lindex [lindex $pid_paths 0] 3] -var pid]} {
return $pid
} else {
return ""
}
}
proc twapi::get_process_thread_ids {pid} {
return [lindex [lindex [get_multiple_process_info [list $pid] -tids] 1] 1]
}
proc twapi::get_process_info {pid args} {
return [lindex [eval [list get_multiple_process_info [list $pid]] $args] 1]
}
proc twapi::get_multiple_process_info {pids args} {
if {![info exists ::twapi::get_multiple_process_info_base_opts]} {
array set ::twapi::get_multiple_process_info_base_opts {
basepriority       1
parent             1
tssession          1
name               2
createtime         4
usertime           4
privilegedtime     4
elapsedtime        4
handlecount        4
pagefaults         8
pagefilebytes      8
pagefilebytespeak  8
poolnonpagedbytes  8
poolnonpagedbytespeak  8
poolpagedbytes     8
poolpagedbytespeak 8
threadcount        4
virtualbytes       8
virtualbytespeak   8
workingset         8
workingsetpeak     8
tids               32
}
if {[min_os_version 5]} {
array set ::twapi::get_multiple_process_info_base_opts {
ioreadops         16
iowriteops        16
iootherops        16
ioreadbytes       16
iowritebytes      16
iootherbytes      16
}
}
}
set pdh_opts {
privatebytes
}
set pdh_rate_opts {
privilegedutilization
processorutilization
userutilization
iodatabytesrate
iodataopsrate
iootherbytesrate
iootheropsrate
ioreadbytesrate
ioreadopsrate
iowritebytesrate
iowriteopsrate
pagefaultrate
}
set token_opts {
user
groups
primarygroup
privileges
logonsession
}
array set opts [parseargs args \
[concat [list all \
pid \
handles \
path \
toplevels \
commandline \
priorityclass \
[list noexist.arg "(no such process)"] \
[list noaccess.arg "(unknown)"] \
[list interval.int 100]] \
[array names ::twapi::get_multiple_process_info_base_opts] \
$token_opts \
$pdh_opts \
$pdh_rate_opts]]
array set results {}
if {$opts(all) || $opts(user)} {
_get_wts_pids wtssids wtsnames
}
set flags 0
foreach opt [array names ::twapi::get_multiple_process_info_base_opts] {
if {$opts($opt) || $opts(all)} {
set flags [expr {$flags | $::twapi::get_multiple_process_info_base_opts($opt)}]
}
}
if {$flags} {
if {[llength $pids] == 1} {
array set basedata [twapi::Twapi_GetProcessList [lindex $pids 0] $flags]
} else {
array set basedata [twapi::Twapi_GetProcessList -1 $flags]
}
}
foreach pid $pids {
set result [list ]
if {$opts(all) || $opts(pid)} {
lappend result -pid $pid
}
foreach {opt field} {
createtime         CreateTime
usertime           UserTime
privilegedtime     KernelTime
handlecount        HandleCount
pagefaults         VmCounters.PageFaultCount
pagefilebytes      VmCounters.PagefileUsage
pagefilebytespeak  VmCounters.PeakPagefileUsage
poolnonpagedbytes  VmCounters.QuotaNonPagedPoolUsage
poolnonpagedbytespeak  VmCounters.QuotaPeakNonPagedPoolUsage
poolpagedbytespeak     VmCounters.QuotaPeakPagedPoolUsage
poolpagedbytes     VmCounters.QuotaPagedPoolUsage
basepriority       BasePriority
threadcount        ThreadCount
virtualbytes       VmCounters.VirtualSize
virtualbytespeak   VmCounters.PeakVirtualSize
workingset         VmCounters.WorkingSetSize
workingsetpeak     VmCounters.PeakWorkingSetSize
ioreadops          IoCounters.ReadOperationCount
iowriteops         IoCounters.WriteOperationCount
iootherops         IoCounters.OtherOperationCount
ioreadbytes        IoCounters.ReadTransferCount
iowritebytes       IoCounters.WriteTransferCount
iootherbytes       IoCounters.OtherTransferCount
parent             InheritedFromProcessId
tssession          SessionId
} {
if {$opts($opt) || $opts(all)} {
if {[info exists basedata($pid)]} {
lappend result -$opt [twapi::kl_get $basedata($pid) $field]
} else {
lappend result -$opt $opts(noexist)
}
}
}
if {$opts(elapsedtime) || $opts(all)} {
if {[info exists basedata($pid)]} {
lappend result -elapsedtime [expr {[clock seconds]-[large_system_time_to_secs [twapi::kl_get $basedata($pid) CreateTime]]}]
} else {
lappend result -elapsedtime $opts(noexist)
}
}
if {$opts(tids) || $opts(all)} {
if {[info exists basedata($pid)]} {
set tids [list ]
foreach {tid threaddata} [twapi::kl_get $basedata($pid) Threads] {
lappend tids $tid
}
lappend result -tids $tids
} else {
lappend result -tids $opts(noexist)
}
}
if {$opts(name) || $opts(all)} {
if {[info exists basedata($pid)]} {
set name [twapi::kl_get $basedata($pid) ProcessName]
if {$name eq ""} {
if {[is_system_pid $pid]} {
set name "System"
} elseif {[is_idle_pid $pid]} {
set name "System Idle Process"
}
}
lappend result -name $name
} else {
lappend result -name $opts(noexist)
}
}
if {$opts(all) || $opts(path)} {
lappend result -path [get_process_path $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
}
if {$opts(all) || $opts(priorityclass)} {
try {
set prioclass [get_priority_class $pid]
} onerror {TWAPI_WIN32 5} {
set prioclass $opts(noaccess)
} onerror {TWAPI_WIN32 87} {
set prioclass $opts(noexist)
}
lappend result -priorityclass $prioclass
}
if {$opts(all) || $opts(toplevels)} {
set toplevels [get_toplevel_windows -pid $pid]
if {[llength $toplevels]} {
lappend result -toplevels $toplevels
} else {
if {[process_exists $pid]} {
lappend result -toplevels [list ]
} else {
lappend result -toplevels $opts(noexist)
}
}
}
if {$opts(handles)} {
set handles [list ]
foreach hinfo [get_open_handles $pid] {
lappend handles [list [kl_get $hinfo -handle] [kl_get $hinfo -type] [kl_get $hinfo -name]]
}
lappend result -handles $handles
}
if {$opts(all) || $opts(commandline)} {
lappend result -commandline [get_process_commandline $pid -noexist $opts(noexist) -noaccess $opts(noaccess)]
}
set requested_opts [list ]
if {$opts(all) || $opts(user)} {
if {[info exists wtssids($pid)]} {
if {$wtssids($pid) == ""} {
lappend result -user "SYSTEM"
} else {
if {[info exists sidcache($wtssids($pid))]} {
lappend result -user $sidcache($wtssids($pid))
} else {
set uname [lookup_account_sid $wtssids($pid)]
lappend result -user $uname
set sidcache($wtssids($pid)) $uname
}
}
} else {
lappend requested_opts -user
}
}
foreach opt {groups primarygroup privileges logonsession} {
if {$opts(all) || $opts($opt)} {
lappend requested_opts -$opt
}
}
if {[llength $requested_opts]} {
try {
eval lappend result [_get_token_info process $pid $requested_opts]
} onerror {TWAPI_WIN32 5} {
foreach opt $requested_opts {
set tokresult($opt) $opts(noaccess)
}
if {[lsearch -exact $requested_opts "-logonsession"] >= 0} {
if {![info exists wtssids]} {
_get_wts_pids wtssids wtsnames
}
if {[info exists wtssids($pid)]} {
switch -exact -- $wtssids($pid) {
S-1-5-18 {
set tokresult(-logonsession) 00000000-000003e7
}
S-1-5-19 {
set tokresult(-logonsession) 00000000-000003e5
}
S-1-5-20 {
set tokresult(-logonsession) 00000000-000003e4
}
}
}
}
if {[lsearch -exact $requested_opts "-user"] >= 0} {
if {[is_idle_pid $pid] || [is_system_pid $pid]} {
set tokresult(-user) SYSTEM
}
}
set result [concat $result [array get tokresult]]
} onerror {TWAPI_WIN32 87} {
foreach opt $requested_opts {
if {$opt eq "-user" && ([is_idle_pid $pid] || [is_system_pid $pid])} {
lappend result $opt SYSTEM
} else {
lappend result $opt $opts(noexist)
}
}
}
}
set results($pid) $result
}
array set gotdata {}
set wanted_pdh_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
if {[llength $wanted_pdh_opts] != 0} {
set counters [eval [list get_perf_process_counter_paths $pids] \
$wanted_pdh_opts]
foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval 0] {
lappend results($pid) $opt $val
set gotdata($pid,$opt) 1; # Since we have the data
}
}
set wanted_pdh_rate_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
foreach pid $pids {
foreach opt $wanted_pdh_rate_opts {
set missingdata($pid,$opt) 1
}
}
if {[llength $wanted_pdh_rate_opts] != 0} {
set counters [eval [list get_perf_process_counter_paths $pids] \
$wanted_pdh_rate_opts]
foreach {opt pid val} [get_perf_values_from_metacounter_info $counters -interval $opts(interval)] {
lappend results($pid) $opt $val
set gotdata($pid,$opt) 1; # Since we have the data
}
}
foreach pid $pids {
foreach opt [concat $wanted_pdh_opts $wanted_pdh_rate_opts] {
if {![info exists gotdata($pid,$opt)]} {
lappend results($pid) $opt $opts(noexist)
}
}
}
return [array get results]
}
proc twapi::get_thread_info {tid args} {
if {![info exists ::twapi::get_thread_info_base_opts]} {
array set ::twapi::get_thread_info_base_opts {
pid 32
elapsedtime 96
waittime 96
usertime 96
createtime 96
privilegedtime 96
contextswitches 96
basepriority 160
priority 160
startaddress 160
state 160
waitreason 160
}
}
set pdh_opts {
}
set pdh_rate_opts {
privilegedutilization
processorutilization
userutilization
contextswitchrate
}
set token_opts {
groups
user
primarygroup
privileges
}
array set opts [parseargs args \
[concat [list all \
relativepriority \
tid \
[list noexist.arg "(no such thread)"] \
[list noaccess.arg "(unknown)"] \
[list interval.int 100]] \
[array names ::twapi::get_thread_info_base_opts] \
$token_opts $pdh_opts $pdh_rate_opts]]
set requested_opts [_array_non_zero_switches opts $token_opts $opts(all)]
if {[llength $requested_opts]} {
try {
try {
set results [_get_token_info thread $tid $requested_opts]
} onerror {TWAPI_WIN32 1008} {
set results [_get_token_info process [get_thread_parent_process_id $tid] $requested_opts]
}
} onerror {TWAPI_WIN32 5} {
foreach opt $requested_opts {
lappend results $opt $opts(noaccess)
}
} onerror {TWAPI_WIN32 87} {
foreach opt $requested_opts {
lappend results $opt $opts(noexist)
}
}
} else {
set results [list ]
}
set flags 0
foreach opt [array names ::twapi::get_thread_info_base_opts] {
if {$opts($opt) || $opts(all)} {
set flags [expr {$flags | $::twapi::get_thread_info_base_opts($opt)}]
}
}
if {$flags} {
foreach {pid piddata} [twapi::Twapi_GetProcessList -1 $flags] {
foreach {thread_id threaddata} [kl_get $piddata Threads] {
if {$tid == $thread_id} {
array set threadinfo $threaddata
break
}
}
if {[info exists threadinfo]} {
break;  # Found it, no need to keep looking through other pids
}
}
foreach {opt field} {
pid            ClientId.UniqueProcess
waittime       WaitTime
usertime       UserTime
createtime     CreateTime
privilegedtime KernelTime
basepriority   BasePriority
priority       Priority
startaddress   StartAddress
state          State
waitreason     WaitReason
contextswitches ContextSwitchCount
} {
if {$opts($opt) || $opts(all)} {
if {[info exists threadinfo]} {
lappend results -$opt $threadinfo($field)
} else {
lappend results -$opt $opts(noexist)
}
}
}
if {$opts(elapsedtime) || $opts(all)} {
if {[info exists threadinfo(CreateTime)]} {
lappend results -elapsedtime [expr {[clock seconds]-[large_system_time_to_secs $threadinfo(CreateTime)]}]
} else {
lappend results -elapsedtime $opts(noexist)
}
}
}
set requested_opts [_array_non_zero_switches opts $pdh_opts $opts(all)]
array set pdhdata {}
if {[llength $requested_opts] != 0} {
set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
$requested_opts]
foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval 0] {
set pdhdata($opt) $value
}
foreach opt $requested_opts {
if {[info exists pdhdata($opt)]} {
lappend results $opt $pdhdata($opt)
} else {
lappend results $opt $opts(noexist)
}
}
}
set requested_opts [_array_non_zero_switches opts $pdh_rate_opts $opts(all)]
if {[llength $requested_opts] != 0} {
set counter_list [eval [list get_perf_thread_counter_paths [list $tid]] \
$requested_opts]
foreach {opt tid value} [get_perf_values_from_metacounter_info $counter_list -interval $opts(interval)] {
set pdhdata($opt) $value
}
foreach opt $requested_opts {
if {[info exists pdhdata($opt)]} {
lappend results $opt $pdhdata($opt)
} else {
lappend results $opt $opts(noexist)
}
}
}
if {$opts(all) || $opts(relativepriority)} {
try {
lappend results -relativepriority [get_thread_relative_priority $tid]
} onerror {TWAPI_WIN32 5} {
lappend results -relativepriority $opts(noaccess)
} onerror {TWAPI_WIN32 87} {
lappend results -relativepriority $opts(noexist)
}
}
if {$opts(all) || $opts(tid)} {
lappend results -tid $tid
}
return $results
}
proc twapi::get_thread_handle {tid args} {
if {$tid & 3} {
win32_error 87;         # "The parameter is incorrect"
}
array set opts [parseargs args {
{access.arg thread_query_information}
{inherit.bool 0}
}]
return [OpenThread [_access_rights_to_mask $opts(access)] $opts(inherit) $tid]
}
proc twapi::suspend_thread {tid} {
set htid [get_thread_handle $tid -access thread_suspend_resume)]
try {
set status [SuspendThread $htid]
} finally {
CloseHandle $htid
}
return $status
}
proc twapi::resume_thread {tid} {
set htid [get_thread_handle $tid -access thread_suspend_resume)]
try {
set status [ResumeThread $htid]
} finally {
CloseHandle $htid
}
return $status
}
proc twapi::get_process_commandline {pid args} {
if {[is_system_pid $pid] || [is_idle_pid $pid]} {
return ""
}
array set opts [parseargs args {
{noexist.arg "(no such process)"}
{noaccess.arg "(unknown)"}
}]
try {
set max_len 2048
set hgbl [GlobalAlloc 0 $max_len]
set pgbl [GlobalLock $hgbl]
try {
set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
} onerror {TWAPI_WIN32 87} {
return $opts(noexist)
}
set peb_addr [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 1]
ReadProcessMemory $hpid [expr {16+$peb_addr}] $pgbl 4
if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 4] i info_addr]} {
error "Could not get address of process information block"
}
ReadProcessMemory $hpid [expr {$info_addr + 68}] $pgbl 4
if {![binary scan [Twapi_ReadMemoryBinary $pgbl 0 4] i cmdline_addr]} {
error "Could not get address of command line"
}
while {$max_len > 128} {
try {
ReadProcessMemory $hpid $cmdline_addr $pgbl $max_len
break
} onerror {TWAPI_WIN32 299} {
set max_len [expr {$max_len / 2}]
}
}
set cmdline [encoding convertfrom unicode [Twapi_ReadMemoryBinary $pgbl 0 $max_len]]
set null_offset [string first "\0" $cmdline]
if {$null_offset >= 0} {
set cmdline [string range $cmdline 0 [expr {$null_offset-1}]]
}
} onerror {TWAPI_WIN32 5} {
set cmdline $opts(noaccess)
} finally {
if {[info exists hpid]} {
close_handles $hpid
}
if {[info exists hgbl]} {
if {[info exists pgbl]} {
GlobalUnlock $hgbl
}
GlobalFree $hgbl
}
}
return $cmdline
}
proc twapi::get_process_parent {pid args} {
array set opts [parseargs args {
{noexist.arg "(no such process)"}
{noaccess.arg "(unknown)"}
}]
if {[is_system_pid $pid] || [is_idle_pid $pid]} {
return ""
}
try {
set hpid [get_process_handle $pid]
set parent [lindex [Twapi_NtQueryInformationProcessBasicInformation $hpid] 5]
} onerror {TWAPI_WIN32 5} {
set error noaccess
} onerror {TWAPI_WIN32 87} {
set error noexist
} finally {
if {[info exists hpid]} {
close_handles $hpid
}
}
if {![info exists parent]} {
set counters [get_perf_process_counter_paths $pid -parent]
if {[llength counters]} {
set vals [get_perf_values_from_metacounter_info $counters -interval 0]
if {[llength $vals] > 2} {
set parent [lindex $vals 2]
}
}
if {![info exists parent]} {
set parent $opts($error)
}
}
return $parent
}
proc twapi::get_priority_class {pid} {
set ph [get_process_handle $pid]
try {
return [GetPriorityClass $ph]
} finally {
CloseHandle $ph
}
}
proc twapi::set_priority_class {pid priority} {
set ph [get_process_handle $pid -access process_set_information]
try {
SetPriorityClass $ph $priority
} finally {
CloseHandle $ph
}
}
proc twapi::get_thread_relative_priority {tid} {
set h [get_thread_handle $tid]
try {
return [GetThreadPriority $h]
} finally {
CloseHandle $h
}
}
proc twapi::set_thread_relative_priority {tid priority} {
switch -exact -- $priority {
abovenormal { set priority 1 }
belownormal { set priority -1 }
highest     { set priority 2 }
idle        { set priority -15 }
lowest      { set priority -2 }
normal      { set priority 0 }
timecritical { set priority 15 }
default {
if {![string is integer -strict $priority]} {
error "Invalid priority value '$priority'."
}
}
}
set h [get_thread_handle $tid -access thread_set_information]
try {
SetThreadPriority $h $priority
} finally {
CloseHandle $h
}
}
proc twapi::_get_process_name_path_helper {pid {type name} args} {
variable windefs
array set opts [parseargs args {
{noexist.arg "(no such process)"}
{noaccess.arg "(unknown)"}
}]
if {![string is integer $pid]} {
error "Invalid non-numeric pid $pid"
}
if {[is_system_pid $pid]} {
return "System"
}
if {[is_idle_pid $pid]} {
return "System Idle Process"
}
try {
set hpid [get_process_handle $pid -access {process_query_information process_vm_read}]
} onerror {TWAPI_WIN32 87} {
return $opts(noexist)
} onerror {TWAPI_WIN32 5} {
if {[string equal $type "name"]} {
if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
foreach wtselem $wtslist {
if {[kl_get $wtselem ProcessId] == $pid} {
return [kl_get $wtselem pProcessName]
}
}
}
set pdh_path [lindex [lindex [twapi::get_perf_process_counter_paths [list $pid] -pid] 0] 3]
array set pdhinfo [parse_perf_counter_path $pdh_path]
return $pdhinfo(instance)
}
return $opts(noaccess)
}
try {
set module [lindex [EnumProcessModules $hpid] 0]
if {[string equal $type "name"]} {
set path [GetModuleBaseName $hpid $module]
} else {
set path [_normalize_path [GetModuleFileNameEx $hpid $module]]
}
} onerror {TWAPI_WIN32 5} {
if {[min_os_version 5 0]} {
if {[GetExitCodeProcess $hpid] == 259} {
return $opts(noaccess)
} else {
return $opts(noexist)
}
} else {
error $errorResult $errorInfo $errorCode
}
} finally {
CloseHandle $hpid
}
return $path
}
proc twapi::_get_wts_pids {v_sids v_names} {
if {! [catch {WTSEnumerateProcesses NULL} wtslist]} {
upvar $v_sids wtssids
upvar $v_names wtsnames
foreach wtselem $wtslist {
set pid [kl_get $wtselem ProcessId]
set wtssids($pid) [kl_get $wtselem pUserSid]
set wtsnames($pid) [kl_get $wtselem pProcessName]
}
}
}
#-- from security.tcl
namespace eval twapi {
array set priv_level_map {guest 0 user 1 admin 2}
array set sid_type_names {
1 user 
2 group
3 domain 
4 alias 
5 wellknowngroup
6 deletedaccount
7 invalid
8 unknown
9 computer
}
array set well_known_sids {
nullauthority     S-1-0
nobody            S-1-0-0
worldauthority    S-1-1
everyone          S-1-1-0
localauthority    S-1-2
creatorauthority  S-1-3
creatorowner      S-1-3-0
creatorgroup      S-1-3-1
creatorownerserver  S-1-3-2
creatorgroupserver  S-1-3-3
ntauthority       S-1-5
dialup            S-1-5-1
network           S-1-5-2
batch             S-1-5-3
interactive       S-1-5-4
service           S-1-5-6
anonymouslogon    S-1-5-7
proxy             S-1-5-8
serverlogon       S-1-5-9
authenticateduser S-1-5-11
terminalserver    S-1-5-13
localsystem       S-1-5-18
localservice      S-1-5-19
networkservice    S-1-5-20
}
array set builtin_account_sids {
administrators  S-1-5-32-544
users           S-1-5-32-545
guests          S-1-5-32-546
"power users"   S-1-5-32-547
}
}
proc twapi::_lookup_account {func account args} {
if {$func == "LookupAccountSid"} {
set lookup name
if {[is_valid_sid_syntax $account] &&
[string match -nocase "S-1-5-5-*" $account]} {
set name "Logon SID"
set domain "NT AUTHORITY"
set type "logonid"
}
} else {
set lookup sid
}
array set opts [parseargs args \
[list all \
$lookup \
domain \
type \
[list system.arg ""]\
]]
if {![info exists domain]} {
foreach "$lookup domain type" [$func $opts(system) $account] break
}
set result [list ]
if {$opts(all) || $opts(domain)} {
lappend result -domain $domain
}
if {$opts(all) || $opts(type)} {
lappend result -type $twapi::sid_type_names($type)
}
if {$opts(all) || $opts($lookup)} {
lappend result -$lookup [set $lookup]
}
if {[llength $result] == 0} {
return [set $lookup]
}
return $result
}
proc twapi::lookup_account_name {name args} {
return [eval [list _lookup_account LookupAccountName $name] $args]
}
proc twapi::lookup_account_sid {sid args} {
return [eval [list _lookup_account LookupAccountSid $sid] $args]
}
proc twapi::map_account_to_sid {account args} {
array set opts [parseargs args {system.arg} -nulldefault]
if {[string length $account] == ""} {
return ""
}
if {[is_valid_sid_syntax $account]} {
return $account
} else {
return [lookup_account_name $account -system $opts(system)]
}
}
proc twapi::map_account_to_name {account args} {
array set opts [parseargs args {system.arg} -nulldefault]
if {[is_valid_sid_syntax $account]} {
return [lookup_account_sid $account -system $opts(system)]
} else {
if {[catch {map_account_to_sid $account -system $opts(system)}]} {
if {$account == "LocalSystem"} {
return "SYSTEM"
}
error "Unknown account '$account'"
} 
return $account
}
}
proc twapi::get_current_user {{format -samcompatible}} {
set return_sid false
switch -exact -- $format {
-fullyqualifieddn {set format 1}
-samcompatible {set format 2}
-display {set format 3}
-uniqueid {set format 6}
-canonical {set format 7}
-userprincipal {set format 8}
-canonicalex {set format 9}
-serviceprincipal {set format 10}
-dnsdomain {set format 12}
-sid {set format 2 ; set return_sid true}
default {
error "Unknown user name format '$format'"
}
}
set user [GetUserNameEx $format]
if {$return_sid} {
return [map_account_to_sid $user]
} else {
return $user
}
}
proc twapi::is_valid_sid_syntax sid {
try {
set result [IsValidSid $sid]
} onerror {TWAPI_WIN32 1337} {
set result 0
}
return $result
}
proc twapi::open_process_token {args} {
variable windefs
array set opts [parseargs args {
pid.int
{access.arg token_query}
} -maxleftover 0]
set access [_access_rights_to_mask $opts(access)]
if {($access == $windefs(TOKEN_ALL_ACCESS_WIN2K))
&& ([lindex [get_os_version] 0] == 4)} {
set access $windefs(TOKEN_ALL_ACCESS_WINNT)
}
if {[info exists opts(pid)]} {
set ph [OpenProcess $windefs(PROCESS_QUERY_INFORMATION) 0 $opts(pid)]
} else {
variable my_process_handle
set ph $my_process_handle
}
try {
set ptok [OpenProcessToken $ph $access]
} finally {
if {[info exists opts(pid)]} {
CloseHandle $ph
}
}
return $ptok
}
proc twapi::open_thread_token {args} {
variable windefs
array set opts [parseargs args {
tid.int
{access.arg token_query}
{self.bool  false}
} -maxleftover 0]
set access [_access_rights_to_mask $opts(access)]
if {($access == $windefs(TOKEN_ALL_ACCESS_WIN2K))
&& ([lindex [get_os_version] 0] == 4)} {
set access $windefs(TOKEN_ALL_ACCESS_WINNT)
}
if {[info exists opts(tid)]} {
set th [get_thread_handle $opts(tid)]
} else {
set th [GetCurrentThread]
}
try {
set ttok [OpenThreadToken $th $access $opts(self)]
} finally {
if {[info exists opts(tid)]} {
CloseHandle $th
}
}
return $ttok
}
proc twapi::close_token {tok} {
CloseHandle $tok
}
proc twapi::get_token_user {tok args} {
array set opts [parseargs args [list name]]
set user [lindex [GetTokenInformation $tok $twapi::windefs(TokenUser)] 0]
if {$opts(name)} {
set user [lookup_account_sid $user]
}
return $user
}
proc twapi::get_token_groups {tok args} {
array set opts [parseargs args [list name] -maxleftover 0]
set groups [list ]
foreach {group} [GetTokenInformation $tok $twapi::windefs(TokenGroups)] {
set group [lindex $group 0]
if {$opts(name)} {
set group [lookup_account_sid $group]
}
lappend groups $group
}
return $groups
}
proc twapi::get_token_group_sids_and_attrs {tok} {
variable windefs 
set sids_and_attrs [list ]
foreach {group} [GetTokenInformation $tok $windefs(TokenGroups)] {
foreach {sid attr} $group break
set attr_list {enabled enabled_by_default logon_id
mandatory owner resource use_for_deny_only}
lappend sids_and_attrs $sid [_map_token_attr $attr $attr_list SE_GROUP]
}
return $sids_and_attrs
}
proc twapi::get_token_privileges {tok args} {
variable windefs
set all [expr {[lsearch -exact $args -all] >= 0}]
set enabled_privs [list ]
set disabled_privs [list ]
foreach {item} [GetTokenInformation $tok $windefs(TokenPrivileges)] {
set priv [map_luid_to_privilege [lindex $item 0] -mapunknown]
if {[lindex $item 1] & $windefs(SE_PRIVILEGE_ENABLED)} {
lappend enabled_privs $priv
} else {
lappend disabled_privs $priv
}
}
if {$all} {
return [list $enabled_privs $disabled_privs]
} else {
return $enabled_privs
}
}
proc twapi::check_enabled_privileges {tok privlist args} {
set all_required [expr {[lsearch -exact $args "-any"] < 0}]
if {0} {
We now call the PrivilegeCheck instead. Not sure it matters
This code also does not handle -any option
foreach priv $privlist {
if {[expr {
[lsearch -exact [get_token_privileges $tok] $priv] < 0
}]} {
return 0
}
}
return 1
} else {
set luid_attr_list [list ]
foreach priv $privlist {
lappend luid_attr_list [list [map_privilege_to_luid $priv] 0]
}
return [Twapi_PrivilegeCheck $tok $luid_attr_list $all_required]
}
}
proc twapi::enable_privileges {privlist} {
variable my_process_handle
set tok [OpenProcessToken $my_process_handle 0x28]; # QUERY + ADJUST_PRIVS
try {
return [enable_token_privileges $tok $privlist]
} finally {
close_token $tok
}
}
proc twapi::disable_privileges {privlist} {
variable my_process_handle
set tok [OpenProcessToken $my_process_handle 0x28]; # QUERY + ADJUST_PRIVS
try {
return [disable_token_privileges $tok $privlist]
} finally {
close_token $tok
}
}
proc twapi::eval_with_privileges {script privs args} {
array set opts [parseargs args {besteffort} -maxleftover 0]
if {[catch {enable_privileges $privs} privs_to_disable]} {
if {! $opts(besteffort)} {
return -code error -errorinfo $::errorInfo \
-errorcode $::errorCode $privs_to_disable
}
set privs_to_disable [list ]
}
set code [catch {uplevel $script} result]
switch $code {
0 {
disable_privileges $privs_to_disable
return $result
}
1 {
set erinfo $::errorInfo
set ercode $::errorCode
disable_privileges $privs_to_disable
return -code error -errorinfo $::errorInfo \
-errorcode $::errorCode $result
}
default {
disable_privileges $privs_to_disable
return -code $code $result
}
}
}
proc twapi::get_token_privileges_and_attrs {tok} {
set privs_and_attrs [list ]
foreach priv [GetTokenInformation $tok $twapi::windefs(TokenPrivileges)] {
foreach {luid attr} $priv break
set attr_list {enabled enabled_by_default used_for_access}
lappend privs_and_attrs [map_luid_to_privilege $luid -mapunknown] \
[_map_token_attr $attr $attr_list SE_PRIVILEGE]
}
return $privs_and_attrs
}
proc twapi::get_token_owner {tok args} {
return [ _get_token_sid_field $tok TokenOwner $args]
}
proc twapi::get_token_primary_group {tok args} {
return [ _get_token_sid_field $tok TokenPrimaryGroup $args]
}
proc twapi::get_token_source {tok} {
return [GetTokenInformation $tok $twapi::windefs(TokenSource)]
}
proc twapi::get_token_type {tok} {
if {[GetTokenInformation $tok $twapi::windefs(TokenType)]} {
return "primary"
} else {
return "impersonation"
}
}
proc twapi::get_token_impersonation_level {tok} {
return [_map_impersonation_level \
[GetTokenInformation $tok \
$twapi::windefs(TokenImpersonationLevel)]]
}
proc twapi::get_token_statistics {tok} {
array set stats {}
set labels {luid authluid expiration type impersonationlevel
dynamiccharged dynamicavailable groupcount
privilegecount modificationluid}
set statinfo [GetTokenInformation $tok $twapi::windefs(TokenStatistics)]
foreach label $labels val $statinfo {
set stats($label) $val
}
set stats(type) [expr {$stats(type) == 1 ? "primary" : "impersonation"}]
set stats(impersonationlevel) [_map_impersonation_level $stats(impersonationlevel)]
return [array get stats]
}
proc twapi::enable_token_privileges {tok privs} {
variable windefs
set luid_attrs [list]
foreach priv $privs {
lappend luid_attrs [list [map_privilege_to_luid $priv] $windefs(SE_PRIVILEGE_ENABLED)]
}
set privs [list ]
foreach {item} [Twapi_AdjustTokenPrivileges $tok 0 $luid_attrs] {
lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
}
return $privs
}
proc twapi::disable_token_privileges {tok privs} {
set luid_attrs [list]
foreach priv $privs {
lappend luid_attrs [list [map_privilege_to_luid $priv] 0]
}
set privs [list ]
foreach {item} [Twapi_AdjustTokenPrivileges $tok 0 $luid_attrs] {
lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
}
return $privs
}
proc twapi::disable_all_token_privileges {tok} {
set privs [list ]
foreach {item} [Twapi_AdjustTokenPrivileges $tok 1 [list ]] {
lappend privs [map_luid_to_privilege [lindex $item 0] -mapunknown]
}
return $privs
}
proc twapi::map_luid_to_privilege {luid args} {
array set opts [parseargs args [list system.arg mapunknown] -nulldefault]
if {[is_valid_luid_syntax $luid]} {
try {
set name [LookupPrivilegeName $opts(system) $luid]
} onerror {TWAPI_WIN32 1313} {
if {! $opts(mapunknown)} {
error $errorResult $errorInfo $errorCode
}
set name "Privilege-$luid"
}
} else {
if {[catch {map_privilege_to_luid $luid -system $opts(system)}]} {
error "Invalid LUID '$luid'"
}
return $luid;                   # $luid is itself a priv name
}
return $name
}
proc twapi::map_privilege_to_luid {priv args} {
array set opts [parseargs args [list system.arg] -nulldefault]
if {[string match "Privilege-*" $priv]} {
set priv [string range $priv 10 end]
}
if {[is_valid_luid_syntax $priv]} {
return $priv
}
return [LookupPrivilegeValue $opts(system) $priv]
}
proc twapi::is_valid_luid_syntax {luid} {
return [regexp {^[[:xdigit:]]{8}-[[:xdigit:]]{8}$} $luid]
}
proc twapi::new_ace {type account rights args} {
variable windefs
array set opts [parseargs args {
{self.bool 1}
{recursecontainers.bool 0}
{recurseobjects.bool 0}
{recurseonelevelonly.bool 0}
}]
set sid [map_account_to_sid $account]
set access_mask [_access_rights_to_mask $rights]
switch -exact -- $type {
allow -
deny  -
audit {
set typecode [_ace_type_symbol_to_code $type]
}
default {
error "Invalid or unsupported ACE type '$type'"
}
}
set inherit_flags 0
if {! $opts(self)} {
setbits inherit_flags $windefs(INHERIT_ONLY_ACE)
}
if {$opts(recursecontainers)} {
setbits inherit_flags $windefs(CONTAINER_INHERIT_ACE)
}
if {$opts(recurseobjects)} {
setbits inherit_flags $windefs(OBJECT_INHERIT_ACE)
}
if {$opts(recurseonelevelonly)} {
setbits inherit_flags $windefs(NO_PROPAGATE_INHERIT_ACE)
}
return [list $typecode $inherit_flags $access_mask $sid]
}
proc twapi::get_ace_type {ace} {
return [_ace_type_code_to_symbol [lindex $ace 0]]
}
proc twapi::set_ace_type {ace type} {
return [lreplace $ace 0 0 [_ace_type_symbol_to_code $type]]
}
proc twapi::get_ace_rights {ace args} {
array set opts [parseargs args {type.arg raw} -nulldefault]
if {$opts(raw)} {
return [format 0x%x [lindex $ace 2]]
} else {
return [_access_mask_to_rights [lindex $ace 2] $opts(type)]
}
}
proc twapi::set_ace_rights {ace rights} {
return [lreplace $ace 2 2 [_access_rights_to_mask $rights]]
}
proc twapi::get_ace_sid {ace} {
return [lindex $ace 3]
}
proc twapi::set_ace_sid {ace account} {
return [lreplace $ace 3 3 [map_account_to_sid $account]]
}
proc twapi::get_ace_inheritance {ace} {
variable windefs
set inherit_opts [list ]
set inherit_mask [lindex $ace 1]
lappend inherit_opts -self \
[expr {($inherit_mask & $windefs(INHERIT_ONLY_ACE)) == 0}]
lappend inherit_opts -recursecontainers \
[expr {($inherit_mask & $windefs(CONTAINER_INHERIT_ACE)) != 0}]
lappend inherit_opts -recurseobjects \
[expr {($inherit_mask & $windefs(OBJECT_INHERIT_ACE)) != 0}]
lappend inherit_opts -recurseonelevelonly \
[expr {($inherit_mask & $windefs(NO_PROPAGATE_INHERIT_ACE)) != 0}]
lappend inherit_opts -inherited \
[expr {($inherit_mask & $windefs(INHERITED_ACE)) != 0}]
return $inherit_opts
}
proc twapi::set_ace_inheritance {ace args} {
variable windefs
array set opts [parseargs args {
self.bool
recursecontainers.bool
recurseobjects.bool
recurseonelevelonly.bool
}]
set inherit_flags [lindex $ace 1]
if {[info exists opts(self)]} {
if {$opts(self)} {
resetbits inherit_flags $windefs(INHERIT_ONLY_ACE)
} else {
setbits   inherit_flags $windefs(INHERIT_ONLY_ACE)
}
}
foreach {
opt                 mask
} {
recursecontainers   CONTAINER_INHERIT_ACE
recurseobjects      OBJECT_INHERIT_ACE
recurseonelevelonly NO_PROPAGATE_INHERIT_ACE
} {
if {[info exists opts($opt)]} {
if {$opts($opt)} {
setbits inherit_flags $windefs($mask)
} else {
resetbits inherit_flags $windefs($mask)
}
}
}
return [lreplace $ace 1 1 $inherit_flags]
}
proc twapi::sort_aces {aces} {
variable windefs
_init_ace_type_symbol_to_code_map
foreach type [array names twapi::_ace_type_symbol_to_code_map] {
set direct_aces($type) [list ]
set inherited_aces($type) [list ]
}
foreach ace $aces {
set type [get_ace_type $ace]
if {[lindex $ace 1] & $windefs(INHERITED_ACE)} {
lappend inherited_aces($type) $ace
} else {
lappend direct_aces($type) $ace
}
}
return [concat \
$direct_aces(deny) \
$direct_aces(deny_object) \
$direct_aces(deny_callback) \
$direct_aces(deny_callback_object) \
$direct_aces(allow) \
$direct_aces(allow_object) \
$direct_aces(allow_compound) \
$direct_aces(allow_callback) \
$direct_aces(allow_callback_object) \
$direct_aces(audit) \
$direct_aces(audit_object) \
$direct_aces(audit_callback) \
$direct_aces(audit_callback_object) \
$direct_aces(alarm) \
$direct_aces(alarm_object) \
$direct_aces(alarm_callback) \
$direct_aces(alarm_callback_object) \
$inherited_aces(deny) \
$inherited_aces(deny_object) \
$inherited_aces(deny_callback) \
$inherited_aces(deny_callback_object) \
$inherited_aces(allow) \
$inherited_aces(allow_object) \
$inherited_aces(allow_compound) \
$inherited_aces(allow_callback) \
$inherited_aces(allow_callback_object) \
$inherited_aces(audit) \
$inherited_aces(audit_object) \
$inherited_aces(audit_callback) \
$inherited_aces(audit_callback_object) \
$inherited_aces(alarm) \
$inherited_aces(alarm_object) \
$inherited_aces(alarm_callback) \
$inherited_aces(alarm_callback_object)]
}
proc twapi::get_ace_text {ace args} {
array set opts [parseargs args {
{resourcetype.arg raw}
{offset.arg ""}
} -maxleftover 0]
if {$ace eq "null"} {
return "Null"
}
set offset $opts(offset)
array set bools {0 No 1 Yes}
array set inherit_flags [get_ace_inheritance $ace]
append inherit_text "${offset}Inherited: $bools($inherit_flags(-inherited))\n"
append inherit_text "${offset}Include self: $bools($inherit_flags(-self))\n"
append inherit_text "${offset}Recurse containers: $bools($inherit_flags(-recursecontainers))\n"
append inherit_text "${offset}Recurse objects: $bools($inherit_flags(-recurseobjects))\n"
append inherit_text "${offset}Recurse single level only: $bools($inherit_flags(-recurseonelevelonly))\n"
set rights [get_ace_rights $ace -type $opts(resourcetype)]
if {[lsearch -glob $rights *_all_access] >= 0} {
set rights "All"
} else {
set rights [join $rights ", "]
}
append result "${offset}Type: [string totitle [get_ace_type $ace]]\n"
append result "${offset}User: [map_account_to_name [get_ace_sid $ace]]\n"
append result "${offset}Rights: $rights\n"
append result $inherit_text
return $result
}
proc twapi::new_acl {{aces ""}} {
variable windefs
set acl_rev $windefs(ACL_REVISION)
foreach ace $aces {
set ace_typecode [lindex $ace 0]
if {$ace_typecode != $windefs(ACCESS_ALLOWED_ACE_TYPE) &&
$ace_typecode != $windefs(ACCESS_DENIED_ACE_TYPE) &&
$ace_typecode != $windefs(SYSTEM_AUDIT_ACE_TYPE)} {
set acl_rev $windefs(ACL_REVISION_DS)
break
}
}
return [list $acl_rev $aces]
}
proc twapi::get_acl_aces {acl} {
return [lindex $acl 1]
}
proc twapi::set_acl_aces {acl aces} {
return [new_acl $aces]
}
proc twapi::append_acl_aces {acl aces} {
return [set_acl_aces $acl [concat [get_acl_aces $acl] $aces]]
}
proc twapi::prepend_acl_aces {acl aces} {
return [set_acl_aces $acl [concat $aces [get_acl_aces $acl]]]
}
proc twapi::sort_acl_aces {acl} {
return [set_acl_aces $acl [sort_aces [get_acl_aces $acl]]]
}
proc twapi::get_acl_rev {acl} {
return [lindex $acl 0]
}
proc twapi::new_security_descriptor {args} {
array set opts [parseargs args {
owner.arg
group.arg
dacl.arg
sacl.arg
}]
set secd [Twapi_InitializeSecurityDescriptor]
foreach field {owner group dacl sacl} {
if {[info exists opts($field)]} {
set secd [set_security_descriptor_$field $secd $opts($field)]
}
}
return $secd
}
proc twapi::get_security_descriptor_control {secd} {
if {[_null_secd $secd]} {
error "Attempt to get control field from NULL security descriptor."
}
set control [lindex $secd 0]
set retval [list ]
if {$control & 0x0001} {
lappend retval owner_defaulted
}
if {$control & 0x0002} {
lappend retval group_defaulted
}
if {$control & 0x0004} {
lappend retval dacl_present
}
if {$control & 0x0008} {
lappend retval dacl_defaulted
}
if {$control & 0x0010} {
lappend retval sacl_present
}
if {$control & 0x0020} {
lappend retval sacl_defaulted
}
if {$control & 0x0100} {
lappend retval dacl_auto_inherit_req
}
if {$control & 0x0200} {
lappend retval sacl_auto_inherit_req
}
if {$control & 0x0400} {
lappend retval dacl_auto_inherited
}
if {$control & 0x0800} {
lappend retval sacl_auto_inherited
}
if {$control & 0x1000} {
lappend retval dacl_protected
}
if {$control & 0x2000} {
lappend retval sacl_protected
}
if {$control & 0x4000} {
lappend retval rm_control_valid
}
if {$control & 0x8000} {
lappend retval self_relative
}
return $retval
}
proc twapi::get_security_descriptor_owner {secd} {
if {[_null_secd $secd]} {
win32_error 87 "Attempt to get owner field from NULL security descriptor."
}
return [lindex $secd 1]
}
proc twapi::set_security_descriptor_owner {secd account} {
if {[_null_secd $secd]} {
set secd [new_security_descriptor]
}
set sid [map_account_to_sid $account]
return [lreplace $secd 1 1 $sid]
}
proc twapi::get_security_descriptor_group {secd} {
if {[_null_secd $secd]} {
win32_error 87 "Attempt to get group field from NULL security descriptor."
}
return [lindex $secd 2]
}
proc twapi::set_security_descriptor_group {secd account} {
if {[_null_secd $secd]} {
set secd [new_security_descriptor]
}
set sid [map_account_to_sid $account]
return [lreplace $secd 2 2 $sid]
}
proc twapi::get_security_descriptor_dacl {secd} {
if {[_null_secd $secd]} {
win32_error 87 "Attempt to get DACL field from NULL security descriptor."
}
return [lindex $secd 3]
}
proc twapi::set_security_descriptor_dacl {secd acl} {
if {[_null_secd $secd]} {
set secd [new_security_descriptor]
}
return [lreplace $secd 3 3 $acl]
}
proc twapi::get_security_descriptor_sacl {secd} {
if {[_null_secd $secd]} {
win32_error 87 "Attempt to get SACL field from NULL security descriptor."
}
return [lindex $secd 4]
}
proc twapi::set_security_descriptor_sacl {secd acl} {
if {[_null_secd $secd]} {
set secd [new_security_descriptor]
}
return [lreplace $secd 4 4 $acl]
}
proc twapi::get_resource_security_descriptor {restype name args} {
variable windefs
array set opts [parseargs args {
owner
group
dacl
sacl
all
handle
}]
set wanted 0
foreach field {owner group dacl sacl} {
if {$opts($field) || $opts(all)} {
set wanted [expr {$wanted | $windefs([string toupper $field]_SECURITY_INFORMATION)}]
}
}
if {! $wanted} {
foreach field {owner group dacl} {
set wanted [expr {$wanted | $windefs([string toupper $field]_SECURITY_INFORMATION)}]
}
set opts($field) 1
}
if {$opts(handle)} {
set secd [Twapi_GetSecurityInfo \
[CastToHANDLE $name] \
[_map_resource_symbol_to_type $restype false] \
$wanted]
} else {
try {
set secd [Twapi_GetNamedSecurityInfo \
$name \
[_map_resource_symbol_to_type $restype true] \
$wanted]
} onerror {} {
if {$restype eq "share"} {
set secd [lindex [get_share_info $name -secd] 1]
} else {
error $errorResult $errorInfo $errorCode
}
}
}
return $secd
}
proc twapi::set_resource_security_descriptor {restype name secd args} {
variable windefs
array set opts [parseargs args {
handle
owner
group
dacl
sacl
all
protect_dacl
unprotect_dacl
protect_sacl
unprotect_sacl
}]
set mask 0
if {[min_os_version 5 0]} {
if {$opts(protect_dacl) && $opts(unprotect_dacl)} {
error "Cannot specify both -protect_dacl and -unprotect_dacl."
}
if {$opts(protect_dacl)} {
setbits mask $windefs(PROTECTED_DACL_SECURITY_INFORMATION)
}
if {$opts(unprotect_dacl)} {
setbits mask $windefs(UNPROTECTED_DACL_SECURITY_INFORMATION)
}
if {$opts(protect_sacl) && $opts(unprotect_sacl)} {
error "Cannot specify both -protect_sacl and -unprotect_sacl."
}
if {$opts(protect_sacl)} {
setbits mask $windefs(PROTECTED_SACL_SECURITY_INFORMATION)
}
if {$opts(unprotect_sacl)} {
setbits mask $windefs(UNPROTECTED_SACL_SECURITY_INFORMATION)
}
}
if {$opts(owner) || $opts(all)} {
set opts(owner) [get_security_descriptor_owner $secd]
setbits mask $windefs(OWNER_SECURITY_INFORMATION)
} else {
set opts(owner) ""
}
if {$opts(group) || $opts(all)} {
set opts(group) [get_security_descriptor_group $secd]
setbits mask $windefs(GROUP_SECURITY_INFORMATION)
} else {
set opts(group) ""
}
if {$opts(dacl) || $opts(all)} {
set opts(dacl) [get_security_descriptor_dacl $secd]
setbits mask $windefs(DACL_SECURITY_INFORMATION)
} else {
set opts(dacl) null
}
if {$opts(sacl) || $opts(all)} {
set opts(sacl) [get_security_descriptor_sacl $secd]
setbits mask $windefs(SACL_SECURITY_INFORMATION)
} else {
set opts(sacl) null
}
if {$opts(handle)} {
SetSecurityInfo \
[CastToHANDLE $name] \
[_map_resource_symbol_to_type $restype false] \
$mask \
$opts(owner) \
$opts(group) \
$opts(dacl) \
$opts(sacl)
} else {
SetNamedSecurityInfo \
$name \
[_map_resource_symbol_to_type $restype true] \
$mask \
$opts(owner) \
$opts(group) \
$opts(dacl) \
$opts(sacl)
}
}
proc twapi::get_security_descriptor_text {secd args} {
if {[_null_secd $secd]} {
return "null"
}
array set opts [parseargs args {
{resourcetype.arg raw}
} -maxleftover 0]
append result "Flags:\t[get_security_descriptor_control $secd]\n"
append result "Owner:\t[map_account_to_name [get_security_descriptor_owner $secd]]\n"
append result "Group:\t[map_account_to_name [get_security_descriptor_group $secd]]\n"
set acl [get_security_descriptor_dacl $secd]
append result "DACL Rev: [get_acl_rev $acl]\n"
set index 0
foreach ace [get_acl_aces $acl] {
append result "\tDACL Entry [incr index]\n"
append result "[get_ace_text $ace -offset "\t    " -resourcetype $opts(resourcetype)]"
}
set acl [get_security_descriptor_sacl $secd]
append result "SACL Rev: [get_acl_rev $acl]\n"
set index 0
foreach ace [get_acl_aces $acl] {
append result "\tSACL Entry $index\n"
append result "[get_ace_text $ace -offset "\t    " -resourcetype $opts(resourcetype)]"
}
return $result
}
proc twapi::logoff {args} {
array set opts [parseargs args {force forceifhung}]
set flags 0
if {$opts(force)} {setbits flags 0x4}
if {$opts(forceifhung)} {setbits flags 0x10}
ExitWindowsEx $flags 0
}
proc twapi::lock_workstation {} {
LockWorkStation
}
proc twapi::new_luid {} {
return [AllocateLocallyUniqueId]
}
proc twapi::new_uuid {{opt ""}} {
if {[string length $opt]} {
if {[string equal $opt "-localok"]} {
set local_ok 1
} else {
error "Invalid or unknown argument '$opt'"
}
} else {
set local_ok 0
}
return [UuidCreate $local_ok] 
}
proc twapi::nil_uuid {} {
return [UuidCreateNil]
}
proc twapi::get_privilege_description {priv} {
if {[catch {LookupPrivilegeDisplayName "" $priv} desc]} {
switch -exact -- $priv {
SeBatchLogonRight { set desc "Log on as a batch job" }
SeDenyBatchLogonRight { set desc "Deny logon as a batch job" }
SeDenyInteractiveLogonRight { set desc "Deny logon locally" }
SeDenyNetworkLogonRight { set desc "Deny access to this computer from the network" }
SeDenyServiceLogonRight { set desc "Deny logon as a service" }
SeInteractiveLogonRight { set desc "Log on locally" }
SeNetworkLogonRight { set desc "Access this computer from the network" }
SeServiceLogonRight { set desc "Log on as a service" }
default {set desc ""}
}
}
return $desc
}
proc twapi::GetUserName {} {
return [file tail [GetUserNameEx 2]]
}
proc twapi::_get_token_sid_field {tok field options} {
array set opts [parseargs options {name}]
set owner [GetTokenInformation $tok $twapi::windefs($field)]
if {$opts(name)} {
set owner [lookup_account_sid $owner]
}
return $owner
}
proc twapi::_map_token_attr {attr names prefix} {
variable windefs
set attrs [list ]
foreach attr_name $names {
set attr_mask $windefs(${prefix}_[string toupper $attr_name])
if {[expr {$attr & $attr_mask}]} {
lappend attrs $attr_name
}
}
return $attrs
}
proc twapi::_access_rights_to_mask {args} {
variable windefs
set rights 0
foreach right [eval concat $args] {
if {![string is integer $right]} {
if {$right == "token_all_access"} {
if {[min_os_version 5 0]} {
set right $windefs(TOKEN_ALL_ACCESS_WIN2K)
} else {
set right $windefs(TOKEN_ALL_ACCESS_WIN2K)
}
} else {
if {[catch {set right $windefs([string toupper $right])}]} {
error "Invalid access right symbol '$right'"
}
}
}
set rights [expr {$rights | $right}]
}
return $rights
}
proc twapi::_access_mask_to_rights {access_mask {type ""}} {
variable windefs
set rights [list ]
foreach x {STANDARD_RIGHTS_REQUIRED STANDARD_RIGHTS_READ STANDARD_RIGHTS_WRITE STANDARD_RIGHTS_EXECUTE STANDARD_RIGHTS_ALL SPECIFIC_RIGHTS_ALL} {
if {($windefs($x) & $access_mask) == $windefs($x)} {
lappend rights [string tolower $x]
}
}
switch -exact -- $type {
file {
set masks [list FILE_ALL_ACCESS FILE_GENERIC_READ FILE_GENERIC_WRITE FILE_GENERIC_EXECUTE]
}
pipe {
set masks [list FILE_ALL_ACCESS]
}
service {
set masks [list SERVICE_ALL_ACCESS]
}
registry {
set masks [list KEY_READ KEY_WRITE KEY_EXECUTE KEY_ALL_ACCESS]
}
process {
set masks [list PROCESS_ALL_ACCESS]
}
thread {
set masks [list THREAD_ALL_ACCESS]
}
token {
set masks [list TOKEN_READ TOKEN_WRITE TOKEN_EXECUTE]
if {[min_os_version 5 0]} {
set token_all_access $windefs(TOKEN_ALL_ACCESS_WIN2K)
} else {
set token_all_access $windefs(TOKEN_ALL_ACCESS_WIN2K)
}
if {($token_all_access & $access_mask) == $token_all_access} {
lappend rights "token_all_access"
}
}
desktop {
}
winsta {
set masks [list WINSTA_ALL_ACCESS]
}
default {
set masks [list ]
}
}
foreach x $masks {
if {($windefs($x) & $access_mask) == $windefs($x)} {
lappend rights [string tolower $x]
}
}
foreach x {DELETE READ_CONTROL WRITE_DAC WRITE_OWNER SYNCHRONIZE} {
if {$windefs($x) & $access_mask} {
lappend rights [string tolower $x]
resetbits access_mask $windefs($x)
}
}
foreach x {GENERIC_READ GENERIC_WRITE GENERIC_EXECUTE GENERIC_ALL} {
if {$windefs($x) & $access_mask} {
lappend rights [string tolower $x]
resetbits access_mask $windefs($x)
}
}
switch -exact -- $type {
file {
set masks {
FILE_READ_DATA
FILE_WRITE_DATA
FILE_APPEND_DATA
FILE_READ_EA
FILE_WRITE_EA
FILE_EXECUTE
FILE_DELETE_CHILD
FILE_READ_ATTRIBUTES
FILE_WRITE_ATTRIBUTES
}
}
pipe {
set masks {
FILE_READ_DATA
FILE_WRITE_DATA
FILE_CREATE_PIPE_INSTANCE
FILE_READ_ATTRIBUTES
FILE_WRITE_ATTRIBUTES
}
}
service {
set masks {
SERVICE_QUERY_CONFIG
SERVICE_CHANGE_CONFIG
SERVICE_QUERY_STATUS
SERVICE_ENUMERATE_DEPENDENTS
SERVICE_START
SERVICE_STOP
SERVICE_PAUSE_CONTINUE
SERVICE_INTERROGATE
SERVICE_USER_DEFINED_CONTROL
}
}
registry {
set masks {
KEY_QUERY_VALUE
KEY_SET_VALUE
KEY_CREATE_SUB_KEY
KEY_ENUMERATE_SUB_KEYS
KEY_NOTIFY
KEY_CREATE_LINK
KEY_WOW64_32KEY
KEY_WOW64_64KEY
KEY_WOW64_RES
}
}
process {
set masks {
PROCESS_TERMINATE
PROCESS_CREATE_THREAD
PROCESS_SET_SESSIONID
PROCESS_VM_OPERATION
PROCESS_VM_READ
PROCESS_VM_WRITE
PROCESS_DUP_HANDLE
PROCESS_CREATE_PROCESS
PROCESS_SET_QUOTA
PROCESS_SET_INFORMATION
PROCESS_QUERY_INFORMATION
PROCESS_SUSPEND_RESUME
}
}
thread {
set masks {
THREAD_TERMINATE
THREAD_SUSPEND_RESUME
THREAD_GET_CONTEXT
THREAD_SET_CONTEXT
THREAD_SET_INFORMATION
THREAD_QUERY_INFORMATION
THREAD_SET_THREAD_TOKEN
THREAD_IMPERSONATE
THREAD_DIRECT_IMPERSONATION
}
}
token {
set masks {
TOKEN_ASSIGN_PRIMARY
TOKEN_DUPLICATE
TOKEN_IMPERSONATE
TOKEN_QUERY
TOKEN_QUERY_SOURCE
TOKEN_ADJUST_PRIVILEGES
TOKEN_ADJUST_GROUPS
TOKEN_ADJUST_DEFAULT
TOKEN_ADJUST_SESSIONID
}
}
desktop {
set masks {
DESKTOP_READOBJECTS
DESKTOP_CREATEWINDOW
DESKTOP_CREATEMENU
DESKTOP_HOOKCONTROL
DESKTOP_JOURNALRECORD
DESKTOP_JOURNALPLAYBACK
DESKTOP_ENUMERATE
DESKTOP_WRITEOBJECTS
DESKTOP_SWITCHDESKTOP
}
}
windowstation -
winsta {
set masks {
WINSTA_ENUMDESKTOPS
WINSTA_READATTRIBUTES
WINSTA_ACCESSCLIPBOARD
WINSTA_CREATEDESKTOP
WINSTA_WRITEATTRIBUTES
WINSTA_ACCESSGLOBALATOMS
WINSTA_EXITWINDOWS
WINSTA_ENUMERATE
WINSTA_READSCREEN
}
}
default {
set masks [list ]
}
}
foreach x $masks {
if {$windefs($x) & $access_mask} {
lappend rights [string tolower $x]
resetbits access_mask $windefs($x)
}
}
for {set i 0} {$i < 32} {incr i} {
set x [expr {1 << $i}]
if {$access_mask & $x} {
lappend rights [format 0x%.8X $x]
}
}
return $rights
}
proc twapi::_ace_type_symbol_to_code {type} {
_init_ace_type_symbol_to_code_map
return $::twapi::_ace_type_symbol_to_code_map($type)
}
proc twapi::_ace_type_code_to_symbol {type} {
_init_ace_type_symbol_to_code_map
return $::twapi::_ace_type_code_to_symbol_map($type)
}
proc twapi::_init_ace_type_symbol_to_code_map {} {
variable windefs
if {[info exists ::twapi::_ace_type_symbol_to_code_map]} {
return
}
array set ::twapi::_ace_type_symbol_to_code_map \
[list \
allow [expr { $windefs(ACCESS_ALLOWED_ACE_TYPE) + 0 }] \
deny [expr  { $windefs(ACCESS_DENIED_ACE_TYPE) + 0 }] \
audit [expr { $windefs(SYSTEM_AUDIT_ACE_TYPE) + 0 }] \
alarm [expr { $windefs(SYSTEM_ALARM_ACE_TYPE) + 0 }] \
allow_compound [expr { $windefs(ACCESS_ALLOWED_COMPOUND_ACE_TYPE) + 0 }] \
allow_object [expr   { $windefs(ACCESS_ALLOWED_OBJECT_ACE_TYPE) + 0 }] \
deny_object [expr    { $windefs(ACCESS_DENIED_OBJECT_ACE_TYPE) + 0 }] \
audit_object [expr   { $windefs(SYSTEM_AUDIT_OBJECT_ACE_TYPE) + 0 }] \
alarm_object [expr   { $windefs(SYSTEM_ALARM_OBJECT_ACE_TYPE) + 0 }] \
allow_callback [expr { $windefs(ACCESS_ALLOWED_CALLBACK_ACE_TYPE) + 0 }] \
deny_callback [expr  { $windefs(ACCESS_DENIED_CALLBACK_ACE_TYPE) + 0 }] \
allow_callback_object [expr { $windefs(ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE) + 0 }] \
deny_callback_object [expr  { $windefs(ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE) + 0 }] \
audit_callback [expr { $windefs(SYSTEM_AUDIT_CALLBACK_ACE_TYPE) + 0 }] \
alarm_callback [expr { $windefs(SYSTEM_ALARM_CALLBACK_ACE_TYPE) + 0 }] \
audit_callback_object [expr { $windefs(SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE) + 0 }] \
alarm_callback_object [expr { $windefs(SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE) + 0 }] \
]
foreach {sym code} [array get ::twapi::_ace_type_symbol_to_code_map] {
set ::twapi::_ace_type_code_to_symbol_map($code) $sym
}
}
proc twapi::_make_secattr {secd inherit} {
if {$inherit} {
set sec_attr [list $secd 1]
} else {
if {$secd == ""} {
set sec_attr [list ]
} else {
set sec_attr [list $secd 0]
}
}
return $sec_attr
}
proc twapi::_map_resource_symbol_to_type {sym {named true}} {
if {[string is integer $sym]} {
return $sym
}
switch -exact -- $sym {
file      { return 1 }
service   { return 2 }
printer   { return 3 }
registry  { return 4 }
share     { return 5 }
kernelobj { return 6 }
}
if {$named} {
error "Resource type '$restype' not valid for named resources."
}
switch -exact -- $sym {
windowstation    { return 7 }
directoryservice { return 8 }
directoryserviceall { return 9 }
providerdefined { return 10 }
wmiguid { return 111 }
registrywow6432key { return 12 }
}
error "Resource type '$restype' not valid"
}
proc twapi::_is_valid_luid_syntax luid {
return [regexp {^[[:xdigit:]]{8}-[[:xdigit:]]{8}$} $luid]
}
proc twapi::_delete_rights {account system} {
catch {
remove_account_rights $account {} -all -system $system
foreach {major minor sp dontcare} [get_os_version] break
if {($major == 5) && ($minor == 0) && ($sp < 3)} {
after 1000
}
}
}
set twapi::logon_session_type_map {
0
1
interactive
network
batch
service
proxy
unlockworkstation
networkclear
newcredentials
remoteinteractive
cachedinteractive
cachedremoteinteractive
cachedunlockworkstation
}
proc twapi::_null_secd {secd} {
if {[llength $secd] == 0} {
return 1
} else {
return 0
}
}
proc twapi::_is_valid_acl {acl} {
if {$acl eq "null"} {
return 1
} else {
return [IsValidAcl $acl]
}
}
proc twapi::_is_valid_security_descriptor {secd} {
if {[_null_secd $secd]} {
return 1
} else {
return [IsValidSecurityDescriptor $secd]
}
}
#-- from services.tcl
namespace eval twapi {
variable service_state
variable service_state_values
array set service_state_values {
stopped       1
start_pending 2
stop_pending  3
running       4
continue_pending 5
pause_pending 6
paused        7
}
}
proc twapi::lock_scm_db {args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(SC_MANAGER_LOCK)]
try {
set lock [LockServiceDatabase $scm]
} finally {
CloseServiceHandle $scm
}
return $lock
}
proc twapi::unlock_scm_db {lock} {
UnlockServiceDatabase $lock
}
proc twapi::query_scm_db_lock_status {v_lockinfo args} {
variable windefs
upvar $v_lockinfo lockinfo
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(SC_MANAGER_QUERY_LOCK_STATUS)]
try {
array set lock_status [QueryServiceLockStatus $scm]
set lockinfo [list $lock_status(lpLockOwner) $lock_status(dwLockDuration)]
} finally {
CloseServiceHandle $scm
}
return $lock_status(fIsLocked)
}
proc twapi::service_exists {name args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(STANDARD_RIGHTS_READ)]
try {
GetServiceKeyName $scm $name
set exists 1
} onerror {TWAPI_WIN32 1060} {
try {
GetServiceDisplayName $scm $name
set exists 1
} onerror {TWAPI_WIN32 1060} {
set exists 0
}
} finally {
CloseServiceHandle $scm
}
return $exists
}
proc twapi::create_service {name command args} {
variable windefs
array set opts [parseargs args {
displayname.arg
{servicetype.arg     win32_own_process {win32_own_process win32_share_process file_system_driver kernel_driver}}
{interactive.bool    0}
{starttype.arg       auto_start {auto_start boot_start demand_start disabled system_start}}
{errorcontrol.arg    normal {ignore normal severe critical}}
loadordergroup.arg
dependencies.arg
account.arg
password.arg
system.arg
database.arg
} -nulldefault]
if {[string length $opts(displayname)] == 0} {
set opts(displayname) $name
}
if {[string length $command] == 0} {
error "The executable path must not be null when creating a service"
}
set opts(command) $command
switch -exact -- $opts(servicetype) {
file_system_driver -
kernel_driver {
if {$opts(interactive)} {
error "Option -interactive cannot be specified when -servicetype is $opts(servicetype)."
}
}
default {
if {$opts(interactive) && [string length $opts(account)]} {
error "Option -interactive cannot be specified with the -account option as interactive services must run under the LocalSystem account."
}
if {[string equal $opts(starttype) "boot_start"]
|| [string equal $opts(starttype) "system_start"]} {
error "Option -starttype value must be one of auto_start, demand_start or disabled when -servicetype is '$opts(servicetype)'."
}
}
}
set opts(servicetype)  $windefs(SERVICE_[string toupper $opts(servicetype)])
set opts(starttype)    $windefs(SERVICE_[string toupper $opts(starttype)])
set opts(errorcontrol) $windefs(SERVICE_ERROR_[string toupper $opts(errorcontrol)])
if {$opts(interactive)} {
setbits opts(servicetype) $windefs(SERVICE_INTERACTIVE_PROCESS)
}
if {[string length $opts(account)] == 0} {
set opts(password) ""
} else {
if {[string first \\ $opts(account)] < 0} {
set opts(account) ".\\$opts(account)"
}
}
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(SC_MANAGER_CREATE_SERVICE)]
try {
set svch [CreateService \
$scm \
$name \
$opts(displayname) \
$windefs(SERVICE_ALL_ACCESS) \
$opts(servicetype) \
$opts(starttype) \
$opts(errorcontrol) \
$opts(command) \
$opts(loadordergroup) \
NULL \
$opts(dependencies) \
$opts(account) \
$opts(password)]
CloseServiceHandle $svch
} finally {
CloseServiceHandle $scm
}
return
}
proc twapi::delete_service {name args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set opts(scm_priv) DELETE
set opts(svc_priv) DELETE
set opts(proc)     twapi::DeleteService
_service_fn_wrapper $name opts
return
}
proc twapi::get_service_internal_name {name args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(STANDARD_RIGHTS_READ)]
try {
if {[catch {GetServiceKeyName $scm $name} internal_name]} {
GetServiceDisplayName $scm $name; # Will throw an error if not internal name
set internal_name $name
}
} finally {
CloseServiceHandle $scm
}
return $internal_name
}
proc twapi::get_service_display_name {name args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(STANDARD_RIGHTS_READ)]
try {
if {[catch {GetServiceDisplayName $scm $name} display_name]} {
GetServiceKeyName $scm $name; # Will throw an error if not display name
set display_name $name
}
} finally {
CloseServiceHandle $scm
}
return $display_name
}
proc twapi::start_service {name args} {
variable windefs
array set opts [parseargs args {
system.arg
database.arg
params.arg
wait.int
} -nulldefault]
set opts(svc_priv) SERVICE_START
set opts(proc)     twapi::StartService
set opts(args)     [list $opts(params)]
unset opts(params)
try {
_service_fn_wrapper $name opts
} onerror {TWAPI_WIN32 1056} {
}
return [wait {twapi::get_service_state $name -system $opts(system) -database $opts(database)} running $opts(wait)]
}
proc twapi::control_service {name code access finalstate args} {
variable windefs
array set opts [parseargs args {
system.arg
database.arg
ignorecodes.arg
wait.int
} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(STANDARD_RIGHTS_READ)]
try {
set svch [OpenService $scm $name $access]
} finally {
CloseServiceHandle $scm
}
SERVICE_STATUS svc_status
try {
ControlService $svch $code svc_status
} onerror {TWAPI_WIN32} {
if {[lsearch -exact -integer $opts(ignorecodes) [lindex $errorCode 1]] < 0} {
error $errorResult $errorInfo $errorCode
}
} finally {
svc_status -delete
CloseServiceHandle $svch
}
if {[string length $finalstate]} {
return [wait {twapi::get_service_state $name -system $opts(system) -database $opts(database)} $finalstate $opts(wait)]
} else {
return 0
}
}
proc twapi::stop_service {name args} {
variable windefs
eval [list control_service $name \
$windefs(SERVICE_CONTROL_STOP) $windefs(SERVICE_STOP) stopped -ignorecodes 1062] $args
}
proc twapi::pause_service {name args} {
variable windefs
eval [list control_service $name \
$windefs(SERVICE_CONTROL_PAUSE) \
$windefs(SERVICE_PAUSE_CONTINUE) paused] $args
}
proc twapi::continue_service {name args} {
variable windefs
eval [list control_service $name \
$windefs(SERVICE_CONTROL_CONTINUE) \
$windefs(SERVICE_PAUSE_CONTINUE) running] $args
}
proc twapi::interrogate_service {name args} {
variable windefs
eval [list control_service $name \
$windefs(SERVICE_CONTROL_INTERROGATE) \
$windefs(SERVICE_INTERROGATE) ""] $args
return
}
proc twapi::get_service_status {name args} {
variable windefs
array set opts [parseargs args {system.arg database.arg} -nulldefault]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(STANDARD_RIGHTS_READ)]
try {
set svch [OpenService $scm $name $windefs(SERVICE_QUERY_STATUS)]
} finally {
CloseServiceHandle $scm
}
try {
return [_format_SERVICE_STATUS_EX [QueryServiceStatusEx $svch 0]]
} finally {
CloseServiceHandle $svch
}
}
proc twapi::get_service_state {name args} {
return [kl_get [eval [list get_service_status $name] $args] state]
}
proc twapi::get_service_configuration {name args} {
variable windefs
array set opts [parseargs args {
system.arg
database.arg
all
servicetype
interactive
errorcontrol
starttype
command
loadordergroup
account
displayname
dependencies
description
scm_handle.arg
} -nulldefault]
set opts(svc_priv) SERVICE_QUERY_CONFIG
set opts(proc)     twapi::QueryServiceConfig
array set svc_config [_service_fn_wrapper $name opts]
foreach {servicetype interactive} \
[_map_servicetype_code $svc_config(dwServiceType)] break
set result [list ]
if {$opts(all) || $opts(servicetype)} {
lappend result -servicetype $servicetype
}
if {$opts(all) || $opts(interactive)} {
lappend result -interactive $interactive
}
if {$opts(all) || $opts(errorcontrol)} {
lappend result -errorcontrol [_map_errorcontrol_code $svc_config(dwErrorControl)]
}
if {$opts(all) || $opts(starttype)} {
lappend result -starttype [_map_starttype_code $svc_config(dwStartType)]
}
if {$opts(all) || $opts(command)} {
lappend result -command $svc_config(lpBinaryPathName)
}
if {$opts(all) || $opts(loadordergroup)} {
lappend result -loadordergroup $svc_config(lpLoadOrderGroup)
}
if {$opts(all) || $opts(account)} {
lappend result -account $svc_config(lpServiceStartName)
}
if {$opts(all) || $opts(displayname)} {
lappend result -displayname    $svc_config(lpDisplayName)
}
if {$opts(all) || $opts(dependencies)} {
lappend result -dependencies $svc_config(lpDependencies)
}
if {$opts(all) || $opts(description)} {
if {[catch {
registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\$name" "Description"
} desc]} {
lappend result -description ""
} else {
lappend result -description $desc
}
}
return $result
}
proc twapi::set_service_configuration {name args} {
variable windefs
array set current [get_service_configuration $name -all]
set current(-password) ""; # This is not returned by get_service_configuration
array set specified_args $args
array set opts [parseargs args {
displayname.arg
servicetype.arg
interactive.bool
starttype.arg
errorcontrol.arg
command.arg
loadordergroup.arg
dependencies.arg
account.arg
password.arg
{system.arg ""}
{database.arg ""}
}]
if {[info exists opts(account)] && ! [info exists opts(password)]} {
error "Option -password must also be specified when -account is specified."
}
foreach opt {
displayname
servicetype
interactive
starttype
errorcontrol
command
loadordergroup
dependencies
account
password
} {
if {[info exists opts($opt)]} {
set winparams($opt) $opts($opt)
} else {
set winparams($opt) $current(-$opt)
}
}
switch -exact -- $winparams(servicetype) {
file_system_driver -
kernel_driver {
if {$winparams(interactive)} {
error "Option -interactive cannot be specified when -servicetype is $winparams(servicetype)."
}
}
default {
if {$winparams(interactive) &&
[string length $winparams(account)] &&
[string compare -nocase $winparams(account) "LocalSystem"]
} {
error "Option -interactive cannot be specified with the -account option as interactive services must run under the LocalSystem account."
}
if {[string equal $winparams(starttype) "boot_start"]
|| [string equal $winparams(starttype) "system_start"]} {
error "Option -starttype value must be one of auto_start, demand_start or disabled when -servicetype is '$winparams(servicetype)'."
}
}
}
set winparams(servicetype)  $windefs(SERVICE_[string toupper $winparams(servicetype)])
set winparams(starttype)    $windefs(SERVICE_[string toupper $winparams(starttype)])
set winparams(errorcontrol) $windefs(SERVICE_ERROR_[string toupper $winparams(errorcontrol)])
if {$winparams(interactive)} {
if {![info exists opts(servicetype)]} {
set opts(servicetype) $winparams(servicetype)
}
setbits opts(servicetype) $windefs(SERVICE_INTERACTIVE_PROCESS)
setbits winparams(servicetype) $opts(servicetype)
}
if {[string length $winparams(account)]} {
if {[string first \\ $winparams(account)] < 0} {
set winparams(account) ".\\$winparams(account)"
}
}
foreach opt {servicetype starttype errorcontrol} {
if {![info exists opts($opt)]} {
set winparams($opt) $windefs(SERVICE_NO_CHANGE)
}
}
foreach opt {command loadordergroup dependencies account password displayname} {
if {![info exists opts($opt)]} {
set winparams($opt) $twapi::nullptr
}
}
set opts(scm_priv) STANDARD_RIGHTS_READ
set opts(svc_priv) SERVICE_CHANGE_CONFIG
set opts(proc)     twapi::ChangeServiceConfig
set opts(args) \
[list \
$winparams(servicetype) \
$winparams(starttype) \
$winparams(errorcontrol) \
$winparams(command) \
$winparams(loadordergroup) \
NULL \
$winparams(dependencies) \
$winparams(account) \
$winparams(password) \
$winparams(displayname)]
_service_fn_wrapper $name opts
return
}
proc twapi::get_multiple_service_status {args} {
variable windefs
set service_types [list \
kernel_driver \
file_system_driver \
adapter \
recognizer_driver \
win32_own_process \
win32_share_process]
set switches [concat $service_types \
[list active inactive] \
[list system.arg database.arg]]
array set opts [parseargs args $switches -nulldefault]
set servicetype 0
foreach type $service_types {
if {$opts($type)} {
set servicetype [expr { $servicetype
| $windefs(SERVICE_[string toupper $type])
}]
}
}
if {$servicetype == 0} {
set servicetype [expr {$windefs(SERVICE_KERNEL_DRIVER)
| $windefs(SERVICE_FILE_SYSTEM_DRIVER)
| $windefs(SERVICE_ADAPTER)
| $windefs(SERVICE_RECOGNIZER_DRIVER)
| $windefs(SERVICE_WIN32_OWN_PROCESS)
| $windefs(SERVICE_WIN32_SHARE_PROCESS)}]
}
set servicestate 0
if {$opts(active)} {
set servicestate [expr {$servicestate |
$windefs(SERVICE_ACTIVE)}]
}
if {$opts(inactive)} {
set servicestate [expr {$servicestate |
$windefs(SERVICE_INACTIVE)}]
}
if {$servicestate == 0} {
set servicestate $windefs(SERVICE_STATE_ALL)
}
set servicelist [list ]
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs(SC_MANAGER_ENUMERATE_SERVICE)]
try {
if {[min_os_version 5]} {
set status_recs [EnumServicesStatusEx $scm 0 $servicetype $servicestate __null__]
} else {
set status_recs [EnumServicesStatus $scm $servicetype $servicestate]
}
} finally {
CloseServiceHandle $scm
}
foreach status_rec $status_recs {
lappend servicelist [_format_status_record $status_rec]
}
return $servicelist
}
proc twapi::get_dependent_service_status {name args} {
variable windefs
array set opts [parseargs args \
[list active inactive system.arg database.arg] \
-nulldefault]
set servicestate 0
if {$opts(active)} {
set servicestate [expr {$servicestate |
$windefs(SERVICE_ACTIVE)}]
}
if {$opts(inactive)} {
set servicestate [expr {$servicestate |
$windefs(SERVICE_INACTIVE)}]
}
if {$servicestate == 0} {
set servicestate $windefs(SERVICE_STATE_ALL)
}
set opts(svc_priv) SERVICE_ENUMERATE_DEPENDENTS
set opts(proc)     twapi::EnumDependentServices
set opts(args)     [list $servicestate]
set status_recs [_service_fn_wrapper $name opts]
set servicelist [list ]
foreach status_rec $status_recs {
lappend servicelist [_format_status_record $status_rec]
}
return $servicelist
}
proc twapi::run_as_service {services args} {
variable service_state
if {[llength $services] == 0} {
win32_error 87 "No services specified"
}
array set opts [parseargs args {
interactive.bool
} -nulldefault -maxleftover 0]
if {[llength $services] == 1} {
set type 0x10;          # WIN32_OWN_PROCESS
} else {
set type 0x20;          # WIN32_SHARE_PROCESS
}
if {$opts(interactive)} {
setbits type 0x100;     # INTERACTIVE_PROCESS
}
set service_names [list ]
foreach service $services {
foreach {name script} $service break
set name [string tolower $name]
lappend service_names $name
set service_state($name,state)       stopped
set service_state($name,script)      $script
set service_state($name,checkpoint)  0
set service_state($name,waithint)    2000; # 2 seconds
set service_state($name,exitcode)    0
set service_state($name,servicecode) 0
set service_state($name,seq)         0
set service_state($name,seqack)      0
}
twapi::Twapi_BecomeAService $service_names $type ::twapi::_safe_service_handler
proc ::twapi::run_as_service args {
error "Already running as a service"
}
}
proc twapi::_safe_service_handler {name service_status_handle control args} {
if {[catch {
_service_handler $name $service_status_handle $control $args
} msg]} {
catch {eventlog_log "Error in service handler for service $name. $msg Stack: $::errorInfo" -type error}
}
}
proc twapi::_service_handler {name service_status_handle control extra_args} {
variable service_state
set name [string tolower $name]
set tell_app true
set report_status true
switch -glob -- "$service_state($name,state),$control" {
stopped,start {
set service_state($name,state) start_pending
set service_state($name,checkpoint) 1
}
start_pending,stop -
paused,stop        -
pause_pending,stop -
continue_pending,stop -
running,stop {
set service_state($name,state) stop_pending
set service_state($name,checkpoint) 1
}
running,pause {
set service_state($name,state) pause_pending
set service_state($name,checkpoint) 1
}
pause_pending,continue -
paused,continue {
set service_state($name,state) continue_pending
set service_state($name,checkpoint) 1
}
*,interrogate {
set tell_app false; # No need to bother the application
}
*,userdefined {
set report_status false; # We do not need to report status
}
default {
return
}
}
if {$report_status} {
_report_service_status $name
}
if {$tell_app} {
if {[catch {
incr service_state($name,seq)
eval [linsert $service_state($name,script) end $control $name $service_state($name,seq)] $extra_args
} msg]} {
}
}
}
proc twapi::update_service_status {name seq state args} {
variable service_state
if {[lsearch -exact {running paused stopped} $state] < 0} {
error "Invalid state token $state"
}
array set opts [parseargs args {
exitcode.int
servicecode.int
waithint.int
} -maxleftover 0]
set name [string tolower $name]
if {$service_state($name,seq) < $seq} {
error "Invalid sequence number $seq (too large) for service status update."
}
if {($service_state($name,seq) > $service_state($name,seqack)) &&
($seq == 0 || $seq < $service_state($name,seq))} {
return ignored
}
set service_state($name,seqack) $seq; # last responded sequence number
if {$state eq "stopped"} {
if {[info exists opts(exitcode)]} {
set service_state($name,exitcode) $opts(exitcode)
}
if {[info exists opts(servicecode)]} {
set service_state($name,servicecode) $opts(servicecode)
}
}
upvar 0 service_state($name,state) current_state
if {$state eq $current_state} {
return nochange
}
switch -exact -- $state {
stopped {
}
running {
if {$current_state eq "stopped" || $current_state eq "paused"} {
return invalidchange
}
}
paused {
if {$current_state ne "pause_pending" &&
$current_state ne "continue_pending"} {
return invalidchange
}
}
}
set current_state $state
_report_service_status $name
if {$state eq "stopped"} {
Twapi_StopServiceThread $name
set all_stopped true
foreach {entry val} [array get service_state *,state] {
if {$val ne "stopped"} {
set all_stopped false
break
}
}
if {$all_stopped} {
eval [linsert $service_state($name,script) end all_stopped]
}
}
return changed;             # State changed
}
proc twapi::_report_service_status {name} {
variable service_state
upvar 0 service_state($name,state) current_state
if {[string match *pending $current_state]} {
incr service_state($name,checkpoint)
set waithint $service_state($name,waithint)
} else {
set service_state($name,checkpoint) 0
set waithint 0
}
if {[catch {
Twapi_SetServiceStatus $name $::twapi::service_state_values($current_state) $service_state($name,exitcode) $service_state($name,servicecode) $service_state($name,checkpoint) $waithint
} msg]} {
}
if {$waithint} {
set delay [expr {($waithint*3)/4}]
after $delay ::twapi::_call_scm_within_waithint $name $current_state $service_state($name,checkpoint)
}
return
}
proc ::twapi::_call_scm_within_waithint {name orig_state orig_checkpoint} {
variable service_state
if {($service_state($name,state) eq $orig_state) &&
($service_state($name,checkpoint) == $orig_checkpoint)} {
_report_service_status $name
}
}
proc twapi::_map_servicetype_code {servicetype} {
variable windefs
set interactive [expr {($servicetype & $windefs(SERVICE_INTERACTIVE_PROCESS)) != 0}]
set servicetype [expr {$servicetype & (~$windefs(SERVICE_INTERACTIVE_PROCESS))}]
set service_syms {
win32_own_process win32_share_process kernel_driver
file_system_driver adapter recognizer_driver
}
set servicetype [code_to_symbol $servicetype $service_syms]
return [list $servicetype $interactive]
}
proc twapi::_map_starttype_code {code} {
return [code_to_symbol \
$code {auto_start boot_start demand_start disabled system_start}]
}
proc twapi::_map_errorcontrol_code {code} {
return [code_to_symbol \
$code {ignore normal severe critical} "SERVICE_ERROR_"]
}
proc twapi::_map_state_code {code} {
set states {
stopped start_pending stop_pending running continue_pending
pause_pending paused
}
set state [code_to_symbol $code $states]
}
proc twapi::_format_status_record {status_rec} {
set retval [_format_SERVICE_STATUS_EX $status_rec]
if {[kl_vget $status_rec lpServiceName name]} {
lappend retval name $name
}
if {[kl_vget $status_rec lpDisplayName displayname]} {
lappend retval displayname $displayname
}
return $retval
}
proc twapi::_format_SERVICE_STATUS_EX {svc_status} {
foreach {servicetype interactive} \
[_map_servicetype_code [kl_get $svc_status dwServiceType]] break
set state [_map_state_code [kl_get $svc_status dwCurrentState]]
if {![kl_vget $svc_status dwProcessId pid]} {
if {$state == "stopped"} {
set pid 0
} else {
set pid -1
}
}
set attrs [list ]
if {[kl_vget $svc_status dwServiceFlags flags] &&
($flags & 1)} {
lappend attrs systemprocess
}
return [list \
servicetype  $servicetype \
interactive  $interactive \
state        $state \
controls_accepted [kl_get $svc_status dwControlsAccepted] \
exitcode     [kl_get $svc_status dwWin32ExitCode] \
service_code [kl_get $svc_status dwServiceSpecificExitCode] \
checkpoint   [kl_get $svc_status dwCheckPoint] \
wait_hint    [kl_get $svc_status dwWaitHint] \
pid          $pid \
attrs        $attrs]
}
proc twapi::code_to_symbol {code symlist {prefix "SERVICE_"}} {
variable windefs
foreach sym $symlist {
if {$code == $windefs(${prefix}[string toupper $sym])} {
return $sym
}
}
return $code
}
proc twapi::_service_fn_wrapper {name v_opts} {
variable windefs
upvar $v_opts opts
set scm_priv [expr {[info exists opts(scm_priv)] ? $opts(scm_priv) : "STANDARD_RIGHTS_READ"}]
if {[info exists opts(scm_handle)] &&
$opts(scm_handle) ne ""} {
set scm $opts(scm_handle)
} else {
set scm [OpenSCManager $opts(system) $opts(database) \
$windefs($scm_priv)]
}
try {
set svch [OpenService $scm $name $windefs($opts(svc_priv))]
} finally {
if {(![info exists opts(scm_handle)]) ||
($opts(scm_handle) eq "")} {
CloseServiceHandle $scm
}
}
set proc_args [expr {[info exists opts(args)] ? $opts(args) : ""}]
try {
set results [eval [list $opts(proc) $svch] $proc_args]
} finally {
CloseServiceHandle $svch
}
return $results
}
proc twapi::_service_background_error {winerror msg} {
twapi::win32_error $winerror $msg
}
#-- from share.tcl
namespace eval twapi {
}
proc twapi::new_share {sharename path args} {
variable windefs
array set opts [parseargs args {
{system.arg ""}
{type.arg "file"}
{comment.arg ""}
{max_conn.int -1}
secd.arg
} -maxleftover 0]
if {![info exists opts(secd)]} {
set opts(secd) [new_security_descriptor -dacl [new_acl [list [new_ace allow S-1-1-0 1179817]]]]
}
NetShareAdd $opts(system) \
$sharename \
[_share_type_symbols_to_code $opts(type)] \
$opts(comment) \
$opts(max_conn) \
[file nativename $path] \
$opts(secd)
}
proc twapi::delete_share {sharename args} {
array set opts [parseargs args {system.arg} -nulldefault]
NetShareDel $opts(system) $sharename 0
}
proc twapi::get_shares {args} {
variable windefs
array set opts [parseargs args {
system.arg
type.arg
excludespecial
} -nulldefault]
if {$opts(type) != ""} {
set type_filter [_share_type_symbols_to_code $opts(type) 1]
} else {
set type_filter ""
}
set shares [list ]
foreach share [Twapi_NetShareEnum $opts(system)] {
foreach {name type comment} $share break
set special [expr {$type & ($windefs(STYPE_SPECIAL) | $windefs(STYPE_TEMPORARY))}]
if {$special && $opts(excludespecial)} {
continue
}
set type [expr {int($type & ~ $special)}]
if {([string length $type_filter] == 0) || ($type == $type_filter)} {
lappend shares $name
}
}
return $shares
}
proc twapi::get_share_info {sharename args} {
array set opts [parseargs args {
system.arg
all
name
type
path
comment
max_conn
current_conn
secd
} -nulldefault]
if {$opts(all)} {
foreach opt {name type path comment max_conn current_conn secd} {
set opts($opt) 1
}
}
set level 0
if {$opts(name) || $opts(type) || $opts(comment)} {
set level 1
}
if {$opts(max_conn) || $opts(current_conn) || $opts(path)} {
set level 2
}
if {$opts(secd)} {
set level 502
}
if {! $level} {
return
}
set shareinfo [NetShareGetInfo $opts(system) $sharename $level]
set result [list ]
if {$opts(name)} {
lappend result -name [lindex $shareinfo 0]
}
if {$opts(type)} {
lappend result -type [_share_type_code_to_symbols [lindex $shareinfo 1]]
}
if {$opts(comment)} {
lappend result -comment [lindex $shareinfo 2]
}
if {$opts(max_conn)} {
lappend result -max_conn [lindex $shareinfo 4]
}
if {$opts(current_conn)} {
lappend result -current_conn [lindex $shareinfo 5]
}
if {$opts(path)} {
lappend result -path [lindex $shareinfo 6]
}
if {$opts(secd)} {
lappend result -secd [lindex $shareinfo 9]
}
return $result
}
proc twapi::set_share_info {sharename args} {
array set opts [parseargs args {
{system.arg ""}
comment.arg
max_conn.int
secd.arg
}]
array set shareinfo [get_share_info $sharename -system $opts(system) \
-comment -max_conn -secd]
foreach field {comment max_conn secd} {
if {[info exists opts($field)]} {
set shareinfo(-$field) $opts($field)
}
}
NetShareSetInfo $opts(system) $sharename $shareinfo(-comment) \
$shareinfo(-max_conn) $shareinfo(-secd)
}
proc twapi::get_connected_shares {} {
return [get_client_shares]
}
proc twapi::get_client_shares {} {
return [NetUseEnum]
}
proc twapi::connect_share {remoteshare args} {
array set opts [parseargs args {
{type.arg  "disk"} 
localdevice.arg
provider.arg
password.arg
nopassword
defaultpassword
user.arg
{window.arg 0}
interactive
prompt
updateprofile
commandline
} -nulldefault]
set flags 0
switch -exact -- $opts(type) {
"any"       {set type 0}
"disk"      -
"file"      {set type 1}
"printer"   {set type 2}
default {
error "Invalid network share type '$opts(type)'"
}
}
if {$opts(localdevice) == "*"} {
set opts(localdevice) ""
setbits flags 0x80;             # CONNECT_REDIRECT
}
if {$opts(defaultpassword) && $opts(nopassword)} {
error "Options -defaultpassword and -nopassword may not be used together"
}
if {$opts(nopassword)} {
set opts(password) ""
set ignore_password 1
} else {
set ignore_password 0
if {$opts(defaultpassword)} {
set opts(password) ""
}
}
foreach {opt mask} {
interactive   0x8
prompt        0x10
updateprofile 0x1
commandline   0x800
} {
if {$opts($opt)} {
setbits flags $mask
}
}
return [Twapi_WNetUseConnection $opts(window) $type $opts(localdevice) \
$remoteshare $opts(provider) $opts(user) $ignore_password \
$opts(password) $flags]
}
proc twapi::disconnect_share {sharename args} {
array set opts [parseargs args {updateprofile force}]
set flags [expr {$opts(updateprofile) ? 0x1 : 0}]
WNetCancelConnection2 $sharename $flags $opts(force)
}
proc twapi::get_client_share_info {sharename args} {
if {$sharename eq ""} {
error "A share name cannot be the empty string"
}
foreach elem [get_client_shares] {
foreach {elem_device elem_unc} $elem break
if {[string equal -nocase $sharename $elem_unc]} {
if {$elem_device eq ""} {
set unc $elem_unc
unset -nocomplain local; # In case we found a match earlier
break
} else {
set local $elem_device
set unc $elem_unc
}
} else {
if {[string equal -nocase [string trimright $elem_device :] [string trimright $sharename :]]} {
set local $elem_device
set unc $elem_unc
break
}
}
}
if {![info exists unc]} {
win32_error 2250 "Share '$sharename' not found."
}
array set opts [parseargs args {
user
localdevice
remoteshare
status
type
opencount
usecount
domain
provider
comment
all
} -maxleftover 0]
if {$opts(all) || $opts(user) || $opts(status) || $opts(type) ||
$opts(opencount) || $opts(usecount) || $opts(domain)} {
if {[info exists local]} {
array set shareinfo [Twapi_NetUseGetInfo "" $local]
} else {
array set shareinfo [Twapi_NetUseGetInfo "" $unc]
}
}
if {$opts(all) || $opts(comment) || $opts(provider) || $opts(remoteshare)} {
if {$shareinfo(ui2_status) == 0} {
array set shareinfo [lindex [Twapi_WNetGetResourceInformation $unc "" 0] 0]
} else {
set shareinfo(lpRemoteName) $unc
set shareinfo(lpProvider) ""
set shareinfo(lpComment) ""
}
}
array set result {}
foreach {opt index} {
user           ui2_username
localdevice    ui2_local
remoteshare    lpRemoteName
status         ui2_status
type           ui2_asg_type
opencount      ui2_refcount
usecount       ui2_usecount
domain         ui2_domainname
provider       lpProvider
comment        lpComment
} {
if {$opts(all) || $opts($opt)} {
set result(-$opt) $shareinfo($index)
}
}
if {[info exists result(-status)]} {
set temp [lindex {connected paused lostsession disconnected networkerror connecting reconnecting} $result(-status)]
if {$temp ne ""} {
set result(-status) $temp
} else {
set result(-status) "unknown"
}
}
if {[info exists result(-type)]} {
set temp [lindex {file printer char ipc} $result(-type)]
if {$temp ne ""} {
set result(-type) $temp
} else {
set result(-type) "unknown"
}
}
return [array get result]
}
proc twapi::get_mapped_share_info {path args} {
array set opts [parseargs args {
all user uncpath uncvolume relativepath
}]
if {! [regexp {^([[:alpha:]]:)} $path dontcare drive]} {
error "No drive specified in path '$path'"
}
set result [list ]
foreach {uncpath uncvolume relativepath} [WNetGetUniversalName $path] break
foreach opt {uncpath uncvolume relativepath} {
if {$opts($opt) || $opts(all)} {
lappend result -$opt [set $opt]
}
}
if {$opts(user) || $opts(all)} {
lappend result -user [WNetGetUser $drive]
}
return $result
}
proc twapi::find_lm_sessions args {
array set opts [parseargs args {
all
{client.arg ""}
{system.arg ""}
{user.arg ""}
transport
clientname
username
clienttype
opencount
idleseconds
activeseconds
attrs
} -maxleftover 0]
set level [_calc_minimum_session_info_level opts]
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
set opts(client) [_make_unc_computername $opts(client)]
try {
set sessions [NetSessionEnum $opts(system) $opts(client) $opts(user) $level]
} onerror {TWAPI_WIN32 2312} {
return [list ]
} onerror {TWAPI_WIN32 2221} {
return [list ]
}
set retval [list ]
foreach sess $sessions {
lappend retval [_format_lm_session $sess opts]
}
return $retval
}
proc twapi::get_lm_session_info {client user args} {
array set opts [parseargs args {
all
{system.arg ""}
transport
clientname
username
clienttype
opencount
idleseconds
activeseconds
attrs
} -maxleftover 0]
set level [_calc_minimum_session_info_level opts]
if {$level == -1} {
return [list ]
}
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
set client [_make_unc_computername $client]
set sess [NetSessionGetInfo $opts(system) $client $user $level]
return [_format_lm_session $sess opts]
}
proc twapi::end_lm_sessions args {
array set opts [parseargs args {
{client.arg ""}
{system.arg ""}
{user.arg ""}
} -maxleftover 0]
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
if {$opts(client) eq "" && $opts(user) eq ""} {
win32_error 87 "At least one of -client and -user must be specified."
}
set opts(client) [_make_unc_computername $opts(client)]
try {
NetSessionDel $opts(system) $opts(client) $opts(user)
} onerror {TWAPI_WIN32 2312} {
} onerror {TWAPI_WIN32 2221} {
}
return
}
proc twapi::find_lm_open_files args {
array set opts [parseargs args {
{basepath.arg ""}
{system.arg ""}
{user.arg ""}
all
permissions
id
lockcount
path
username
} -maxleftover 0]
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
set level 3
if {! ($opts(all) || $opts(permissions) || $opts(lockcount) ||
$opts(path) || $opts(username))} {
set level 2
}
try {
set files [NetFileEnum $opts(system) [file nativename $opts(basepath)] $opts(user) $level]
} onerror {TWAPI_WIN32 2221} {
return [list ]
}
set retval [list ]
foreach file $files {
lappend retval [_format_lm_open_file $file opts]
}
return $retval
}
proc twapi::get_lm_open_file_info {fid args} {
array set opts [parseargs args {
{system.arg ""}
all
permissions
id
lockcount
path
username
} -maxleftover 0]
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
set level 3
if {! ($opts(all) || $opts(permissions) || $opts(lockcount) ||
$opts(path) || $opts(username))} {
set level 2
}
return [_format_lm_open_file [NetFileGetInfo $opts(system) $fid $level] opts]
}
proc twapi::close_lm_open_file {fid args} {
array set opts [parseargs args {
{system.arg ""}
} -maxleftover 0]
try {
NetFileClose $opts(system) $fid
} onerror {TWAPI_WIN32 2314} {
}
}
proc twapi::find_lm_connections args {
array set opts [parseargs args {
client.arg
{system.arg ""}
share.arg
all
id
type
opencount
usercount
activeseconds
username
clientname
sharename
} -maxleftover 0]
if {![min_os_version 5]} {
set opts(system) [_make_unc_computername $opts(system)]
}
if {! ([info exists opts(client)] || [info exists opts(share)])} {
win32_error 87 "Must specify either -client or -share option."
}
if {[info exists opts(client)] && [info exists opts(share)]} {
win32_error 87 "Must not specify both -client and -share options."
}
if {[info exists opts(client)]} {
set qualifier [_make_unc_computername $opts(client)]
} else {
set qualifier $opts(share)
}
set level 1
if {! ($opts(all) || $opts(type) || $opts(opencount) ||
$opts(usercount) || $opts(username) ||
$opts(activeseconds) || $opts(clientname) || $opts(sharename))} {
set level 0
}
set conns [NetConnectionEnum $opts(system) $qualifier $level]
set retval [list ]
foreach conn $conns {
set item [list ]
foreach {opt fld} {
id            id
opencount     num_opens
usercount     num_users
activeseconds time
username      username
} {
if {$opts(all) || $opts($opt)} {
lappend item -$opt [kl_get $conn $fld]
}
}
if {$opts(all) || $opts(type)} {
lappend item -type [_share_type_code_to_symbols [kl_get $conn type]]
}
if {$opts(all) || $opts(clientname) || $opts(sharename)} {
if {[info exists opts(client)]} {
set sharename [kl_get $conn netname]
set clientname [_make_unc_computername $opts(client)]
} else {
set sharename $opts(share)
set clientname [_make_unc_computername [kl_get $conn netname]]
}
if {$opts(all) || $opts(clientname)} {
lappend item -clientname $clientname
}
if {$opts(all) || $opts(sharename)} {
lappend item -sharename $sharename
}
}
lappend retval $item
}
return $retval
}
proc twapi::_calc_minimum_session_info_level {v_opts} {
upvar $v_opts opts
if {$opts(all) || $opts(transport)} {
return 502
} elseif {$opts(clienttype)} {
return 2
} elseif {$opts(opencount) || $opts(attrs)} {
return 1
} elseif {$opts(clientname) || $opts(username) ||
$opts(idleseconds) || $opts(activeseconds)} {
return 10
} else {
return 0
}
}
proc twapi::_format_lm_session {sess v_opts} {
upvar $v_opts opts
set retval [list ]
foreach {opt fld} {
transport     transport
username      username
opencount     num_opens
idleseconds   idle_time
activeseconds time
clienttype    cltype_name
} {
if {$opts(all) || $opts($opt)} {
lappend retval -$opt [kl_get $sess $fld]
}
}
if {$opts(all) || $opts(clientname)} {
lappend retval -clientname [_make_unc_computername [kl_get $sess cname]]
}
if {$opts(all) || $opts(attrs)} {
set attrs [list ]
set flags [kl_get $sess user_flags]
if {$flags & 1} {
lappend attrs guest
}
if {$flags & 2} {
lappend attrs noencryption
}
lappend retval -attrs $attrs
}
return $retval
}
proc twapi::_format_lm_open_file {file v_opts} {
upvar $v_opts opts
set retval [list ]
foreach {opt fld} {
id          id
lockcount   num_locks
path        pathname
username    username
} {
if {$opts(all) || $opts($opt)} {
lappend retval -$opt [kl_get $file $fld]
}
}
if {$opts(all) || $opts(permissions)} {
set permissions [list ]
set perms [kl_get $file permissions]
foreach {flag perm} {1 read 2 write 4 create} {
if {$perms & $flag} {
lappend permissions $perm
}
}
lappend retval -permissions $permissions
}
return $retval
}
proc twapi::_share_type_symbols_to_code {typesyms {basetypeonly 0}} {
variable windefs
switch -exact -- [lindex $typesyms 0] {
file    { set code $windefs(STYPE_DISKTREE) }
printer { set code $windefs(STYPE_PRINTQ) }
device  { set code $windefs(STYPE_DEVICE) }
ipc     { set code $windefs(STYPE_IPC) }
default {
error "Unknown type network share type symbol [lindex $typesyms 0]"
}
}
if {$basetypeonly} {
return $code
}
set special 0
foreach sym [lrange $typesyms 1 end] {
switch -exact -- $sym {
special   { setbits special $windefs(STYPE_SPECIAL) }
temporary { setbits special $windefs(STYPE_TEMPORARY) }
file    -
printer -
device  -
ipc     {
error "Base share type symbol '$sym' cannot be used as a share attribute type"
}
default {
error "Unknown type network share type symbol '$sym'"
}
}
}
return [expr {$code | $special}]
}
proc twapi::_share_type_code_to_symbols {type} {
variable windefs
set special [expr {$type & ($windefs(STYPE_SPECIAL) | $windefs(STYPE_TEMPORARY))}]
switch -exact -- [expr {int($type & ~ $special)}] \
[list \
$windefs(STYPE_DISKTREE) {set sym "file"} \
$windefs(STYPE_PRINTQ)   {set sym "printer"} \
$windefs(STYPE_DEVICE)   {set sym "device"} \
$windefs(STYPE_IPC)      {set sym "ipc"} \
default                  {set sym $type}
]
set typesyms [list $sym]
if {$special & $windefs(STYPE_SPECIAL)} {
lappend typesyms special
}
if {$special & $windefs(STYPE_TEMPORARY)} {
lappend typesyms temporary
}
return $typesyms
}
proc twapi::_make_unc_computername {name} {
if {$name eq ""} {
return ""
} else {
return "\\\\[string trimleft $name \\]"
}
}
#-- from shell.tcl
namespace eval twapi {
}
proc twapi::get_shell_folder {csidl args} {
variable csidl_lookup
array set opts [parseargs args {create} -maxleftover 0]
if {![info exists csidl_lookup]} {
array set csidl_lookup {
CSIDL_ADMINTOOLS 0x30
CSIDL_COMMON_ADMINTOOLS 0x2f
CSIDL_APPDATA 0x1a
CSIDL_COMMON_APPDATA 0x23
CSIDL_COMMON_DESKTOPDIRECTORY 0x19
CSIDL_COMMON_DOCUMENTS 0x2e
CSIDL_COMMON_FAVORITES 0x1f
CSIDL_COMMON_MUSIC 0x35
CSIDL_COMMON_PICTURES 0x36
CSIDL_COMMON_PROGRAMS 0x17
CSIDL_COMMON_STARTMENU 0x16
CSIDL_COMMON_STARTUP 0x18
CSIDL_COMMON_TEMPLATES 0x2d
CSIDL_COMMON_VIDEO 0x37
CSIDL_COOKIES 0x21
CSIDL_DESKTOPDIRECTORY 0x10
CSIDL_FAVORITES 0x6
CSIDL_HISTORY 0x22
CSIDL_INTERNET_CACHE 0x20
CSIDL_LOCAL_APPDATA 0x1c
CSIDL_MYMUSIC 0xd
CSIDL_MYPICTURES 0x27
CSIDL_MYVIDEO 0xe
CSIDL_NETHOOD 0x13
CSIDL_PERSONAL 0x5
CSIDL_PRINTHOOD 0x1b
CSIDL_PROFILE 0x28
CSIDL_PROFILES 0x3e
CSIDL_PROGRAMS 0x2
CSIDL_PROGRAM_FILES 0x26
CSIDL_PROGRAM_FILES_COMMON 0x2b
CSIDL_RECENT 0x8
CSIDL_SENDTO 0x9
CSIDL_STARTMENU 0xb
CSIDL_STARTUP 0x7
CSIDL_SYSTEM 0x25
CSIDL_TEMPLATES 0x15
CSIDL_WINDOWS 0x24
}
}
if {![string is integer $csidl]} {
set csidl_key [string toupper $csidl]
if {![info exists csidl_lookup($csidl_key)]} {
set csidl_key "CSIDL_$csidl_key"
if {![info exists csidl_lookup($csidl_key)]} {
error "Invalid CSIDL value '$csidl'"
}
}
set csidl $csidl_lookup($csidl_key)
}
try {
set path [SHGetSpecialFolderPath 0 $csidl $opts(create)]
} onerror {} {
set code $errorCode
set msg $errorResult
set info $errorInfo
switch -exact -- [format %x $csidl] {
1a { catch {set path $::env(APPDATA)} }
2b { catch {set path $::env(CommonProgramFiles)} }
26 { catch {set path $::env(ProgramFiles)} }
24 { catch {set path $::env(windir)} }
25 { catch {set path [file join $::env(systemroot) system32]} }
}
if {![info exists path]} {
return ""
}
}
return $path
}
proc twapi::shell_object_properties_dialog {path args} {
array set opts [parseargs args {
{type.arg "" {"" file printer volume}}
{hwin.int 0}
{page.arg ""}
} -maxleftover 0]
if {$opts(type) eq ""} {
if {[file exists $path]} {
set opts(type) file
} elseif {[lsearch -exact [string tolower [find_volumes]] [string tolower $path]] >= 0} {
set opts(type) volume
} else {
foreach printer [enumerate_printers] {
if {[string equal -nocase [kl_get $printer name] $path]} {
set opts(type) printer
break
}
}
if {$opts(type) eq ""} {
error "Could not figure out type of object '$path'"
}
}
}
if {$opts(type) eq "file"} {
set path [file nativename [file normalize $path]]
}
SHObjectProperties $opts(hwin) \
[string map {printer 1 file 2 volume 4} $opts(type)] \
$path \
$opts(page)
}
proc twapi::write_shortcut {link args} {
array set opts [parseargs args {
path.arg
idl.arg
args.arg
desc.arg
hotkey.arg
iconpath.arg
iconindex.int
{showcmd.arg normal}
workdir.arg
relativepath.arg
} -nulldefault -maxleftover 0]
if {![string is integer -strict $opts(hotkey)]} {
if {$opts(hotkey) eq ""} {
set opts(hotkey) 0
} else {
foreach {modifiers vk} [_hotkeysyms_to_vk $opts(hotkey)] break
set opts(hotkey) $vk
if {$modifiers & 1} {
set opts(hotkey) [expr {$opts(hotkey) | (4<<8)}]
}
if {$modifiers & 2} {
set opts(hotkey) [expr {$opts(hotkey) | (2<<8)}]
}
if {$modifiers & 4} {
set opts(hotkey) [expr {$opts(hotkey) | (1<<8)}]
}
if {$modifiers & 8} {
set opts(hotkey) [expr {$opts(hotkey) | (8<<8)}]
}
}
}
switch -exact -- $opts(showcmd) {
minimized { set opts(showcmd) 7 }
maximized { set opts(showcmd) 3 }
normal    { set opts(showcmd) 1 }
}
Twapi_WriteShortcut $link $opts(path) $opts(idl) $opts(args) \
$opts(desc) $opts(hotkey) $opts(iconpath) $opts(iconindex) \
$opts(relativepath) $opts(showcmd) $opts(workdir)
}
proc twapi::read_shortcut {link args} {
array set opts [parseargs args {
shortnames
uncpath
rawpath
timeout.int
{hwin.int 0}
install
nosearch
notrack
noui
nolinkinfo
anymatch
} -maxleftover 0]
set pathfmt 0
foreach {opt val} {shortnames 1 uncpath 2 rawpath 4} {
if {$opts($opt)} {
setbits pathfmt $val
}
}
set resolve_flags 4;                # SLR_UPDATE
foreach {opt val} {
install      128
nolinkinfo    64
notrack       32
nosearch      16
anymatch       2
noui           1
} {
if {$opts($opt)} {
setbits resolve_flags $val
}
}
array set shortcut [twapi::Twapi_ReadShortcut $link $pathfmt $opts(hwin) $resolve_flags]
switch -exact -- $shortcut(-showcmd) {
1 { set shortcut(-showcmd) normal }
3 { set shortcut(-showcmd) maximized }
7 { set shortcut(-showcmd) minimized }
}
return [array get shortcut]
}
proc twapi::write_url_shortcut {link url args} {
array set opts [parseargs args {
{missingprotocol.arg 0 {0 usedefault guess}}
} -nulldefault -maxleftover 0]
switch -exact -- $opts(missingprotocol) {
guess { set opts(missingprotocol) 1 }
usedefault { set opts(missingprotocol) 2 }
}
Twapi_WriteUrlShortcut $link $url $opts(missingprotocol)
}
proc twapi::read_url_shortcut {link} {
return [Twapi_ReadUrlShortcut $link]
}
proc twapi::invoke_url_shortcut {link args} {
array set opts [parseargs args {
verb.arg
{hwin.int 0}
allowui
} -maxleftover 0]
set flags 0
if {$opts(allowui)} {setbits flags 1}
if {! [info exists opts(verb)]} {
setbits flags 2
set opts(verb) ""
}
Twapi_InvokeUrlShortcut $link $opts(verb) $flags $opts(hwin)
}
proc twapi::recycle_file {fn args} {
array set opts [parseargs args {
confirm.bool
showerror.bool
} -maxleftover 0 -nulldefault]
set fn [file nativename [file normalize $fn]]
if {$opts(confirm)} {
set flags 0x40;         # FOF_ALLOWUNDO
} else {
set flags 0x50;         # FOF_ALLOWUNDO | FOF_NOCONFIRMATION
}
if {! $opts(showerror)} {
set flags [expr {$flags | 0x0400}]; # FOF_NOERRORUI
}
return [expr {[lindex [Twapi_SHFileOperation 0 3 [list $fn] __null__ $flags ""] 0] ? false : true}]
}
#-- from synch.tcl
namespace eval twapi {
}
proc twapi::create_mutex {args} {
array set opts [parseargs args {
{name.arg ""}
{secd.arg ""}
{inherit.bool 0}
lock
}]
return [CreateMutex [_make_secattr $opts(secd) $opts(inherit)] $opts(lock) $opts(name)]
}
proc twapi::get_mutex_handle {name args} {
array set opts [parseargs args {
{inherit.bool 0}
{access.arg {mutex_all_access}}
}]
return [OpenMutex [_access_rights_to_mask $opts(access)] $opts(inherit) $name]
}
proc twapi::lock_mutex {h args} {
array set opts [parseargs args {
{wait.int 1000}
}]
return [wait_on_handles [list $h] -wait $opts(wait)]
}
proc twapi::unlock_mutex {h} {
ReleaseMutex $h
}
proc twapi::wait_on_handles {hlist args} {
array set opts [parseargs args {
{all.bool 0}
{wait.int 1000}
}]
return [WaitForMultipleObjects $hlist $opts(all) $opts(wait)]
}
#-- from ui.tcl
namespace eval twapi {
variable null_hwin ""
}
proc twapi::get_toplevel_windows {args} {
array set opts [parseargs args {
{pid.arg}
}]
set toplevels [twapi::EnumWindows]
if {![info exists opts(pid)]} {
return $toplevels
}
if {[string is integer $opts(pid)]} {
set match_pids [list $opts(pid)]
} else {
set match_pids [list ]
foreach pid [get_process_ids] {
if {[string equal -nocase $opts(pid) [get_process_name $pid]]} {
lappend match_pids $pid
}
}
if {[llength $match_pids] == 0} {
return [list ]
}
}
set process_toplevels [list ]
foreach toplevel $toplevels {
set pid [get_window_process $toplevel]
if {[lsearch -exact $match_pids $pid] >= 0} {
lappend process_toplevels $toplevel
}
}
return $process_toplevels
}
proc twapi::find_windows {args} {
array set opts [parseargs args {
ancestor.int
caption.bool
child.bool
class.arg
{match.arg string {string glob regexp}}
maximize.bool
maximizebox.bool
messageonlywindow.bool
minimize.bool
minimizebox.bool
overlapped.bool
pids.arg
popup.bool
single
style.arg
text.arg
toplevel.bool
visible.bool
} -maxleftover 0]
if {[info exists opts(style)]
||[info exists opts(overlapped)]
|| [info exists opts(popup)]
|| [info exists opts(child)]
|| [info exists opts(minimizebox)]
|| [info exists opts(maximizebox)]
|| [info exists opts(minimize)]
|| [info exists opts(maximize)]
|| [info exists opts(visible)]
|| [info exists opts(caption)]
} {
set need_style 1
} else {
set need_style 0
}
if {[info exists opts(text)]} {
switch -exact -- $opts(match) {
glob {
set text_compare [list string match -nocase $opts(text)]
}
string {
set text_compare [list string equal -nocase $opts(text)]
}
regexp {
set text_compare [list regexp -nocase $opts(text)]
}
default {
error "Invalid value '$opts(match)' specified for -match option"
}
}
}
set include_ordinary true
if {[info exists opts(messageonlywindow)]} {
if {$opts(messageonlywindow)} {
if {[info exists opts(toplevel)] && $opts(toplevel)} {
error "Options -toplevel and -messageonlywindow cannot be both specified as true"
}
if {[info exists opts(ancestor)]} {
error "Option -ancestor cannot be specified if -messageonlywindow is specified as true"
}
set include_ordinary false
}
set include_messageonly $opts(messageonlywindow)
} else {
if {([info exists opts(toplevel)] && $opts(toplevel)) ||
[info exists opts(ancestor)]
} {
set include_messageonly false
} else {
set include_messageonly true
}
}
if {$include_messageonly} {
set class ""
if {[info exists opts(class)]} {
set class $opts(class)
}
set text ""
if {[info exists opts(text)] &&
$opts(match) eq "string"} {
set text $opts(text)
}
set messageonly_candidates [_get_message_only_windows -class $class -text $text]
} else {
set messageonly_candidates [list ]
}
if {$include_ordinary} {
if {[info exists opts(toplevel)]} {
if {$opts(toplevel)} {
set ordinary_candidates [get_toplevel_windows]
if {[info exists opts(ancestor)]} {
error "Option -ancestor may not be specified together with -toplevel true"
}
} else {
set toplevels [get_toplevel_windows]
}
}
if {![info exists ordinary_candidates]} {
if {[info exists opts(ancestor)] && $opts(ancestor)} {
set ordinary_candidates [get_descendent_windows $opts(ancestor)]
} else {
set desktop [get_desktop_window]
set ordinary_candidates [concat [list $desktop] [get_descendent_windows $desktop]]
}
}
} else {
set ordinary_candidates [list ]
}
set matches [list ]
foreach win [concat $messageonly_candidates $ordinary_candidates] {
set status [catch {
if {[info exists toplevels]} {
if {[lsearch -exact -integer $toplevels $win] >= 0} {
continue
}
}
if {$need_style} {
set win_styles [get_window_style $win]
set win_style [lindex $win_styles 0]
set win_exstyle [lindex $win_styles 1]
set win_styles [lrange $win_styles 2 end]
}
if {[info exists opts(style)] && [llength $opts(style)]} {
foreach {style exstyle} $opts(style) break
if {[string length $style] && ($style != $win_style)} continue
if {[string length $exstyle] && ($exstyle != $win_exstyle)} continue
}
set match 1
foreach opt {visible overlapped popup child minimizebox
maximizebox minimize maximize caption
} {
if {[info exists opts($opt)]} {
if {(! $opts($opt)) == ([lsearch -exact $win_styles $opt] >= 0)} {
set match 0
break
}
}
}
if {! $match} continue
if {[info exists opts(class)] &&
[string compare -nocase $opts(class) [get_window_class $win]]} {
continue
}
if {[info exists opts(pids)]} {
set pid [get_window_process $win]
if {[lsearch -exact -integer $opts(pids) $pid] < 0} continue
}
if {[info exists opts(text)]} {
set text [get_window_text $win]
if {![eval $text_compare [list [get_window_text $win]]]} continue
}
if {$opts(single)} {
return [list $win]
}
lappend matches $win
} result ]
switch -exact -- $status {
0 {
}
1 {
foreach {subsystem code msg} $::errorCode { break }
if {$subsystem == "TWAPI_WIN32" && $code == 2} {
} else {
error $result $::errorInfo $::errorCode
}
}
2 {
return $result;         # Block executed a return
}
3 {
break;                  # Block executed a break
}
4 {
continue;               # Block executed a continue
}
}
}
return $matches
}
proc twapi::get_descendent_windows {parent_hwin} {
return [EnumChildWindows $parent_hwin]
}
proc twapi::get_parent_window {hwin} {
return [_return_window [GetAncestor $hwin $twapi::windefs(GA_PARENT)]]
}
proc twapi::get_owner_window {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_OWNER)]]
}
proc twapi::get_child_windows {hwin} {
set children [list ]
foreach w [get_descendent_windows $hwin] {
if {[_same_window $hwin [get_parent_window $w]]} {
lappend children $w
}
}
return $children
}
proc twapi::get_first_child {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_CHILD)]]
}
proc twapi::get_next_sibling_window {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_HWNDNEXT)]]
}
proc twapi::get_prev_sibling_window {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_HWNDPREV)]]
}
proc twapi::get_first_sibling_window {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_HWNDFIRST)]]
}
proc twapi::get_last_sibling_window {hwin} {
return [_return_window [twapi::GetWindow $hwin \
$twapi::windefs(GW_HWNDLAST)]]
}
proc twapi::get_desktop_window {} {
return [_return_window [twapi::GetDesktopWindow]]
}
proc twapi::get_shell_window {} {
return [_return_window [twapi::GetShellWindow]]
}
proc twapi::get_window_process {hwin} {
return [lindex [GetWindowThreadProcessId $hwin] 1]
}
proc twapi::get_window_thread {hwin} {
return [lindex [GetWindowThreadProcessId $hwin] 0]
}
proc twapi::get_window_style {hwin} {
set style   [GetWindowLong $hwin $twapi::windefs(GWL_STYLE)]
set exstyle [GetWindowLong $hwin $twapi::windefs(GWL_EXSTYLE)]
return [concat [list $style $exstyle] [_style_mask_to_symbols $style $exstyle]]
}
proc twapi::set_window_style {hwin style exstyle} {
set style [SetWindowLong $hwin $twapi::windefs(GWL_STYLE) $style]
set exstyle [SetWindowLong $hwin $twapi::windefs(GWL_EXSTYLE) $exstyle]
redraw_window_frame $hwin
return
}
proc twapi::get_window_class {hwin} {
return [_return_window [GetClassName $hwin]]
}
proc twapi::get_window_real_class {hwin} {
return [_return_window [RealGetWindowClass $hwin]]
}
proc twapi::get_window_long {hwin index} {
return [GetWindowLong $hwin $index]
}
proc twapi::set_window_long {hwin index val} {
set oldval [SetWindowLong $hwin $index $val]
}
proc twapi::get_window_application {hwin} {
return [format "0x%x" [GetWindowLong $hwin $twapi::windefs(GWL_HINSTANCE)]]
}
proc twapi::get_window_id {hwin} {
return [format "0x%x" [GetWindowLong $hwin $twapi::windefs(GWL_ID)]]
}
proc twapi::get_window_userdata {hwin} {
return [GetWindowLong $hwin $twapi::windefs(GWL_USERDATA)]
}
proc twapi::set_window_userdata {hwin val} {
return [SetWindowLong $hwin $twapi::windefs(GWL_USERDATA) $val]
}
proc twapi::get_foreground_window {} {
return [_return_window [GetForegroundWindow]]
}
proc twapi::set_foreground_window {hwin} {
return [SetForegroundWindow $hwin]
}
proc twapi::set_active_window_for_thread {hwin} {
return [_return_window [_attach_hwin_and_eval $hwin {SetActiveWindow $hwin}]]
}
proc twapi::get_active_window_for_thread {tid} {
return [_return_window [_get_gui_thread_info $tid hwndActive]]
}
proc twapi::get_focus_window_for_thread {tid} {
return [_get_gui_thread_info $tid hwndFocus]
}
proc twapi::get_active_window_for_current_thread {} {
return [_return_window [GetActiveWindow]]
}
proc twapi::redraw_window_frame {hwin} {
variable windefs
set flags [expr {$windefs(SWP_ASYNCWINDOWPOS) | $windefs(SWP_NOACTIVATE) |
$windefs(SWP_NOMOVE) | $windefs(SWP_NOSIZE) |
$windefs(SWP_NOZORDER) | $windefs(SWP_FRAMECHANGED)}]
SetWindowPos $hwin 0 0 0 0 0 $flags
}
proc twapi::redraw_window {hwin {opt ""}} {
variable windefs
if {[string length $opt]} {
if {[string compare $opt "-force"]} {
error "Invalid option '$opt'"
}
invalidate_screen_region -hwin $hwin -rect [list ] -bgerase
}
UpdateWindow $hwin
}
proc twapi::move_window {hwin x y args} {
variable windefs
array set opts [parseargs args {
{sync}
}]
set flags [expr {$windefs(SWP_NOACTIVATE) |
$windefs(SWP_NOSIZE) | $windefs(SWP_NOZORDER)}]
if {! $opts(sync)} {
setbits flags $windefs(SWP_ASYNCWINDOWPOS)
}
SetWindowPos $hwin 0 $x $y 0 0 $flags
}
proc twapi::resize_window {hwin w h args} {
variable windefs
array set opts [parseargs args {
{sync}
}]
set flags [expr {$windefs(SWP_NOACTIVATE) |
$windefs(SWP_NOMOVE) | $windefs(SWP_NOZORDER)}]
if {! $opts(sync)} {
setbits flags $windefs(SWP_ASYNCWINDOWPOS)
}
SetWindowPos $hwin 0 0 0 $w $h $flags
}
proc twapi::set_window_zorder {hwin pos} {
variable windefs
switch -exact -- $pos {
top       { set pos $windefs(HWND_TOP) }
bottom    { set pos $windefs(HWND_BOTTOM) }
toplayer   { set pos $windefs(HWND_TOPMOST) }
bottomlayer { set pos $windefs(HWND_NOTOPMOST) }
}
set flags [expr {$windefs(SWP_ASYNCWINDOWPOS) | $windefs(SWP_NOACTIVATE) |
$windefs(SWP_NOSIZE) | $windefs(SWP_NOMOVE)}]
SetWindowPos $hwin $pos 0 0 0 0 $flags
}
proc twapi::show_window {hwin args} {
array set opts [parseargs args {sync activate normal startup}]
set show 0
if {$opts(startup)} {
set show $twapi::windefs(SW_SHOWDEFAULT)
} else {
if {$opts(activate)} {
if {$opts(normal)} {
set show $twapi::windefs(SW_SHOWNORMAL)
} else {
set show $twapi::windefs(SW_SHOW)
}
} else {
if {$opts(normal)} {
set show $twapi::windefs(SW_SHOWNOACTIVATE)
} else {
set show $twapi::windefs(SW_SHOWNA)
}
}
}
_show_window $hwin $show $opts(sync)
}
proc twapi::hide_window {hwin args} {
array set opts [parseargs args {sync}]
_show_window $hwin $twapi::windefs(SW_HIDE) $opts(sync)
}
proc twapi::restore_window {hwin args} {
array set opts [parseargs args {sync activate}]
if {$opts(activate)} {
_show_window $hwin $twapi::windefs(SW_RESTORE) $opts(sync)
} else {
OpenIcon $hwin
}
}
proc twapi::maximize_window {hwin args} {
array set opts [parseargs args {sync}]
_show_window $hwin $twapi::windefs(SW_SHOWMAXIMIZED) $opts(sync)
}
proc twapi::minimize_window {hwin args} {
array set opts [parseargs args {sync activate shownext}]
if $opts(activate) {
set show $twapi::windefs(SW_SHOWMINIMIZED)
} else {
if {$opts(shownext)} {
set show $twapi::windefs(SW_MINIMIZE)
} else {
set show $twapi::windefs(SW_SHOWMINNOACTIVE)
}
}
_show_window $hwin $show $opts(sync)
}
proc twapi::hide_owned_popups {hwin} {
ShowOwnedPopups $hwin 0
}
proc twapi::show_owned_popups {hwin} {
ShowOwnedPopups $hwin 1
}
proc twapi::enable_window_input {hwin} {
return [expr {[EnableWindow $hwin 1] != 0}]
}
proc twapi::disable_window_input {hwin} {
return [expr {[EnableWindow $hwin 0] != 0}]
}
proc twapi::close_window {hwin args} {
variable windefs
array set opts [parseargs args {
block
{wait.int 10}
}]
if {$opts(block)} {
set block [expr {$windefs(SMTO_BLOCK) | $windefs(SMTO_ABORTIFHUNG)}]
} else {
set block [expr {$windefs(SMTO_NORMAL) | $windefs(SMTO_ABORTIFHUNG)}]
}
if {[catch {SendMessageTimeout $hwin $windefs(WM_CLOSE) 0 0 $block $opts(wait)} msg]} {
set erCode $::errorCode
set erInfo $::errorInfo
if {[lindex $erCode 0] != "TWAPI_WIN32" ||
([lindex $erCode 1] != 0 && [lindex $erCode 1] != 1460)} {
error $msg $erInfo $erCode
}
}
}
proc twapi::window_minimized {hwin} {
return [IsIconic $hwin]
}
proc twapi::window_maximized {hwin} {
return [IsZoomed $hwin]
}
proc twapi::window_visible {hwin} {
return [IsWindowVisible $hwin]
}
proc twapi::window_exists {hwin} {
return [IsWindow $hwin]
}
proc twapi::window_unicode_enabled {hwin} {
return [IsWindowUnicode $hwin]
}
proc twapi::window_input_enabled {hwin} {
return [IsWindowEnabled $hwin]
}
proc twapi::window_is_child {parent child} {
return [IsChild $parent $child]
}
proc twapi::set_focus {hwin} {
return [_return_window [_attach_hwin_and_eval $hwin {SetFocus $hwin}]]
}
proc twapi::flash_window_caption {hwin args} {
eval set [parseargs args {toggle}]
return [FlashWindow $hwin $toggle]
}
proc twapi::configure_window_titlebar {hwin args} {
variable windefs
array set opts [parseargs args {
visible.bool
sysmenu.bool
minimizebox.bool
maximizebox.bool
contexthelp.bool
} -maxleftover 0]
foreach {style exstyle} [get_window_style $hwin] {break}
foreach {opt def} {
sysmenu WS_SYSMENU
minimizebox WS_MINIMIZEBOX
maximizebox WS_MAXIMIZEBOX
visible  WS_CAPTION
} {
if {[info exists opts($opt)]} {
set $opt [expr {$opts($opt) ? $windefs($def) : 0}]
} else {
set $opt [expr {$style & $windefs($def)}]
}
}
if {[info exists opts(contexthelp)]} {
set contexthelp [expr {$opts(contexthelp) ? $windefs(WS_EX_CONTEXTHELP) : 0}]
} else {
set contexthelp [expr {$exstyle & $windefs(WS_EX_CONTEXTHELP)}]
}
if {($minimizebox || $maximizebox || $contexthelp) && ! $sysmenu} {
}
set style [expr {($style & ~($windefs(WS_SYSMENU) | $windefs(WS_MINIMIZEBOX) | $windefs(WS_MAXIMIZEBOX) | $windefs(WS_CAPTION))) | ($sysmenu | $minimizebox | $maximizebox | $visible)}]
set exstyle [expr {($exstyle & ~ $windefs(WS_EX_CONTEXTHELP)) | $contexthelp}]
set_window_style $hwin $style $exstyle
}
proc twapi::beep {args} {
array set opts [parseargs args {
{frequency.int 1000}
{duration.int 100}
{type.arg}
}]
if {[info exists opts(type)]} {
switch -exact -- $opts(type) {
ok           {MessageBeep 0}
hand         {MessageBeep 0x10}
question     {MessageBeep 0x20}
exclaimation {MessageBeep 0x30}
exclamation {MessageBeep 0x30}
asterisk     {MessageBeep 0x40}
default      {error "Unknown sound type '$opts(type)'"}
}
return
}
Beep $opts(frequency) $opts(duration)
return
}
proc twapi::arrange_icons {{hwin ""}} {
if {$hwin == ""} {
set hwin [get_desktop_window]
}
ArrangeIconicWindows $hwin
}
proc twapi::get_window_text {hwin} {
twapi::GetWindowText $hwin
}
proc twapi::set_window_text {hwin text} {
twapi::SetWindowText $hwin $text
}
proc twapi::get_window_client_area_size {hwin} {
return [lrange [GetClientRect $hwin] 2 3]
}
proc twapi::get_window_coordinates {hwin} {
return [GetWindowRect $hwin]
}
proc twapi::get_window_at_location {x y} {
return [WindowFromPoint [list $x $y]]
}
proc twapi::invalidate_screen_region {args} {
array set opts [parseargs args {
{hwin.int 0}
rect.arg
bgerase
} -nulldefault]
InvalidateRect $opts(hwin) $opts(rect) $opts(bgerase)
}
proc twapi::get_caret_blink_time {} {
return [GetCaretBlinkTime]
}
proc twapi::set_caret_blink_time {ms} {
return [SetCaretBlinkTime $ms]
}
proc twapi::hide_caret {} {
HideCaret 0
}
proc twapi::show_caret {} {
ShowCaret 0
}
proc twapi::get_caret_location {} {
return [GetCaretPos]
}
proc twapi::set_caret_location {point} {
return [SetCaretPos [lindex $point 0] [lindex $point 1]]
}
proc twapi::get_display_size {} {
return [lrange [get_window_coordinates [get_desktop_window]] 2 3]
}
interp alias {} twapi::get_desktop_wallpaper {} twapi::get_system_parameters_info SPI_GETDESKWALLPAPER
proc twapi::set_desktop_wallpaper {path args} {
array set opts [parseargs args {
persist
}]
if {$opts(persist)} {
set flags 3;                    # Notify all windows + persist
} else {
set flags 2;                    # Notify all windows
}
if {$path == "default"} {
SystemParametersInfo 0x14 0 NULL 0
return
}
if {$path == "none"} {
set path ""
}
set mem_size [expr {2 * ([string length $path] + 1)}]
set mem [malloc $mem_size]
try {
twapi::Twapi_WriteMemoryUnicode $mem 0 $mem_size $path
SystemParametersInfo 0x14 0 $mem $flags
} finally {
free $mem
}
}
interp alias {} twapi::get_desktop_workarea {} twapi::get_system_parameters_info SPI_GETWORKAREA
proc twapi::send_input {inputlist} {
variable windefs
set inputs [list ]
foreach input $inputlist {
if {[string equal [lindex $input 0] "mouse"]} {
foreach {mouse xpos ypos} $input {break}
set mouseopts [lrange $input 3 end]
array unset opts
array set opts [parseargs mouseopts {
relative moved
ldown lup rdown rup mdown mup x1down x1up x2down x2up
wheel.int
}]
set flags 0
if {! $opts(relative)} {
set flags $windefs(MOUSEEVENTF_ABSOLUTE)
}
if {[info exists opts(wheel)]} {
if {($opts(x1down) || $opts(x1up) || $opts(x2down) || $opts(x2up))} {
error "The -wheel input event attribute may not be specified with -x1up, -x1down, -x2up or -x2down events"
}
set mousedata $opts(wheel)
set flags $windefs(MOUSEEVENTF_WHEEL)
} else {
if {$opts(x1down) || $opts(x1up)} {
if {$opts(x2down) || $opts(x2up)} {
error "The -x1down, -x1up mouse input attributes are mutually exclusive with -x2down, -x2up attributes"
}
set mousedata $windefs(XBUTTON1)
} else {
if {$opts(x2down) || $opts(x2up)} {
set mousedata $windefs(XBUTTON2)
} else {
set mousedata 0
}
}
}
foreach {opt flag} {
moved MOVE
ldown LEFTDOWN
lup   LEFTUP
rdown RIGHTDOWN
rup   RIGHTUP
mdown MIDDLEDOWN
mup   MIDDLEUP
x1down XDOWN
x1up   XUP
x2down XDOWN
x2up   XUP
} {
if {$opts($opt)} {
set flags [expr {$flags | $windefs(MOUSEEVENTF_$flag)}]
}
}
lappend inputs [list mouse $xpos $ypos $mousedata $flags]
} else {
foreach {inputtype vk scan keyopts} $input {break}
if {[lsearch -exact $keyopts "-extended"] < 0} {
set extended 0
} else {
set extended $windefs(KEYEVENTF_EXTENDEDKEY)
}
if {[lsearch -exact $keyopts "-usescan"] < 0} {
set usescan 0
} else {
set usescan $windefs(KEYEVENTF_SCANCODE)
}
switch -exact -- $inputtype {
keydown {
lappend inputs [list key $vk $scan [expr {$extended|$usescan}]]
}
keyup {
lappend inputs [list key $vk $scan \
[expr {$extended
| $usescan
| $windefs(KEYEVENTF_KEYUP)
}]]
}
key {
lappend inputs [list key $vk $scan [expr {$extended|$usescan}]]
lappend inputs [list key $vk $scan \
[expr {$extended
| $usescan
| $windefs(KEYEVENTF_KEYUP)
}]]
}
unicode {
lappend inputs [list key 0 $scan $windefs(KEYEVENTF_UNICODE)]
lappend inputs [list key 0 $scan \
[expr {$windefs(KEYEVENTF_UNICODE)
| $windefs(KEYEVENTF_KEYUP)
}]]
}
default {
error "Unknown input type '$inputtype'"
}
}
}
}
SendInput $inputs
}
proc twapi::block_input {} {
return [BlockInput 1]
}
proc twapi::unblock_input {} {
return [BlockInput 0]
}
proc twapi::send_input_text {s} {
return [Twapi_SendUnicode $s]
}
proc twapi::send_keys {keys} {
set inputs [_parse_send_keys $keys]
send_input $inputs
}
proc twapi::register_hotkey {hotkey script} {
foreach {modifiers vk} [_hotkeysyms_to_vk $hotkey] break
RegisterHotKey $modifiers $vk $script
}
proc twapi::unregister_hotkey {id} {
UnregisterHotKey $id
}
proc twapi::click_mouse_button {button} {
switch -exact -- $button {
1 -
left { set down -ldown ; set up -lup}
2 -
right { set down -rdown ; set up -rup}
3 -
middle { set down -mdown ; set up -mup}
x1     { set down -x1down ; set up -x1up}
x2     { set down -x2down ; set up -x2up}
default {error "Invalid mouse button '$button' specified"}
}
send_input [list \
[list mouse 0 0 $down] \
[list mouse 0 0 $up]]
return
}
proc twapi::move_mouse {xpos ypos {mode ""}} {
if {[min_os_version 5 1]} {
set trail [get_system_parameters_info SPI_GETMOUSETRAILS]
set_system_parameters_info SPI_SETMOUSETRAILS 0
}
switch -exact -- $mode {
-relative {
lappend cmd -relative
foreach {curx cury} [GetCursorPos] break
incr xpos $curx
incr ypos $cury
}
-absolute -
""        { }
default   { error "Invalid mouse movement mode '$mode'" }
}
SetCursorPos $xpos $ypos
if {[min_os_version 5 1]} {
set_system_parameters_info SPI_SETMOUSETRAILS $trail
}
}
proc twapi::turn_mouse_wheel {wheelunits} {
send_input [list [list mouse 0 0 -relative -wheel $wheelunits]]
return
}
proc twapi::get_mouse_location {} {
return [GetCursorPos]
}
proc twapi::play_sound {name args} {
variable windefs
array set opts [parseargs args {
alias
async
loop
nodefault
wait
nostop
}]
if {$opts(alias)} {
set flags $windefs(SND_ALIAS)
} else {
set flags $windefs(SND_FILENAME)
}
if {$opts(loop)} {
setbits flags [expr {$windefs(SND_LOOP) | $windefs(SND_ASYNC)}]
} else {
if {$opts(async)} {
setbits flags $windefs(SND_ASYNC)
} else {
setbits flags $windefs(SND_SYNC)
}
}
if {$opts(nodefault)} {
setbits flags $windefs(SND_NODEFAULT)
}
if {! $opts(wait)} {
setbits flags $windefs(SND_NOWAIT)
}
if {$opts(nostop)} {
setbits flags $windefs(SND_NOSTOP)
}
return [PlaySound $name 0 $flags]
}
proc twapi::stop_sound {} {
PlaySound "" 0 $twapi::windefs(SND_PURGE)
}
proc twapi::get_color_depth {{hwin 0}} {
set h [GetDC $hwin]
try {
return [GetDeviceCaps $h 12]
} finally {
ReleaseDC $hwin $h
}
}
proc twapi::get_display_devices {} {
set devs [list ]
for {set i 0} {true} {incr i} {
try {
set dev [EnumDisplayDevices "" $i]
} onerror {} {
break
}
lappend devs [_format_display_device $dev]
}
return $devs
}
proc twapi::get_display_monitors {args} {
array set opts [parseargs args {
device.arg
activeonly
} -maxleftover 0]
if {[info exists opts(device)]} {
set devs [list $opts(device)]
} else {
set devs [list ]
foreach dev [get_display_devices] {
lappend devs [kl_get $dev -name]
}
}
set monitors [list ]
foreach dev $devs {
for {set i 0} {true} {incr i} {
try {
set monitor [EnumDisplayDevices $dev $i]
} onerror {} {
break
}
if {(! $opts(activeonly)) ||
([lindex $monitor 2] & 1)} {
lappend monitors [_format_display_monitor $monitor]
}
}
}
return $monitors
}
proc twapi::get_display_monitor_from_window {hwin args} {
array set opts [parseargs args {
default.arg
} -maxleftover 0]
catch {set hwin [winfo id $hwin]}
set flags 0
if {[info exists opts(default)]} {
switch -exact -- $opts(default) {
primary { set flags 1 }
nearest { set flags 2 }
default { error "Invalid value '$opts(default)' for -default option" }
}
}
try {
return [MonitorFromWindow $hwin $flags]
} onerror {TWAPI_WIN32 0} {
win32_error 1461 "Window does not map to a monitor."
}
}
proc twapi::get_display_monitor_from_point {x y args} {
array set opts [parseargs args {
default.arg
} -maxleftover 0]
set flags 0
if {[info exists opts(default)]} {
switch -exact -- $opts(default) {
primary { set flags 1 }
nearest { set flags 2 }
default { error "Invalid value '$opts(default)' for -default option" }
}
}
try {
return [MonitorFromPoint [list $x $y] $flags]
} onerror {TWAPI_WIN32 0} {
win32_error 1461 "Virtual screen coordinates ($x,$y) do not map to a monitor."
}
}
proc twapi::get_display_monitor_from_rect {rect args} {
array set opts [parseargs args {
default.arg
} -maxleftover 0]
set flags 0
if {[info exists opts(default)]} {
switch -exact -- $opts(default) {
primary { set flags 1 }
nearest { set flags 2 }
default { error "Invalid value '$opts(default)' for -default option" }
}
}
try {
return [MonitorFromRect $rect $flags]
} onerror {TWAPI_WIN32 0} {
win32_error 1461 "Virtual screen rectangle <[join $rect ,]> does not map to a monitor."
}
}
proc twapi::get_display_monitor_info {hmon} {
return [_format_monitor_info [GetMonitorInfo $hmon]]
}
proc twapi::get_multiple_display_monitor_info {} {
set result [list ]
foreach elem [EnumDisplayMonitors NULL ""] {
lappend result [get_display_monitor_info [lindex $elem 0]]
}
return $result
}
proc twapi::get_input_idle_time {} {
set last_event [format 0x%x [GetLastInputInfo]]
set now [format 0x%x [GetTickCount]]
if {$now >= $last_event} {
return [expr {$now - $last_event}]
} else {
return [expr {$now + (0xffffffff - $last_event) + 1}]
}
}
proc twapi::_attach_hwin_and_eval {hwin script} {
set me [get_current_thread_id]
set hwin_tid [get_window_thread $hwin]
if {$hwin_tid == 0} {
error "Window $hwin does not exist or could not get its thread owner"
}
if {$me == $hwin_tid} {
return [uplevel 1 $script]
}
try {
if {![AttachThreadInput $me $hwin_tid 1]} {
error "Could not attach to thread input for window $hwin"
}
set result [uplevel 1 $script]
} finally {
AttachThreadInput $me $hwin_tid 0
}
return $result
}
proc twapi::_get_gui_thread_info {tid args} {
set gtinfo [GUITHREADINFO]
try {
GetGUIThreadInfo $tid $gtinfo
set result [list ]
foreach field $args {
set value [$gtinfo cget -$field]
switch -exact -- $field {
cbSize { }
rcCaret {
set value [list [$value cget -left] \
[$value cget -top] \
[$value cget -right] \
[$value cget -bottom]]
}
default { set value [format 0x%x $value] }
}
lappend result $value
}
} finally {
$gtinfo -delete
}
if {[llength $args] == 1} {
return [lindex $result 0]
} else {
return $result
}
}
proc twapi::_return_window {hwin} {
if {$hwin == 0} {
return $twapi::null_hwin
}
return $hwin
}
proc twapi::_same_window {hwin1 hwin2} {
if {[string length $hwin1] == 0 || [string length $hwin2] == 0} {
return 0
}
if {$hwin1 == 0 || $hwin2 == 0} {
return 0
}
return [expr {$hwin1==$hwin2}]
}
proc twapi::_show_window {hwin cmd {wait 0}} {
if {$wait || ([get_window_thread $hwin] == [get_current_thread_id])} {
ShowWindow $hwin $cmd
} else {
ShowWindowAsync $hwin $cmd
}
}
proc twapi::_init_vk_map {} {
variable windefs
variable vk_map
if {![info exists vk_map]} {
array set vk_map [list \
"+" [list $windefs(VK_SHIFT) 0]\
"^" [list $windefs(VK_CONTROL) 0] \
"%" [list $windefs(VK_MENU) 0] \
"BACK" [list $windefs(VK_BACK) 0] \
"BACKSPACE" [list $windefs(VK_BACK) 0] \
"BS" [list $windefs(VK_BACK) 0] \
"BKSP" [list $windefs(VK_BACK) 0] \
"TAB" [list $windefs(VK_TAB) 0] \
"CLEAR" [list $windefs(VK_CLEAR) 0] \
"RETURN" [list $windefs(VK_RETURN) 0] \
"ENTER" [list $windefs(VK_RETURN) 0] \
"SHIFT" [list $windefs(VK_SHIFT) 0] \
"CONTROL" [list $windefs(VK_CONTROL) 0] \
"MENU" [list $windefs(VK_MENU) 0] \
"ALT" [list $windefs(VK_MENU) 0] \
"PAUSE" [list $windefs(VK_PAUSE) 0] \
"BREAK" [list $windefs(VK_PAUSE) 0] \
"CAPITAL" [list $windefs(VK_CAPITAL) 0] \
"CAPSLOCK" [list $windefs(VK_CAPITAL) 0] \
"KANA" [list $windefs(VK_KANA) 0] \
"HANGEUL" [list $windefs(VK_HANGEUL) 0] \
"HANGUL" [list $windefs(VK_HANGUL) 0] \
"JUNJA" [list $windefs(VK_JUNJA) 0] \
"FINAL" [list $windefs(VK_FINAL) 0] \
"HANJA" [list $windefs(VK_HANJA) 0] \
"KANJI" [list $windefs(VK_KANJI) 0] \
"ESCAPE" [list $windefs(VK_ESCAPE) 0] \
"ESC" [list $windefs(VK_ESCAPE) 0] \
"CONVERT" [list $windefs(VK_CONVERT) 0] \
"NONCONVERT" [list $windefs(VK_NONCONVERT) 0] \
"ACCEPT" [list $windefs(VK_ACCEPT) 0] \
"MODECHANGE" [list $windefs(VK_MODECHANGE) 0] \
"SPACE" [list $windefs(VK_SPACE) 0] \
"PRIOR" [list $windefs(VK_PRIOR) 0] \
"PGUP" [list $windefs(VK_PRIOR) 0] \
"NEXT" [list $windefs(VK_NEXT) 0] \
"PGDN" [list $windefs(VK_NEXT) 0] \
"END" [list $windefs(VK_END) 0] \
"HOME" [list $windefs(VK_HOME) 0] \
"LEFT" [list $windefs(VK_LEFT) 0] \
"UP" [list $windefs(VK_UP) 0] \
"RIGHT" [list $windefs(VK_RIGHT) 0] \
"DOWN" [list $windefs(VK_DOWN) 0] \
"SELECT" [list $windefs(VK_SELECT) 0] \
"PRINT" [list $windefs(VK_PRINT) 0] \
"PRTSC" [list $windefs(VK_SNAPSHOT) 0] \
"EXECUTE" [list $windefs(VK_EXECUTE) 0] \
"SNAPSHOT" [list $windefs(VK_SNAPSHOT) 0] \
"INSERT" [list $windefs(VK_INSERT) 0] \
"INS" [list $windefs(VK_INSERT) 0] \
"DELETE" [list $windefs(VK_DELETE) 0] \
"DEL" [list $windefs(VK_DELETE) 0] \
"HELP" [list $windefs(VK_HELP) 0] \
"LWIN" [list $windefs(VK_LWIN) 0] \
"RWIN" [list $windefs(VK_RWIN) 0] \
"APPS" [list $windefs(VK_APPS) 0] \
"SLEEP" [list $windefs(VK_SLEEP) 0] \
"NUMPAD0" [list $windefs(VK_NUMPAD0) 0] \
"NUMPAD1" [list $windefs(VK_NUMPAD1) 0] \
"NUMPAD2" [list $windefs(VK_NUMPAD2) 0] \
"NUMPAD3" [list $windefs(VK_NUMPAD3) 0] \
"NUMPAD4" [list $windefs(VK_NUMPAD4) 0] \
"NUMPAD5" [list $windefs(VK_NUMPAD5) 0] \
"NUMPAD6" [list $windefs(VK_NUMPAD6) 0] \
"NUMPAD7" [list $windefs(VK_NUMPAD7) 0] \
"NUMPAD8" [list $windefs(VK_NUMPAD8) 0] \
"NUMPAD9" [list $windefs(VK_NUMPAD9) 0] \
"MULTIPLY" [list $windefs(VK_MULTIPLY) 0] \
"ADD" [list $windefs(VK_ADD) 0] \
"SEPARATOR" [list $windefs(VK_SEPARATOR) 0] \
"SUBTRACT" [list $windefs(VK_SUBTRACT) 0] \
"DECIMAL" [list $windefs(VK_DECIMAL) 0] \
"DIVIDE" [list $windefs(VK_DIVIDE) 0] \
"F1" [list $windefs(VK_F1) 0] \
"F2" [list $windefs(VK_F2) 0] \
"F3" [list $windefs(VK_F3) 0] \
"F4" [list $windefs(VK_F4) 0] \
"F5" [list $windefs(VK_F5) 0] \
"F6" [list $windefs(VK_F6) 0] \
"F7" [list $windefs(VK_F7) 0] \
"F8" [list $windefs(VK_F8) 0] \
"F9" [list $windefs(VK_F9) 0] \
"F10" [list $windefs(VK_F10) 0] \
"F11" [list $windefs(VK_F11) 0] \
"F12" [list $windefs(VK_F12) 0] \
"F13" [list $windefs(VK_F13) 0] \
"F14" [list $windefs(VK_F14) 0] \
"F15" [list $windefs(VK_F15) 0] \
"F16" [list $windefs(VK_F16) 0] \
"F17" [list $windefs(VK_F17) 0] \
"F18" [list $windefs(VK_F18) 0] \
"F19" [list $windefs(VK_F19) 0] \
"F20" [list $windefs(VK_F20) 0] \
"F21" [list $windefs(VK_F21) 0] \
"F22" [list $windefs(VK_F22) 0] \
"F23" [list $windefs(VK_F23) 0] \
"F24" [list $windefs(VK_F24) 0] \
"NUMLOCK" [list $windefs(VK_NUMLOCK) 0] \
"SCROLL" [list $windefs(VK_SCROLL) 0] \
"SCROLLLOCK" [list $windefs(VK_SCROLL) 0] \
"LSHIFT" [list $windefs(VK_LSHIFT) 0] \
"RSHIFT" [list $windefs(VK_RSHIFT) 0 -extended] \
"LCONTROL" [list $windefs(VK_LCONTROL) 0] \
"RCONTROL" [list $windefs(VK_RCONTROL) 0 -extended] \
"LMENU" [list $windefs(VK_LMENU) 0] \
"LALT" [list $windefs(VK_LMENU) 0] \
"RMENU" [list $windefs(VK_RMENU) 0 -extended] \
"RALT" [list $windefs(VK_RMENU) 0 -extended] \
"BROWSER_BACK" [list $windefs(VK_BROWSER_BACK) 0] \
"BROWSER_FORWARD" [list $windefs(VK_BROWSER_FORWARD) 0] \
"BROWSER_REFRESH" [list $windefs(VK_BROWSER_REFRESH) 0] \
"BROWSER_STOP" [list $windefs(VK_BROWSER_STOP) 0] \
"BROWSER_SEARCH" [list $windefs(VK_BROWSER_SEARCH) 0] \
"BROWSER_FAVORITES" [list $windefs(VK_BROWSER_FAVORITES) 0] \
"BROWSER_HOME" [list $windefs(VK_BROWSER_HOME) 0] \
"VOLUME_MUTE" [list $windefs(VK_VOLUME_MUTE) 0] \
"VOLUME_DOWN" [list $windefs(VK_VOLUME_DOWN) 0] \
"VOLUME_UP" [list $windefs(VK_VOLUME_UP) 0] \
"MEDIA_NEXT_TRACK" [list $windefs(VK_MEDIA_NEXT_TRACK) 0] \
"MEDIA_PREV_TRACK" [list $windefs(VK_MEDIA_PREV_TRACK) 0] \
"MEDIA_STOP" [list $windefs(VK_MEDIA_STOP) 0] \
"MEDIA_PLAY_PAUSE" [list $windefs(VK_MEDIA_PLAY_PAUSE) 0] \
"LAUNCH_MAIL" [list $windefs(VK_LAUNCH_MAIL) 0] \
"LAUNCH_MEDIA_SELECT" [list $windefs(VK_LAUNCH_MEDIA_SELECT) 0] \
"LAUNCH_APP1" [list $windefs(VK_LAUNCH_APP1) 0] \
"LAUNCH_APP2" [list $windefs(VK_LAUNCH_APP2) 0] \
]
}
}
proc twapi::_parse_send_keys {keys {inputs ""}} {
variable vk_map
_init_vk_map
set n [string length $keys]
set trailer [list ]
for {set i 0} {$i < $n} {incr i} {
set key [string index $keys $i]
switch -exact -- $key {
"+" -
"^" -
"%" {
lappend inputs [concat keydown $vk_map($key)]
set trailer [linsert $trailer 0 [concat keyup $vk_map($key)]]
}
"~" {
lappend inputs [concat key $vk_map(RETURN)]
set inputs [concat $inputs $trailer]
set trailer [list ]
}
"(" {
set nextparen [string first ")" $keys $i]
if {$nextparen == -1} {
error "Invalid key sequence - unterminated ("
}
set inputs [concat $inputs [_parse_send_keys [string range $keys [expr {$i+1}] [expr {$nextparen-1}]]]]
set inputs [concat $inputs $trailer]
set trailer [list ]
set i $nextparen
}
"\{" {
set nextbrace [string first "\}" $keys $i]
if {$nextbrace == -1} {
error "Invalid key sequence - unterminated $key"
}
if {$nextbrace == ($i+1)} {
set nextbrace [string first "\}" $keys $nextbrace]
if {$nextbrace == -1} {
error "Invalid key sequence - unterminated $key"
}
}
set key [string range $keys [expr {$i+1}] [expr {$nextbrace-1}]]
set bracepat [string toupper $key]
if {[info exists vk_map($bracepat)]} {
lappend inputs [concat key $vk_map($bracepat)]
} else {
set c [string index $key 0]
set count [string trim [string range $key 1 end]]
scan $c %c unicode
if {[string length $count] == 0} {
set count 1
} else {
incr count 0
if {$count < 0} {
error "Negative character count specified in braced key input"
}
}
for {set j 0} {$j < $count} {incr j} {
lappend inputs [list unicode 0 $unicode]
}
}
set inputs [concat $inputs $trailer]
set trailer [list ]
set i $nextbrace
}
default {
scan $key %c unicode
if {$unicode >= 0x61 && $unicode <= 0x7A} {
lappend inputs [list key [expr {$unicode-32}] 0]
} elseif {$unicode >= 0x30 && $unicode <= 0x39} {
lappend inputs [list key $unicode 0]
} else {
lappend inputs [list unicode 0 $unicode]
}
set inputs [concat $inputs $trailer]
set trailer [list ]
}
}
}
return $inputs
}
proc twapi::_style_mask_to_symbols {style exstyle} {
variable windefs
set attrs [list ]
if {$style & $windefs(WS_POPUP)} {
lappend attrs popup
if {$style & $windefs(WS_GROUP)} { lappend attrs group }
if {$style & $windefs(WS_TABSTOP)} { lappend attrs tabstop }
} else {
if {$style & $windefs(WS_CHILD)} {
lappend attrs child
} else {
lappend attrs overlapped
}
if {$style & $windefs(WS_MINIMIZEBOX)} { lappend attrs minimizebox }
if {$style & $windefs(WS_MAXIMIZEBOX)} { lappend attrs maximizebox }
}
if {$style & $windefs(WS_CAPTION)} {
lappend attrs caption
} else {
if {$style & $windefs(WS_BORDER)} { lappend attrs border }
if {$style & $windefs(WS_DLGFRAME)} { lappend attrs dlgframe }
}
foreach mask {
WS_MINIMIZE WS_VISIBLE WS_DISABLED WS_CLIPSIBLINGS
WS_CLIPCHILDREN WS_MAXIMIZE WS_VSCROLL WS_HSCROLL WS_SYSMENU
WS_THICKFRAME
} {
if {$style & $windefs($mask)} {
lappend attrs [string tolower [string range $mask 3 end]]
}
}
if {$exstyle & $windefs(WS_EX_RIGHT)} {
lappend attrs right
} else {
lappend attrs left
}
if {$exstyle & $windefs(WS_EX_RTLREADING)} {
lappend attrs rtlreading
} else {
lappend attrs ltrreading
}
if {$exstyle & $windefs(WS_EX_LEFTSCROLLBAR)} {
lappend attrs leftscrollbar
} else {
lappend attrs rightscrollbar
}
foreach mask {
WS_EX_DLGMODALFRAME WS_EX_NOPARENTNOTIFY WS_EX_TOPMOST
WS_EX_ACCEPTFILES WS_EX_TRANSPARENT WS_EX_MDICHILD WS_EX_TOOLWINDOW
WS_EX_WINDOWEDGE WS_EX_CLIENTEDGE WS_EX_CONTEXTHELP WS_EX_CONTROLPARENT
WS_EX_STATICEDGE WS_EX_APPWINDOW
} {
if {$exstyle & $windefs($mask)} {
lappend attrs [string tolower [string range $mask 6 end]]
}
}
return $attrs
}
proc twapi::_show_theme_colors {class part {state ""}} {
set w [toplevel .themetest$class$part$state]
set h [OpenThemeData [winfo id $w] $class]
wm title $w "$class Colors"
label $w.title -text "$class, $part, $state" -bg white
grid $w.title -
set part [::twapi::TwapiThemeDefineValue $part]
set state [::twapi::TwapiThemeDefineValue $state]
foreach x {BORDERCOLOR FILLCOLOR TEXTCOLOR EDGELIGHTCOLOR EDGESHADOWCOLOR EDGEFILLCOLOR TRANSPARENTCOLOR GRADIENTCOLOR1 GRADIENTCOLOR2 GRADIENTCOLOR3 GRADIENTCOLOR4 GRADIENTCOLOR5 SHADOWCOLOR GLOWCOLOR TEXTBORDERCOLOR TEXTSHADOWCOLOR GLYPHTEXTCOLOR FILLCOLORHINT BORDERCOLORHINT ACCENTCOLORHINT BLENDCOLOR} {
set prop [::twapi::TwapiThemeDefineValue TMT_$x]
if {![catch {twapi::GetThemeColor $h $part $state $prop} color]} {
label $w.l-$x -text $x
label $w.c-$x -text $color -bg $color
grid $w.l-$x $w.c-$x
} else {
label $w.l-$x -text $x
label $w.c-$x -text "Not defined"
grid $w.l-$x $w.c-$x
}
}
CloseThemeData $h
}
proc twapi::_show_theme_fonts {class part {state ""}} {
set w [toplevel .themetest$class$part$state]
set h [OpenThemeData [winfo id $w] $class]
wm title $w "$class fonts"
label $w.title -text "$class, $part, $state" -bg white
grid $w.title -
set part [::twapi::TwapiThemeDefineValue $part]
set state [::twapi::TwapiThemeDefineValue $state]
foreach x {GLYPHTYPE FONT} {
set prop [::twapi::TwapiThemeDefineValue TMT_$x]
if {![catch {twapi::GetThemeFont $h NULL $part $state $prop} font]} {
label $w.l-$x -text $x
label $w.c-$x -text $font
grid $w.l-$x $w.c-$x
}
}
CloseThemeData $h
}
proc twapi::write_bmp_file {filename bmp} {
binary scan $bmp "iiissiiiiii" size width height planes bitcount compression sizeimage xpelspermeter ypelspermeter clrused clrimportant
if {$size != 40} {
error "Unsupported bitmap format. Header size=$size"
}
if {$bitcount == 0} {
error "Unsupported format: implicit JPEG or PNG"
} elseif {$bitcount == 1} {
set color_table_size 2
} elseif {$bitcount == 4} {
set color_table_size 16
} elseif {$bitcount == 8} {
set color_table_size 256
} elseif {$bitcount == 16 || $bitcount == 32} {
if {$compression == 0} {
set color_table_size $clrused
} elseif {$compression == 3} {
set color_table_size 3
} else {
error "Unsupported compression type '$compression' for bitcount value $bitcount"
}
} elseif {$bitcount == 24} {
set color_table_size $clrused
} else {
error "Unsupported value '$bitcount' in bitmap bitcount field"
}
set filehdr_size 14;                # sizeof(BITMAPFILEHEADER)
set bitmap_file_offset [expr {$filehdr_size+$size+($color_table_size*4)}]
set filehdr [binary format "a2 i x2 x2 i" "BM" [expr {$filehdr_size + [string length $bmp]}] $bitmap_file_offset]
set fd [open $filename w]
fconfigure $fd -translation binary
puts -nonewline $fd $filehdr
puts -nonewline $fd $bmp
close $fd
}
proc twapi::_hotkeysyms_to_vk {hotkey} {
variable vk_map
_init_vk_map
set keyseq [split [string tolower $hotkey] -]
set key [lindex $keyseq end]
set modifiers 0
foreach modifier [lrange $keyseq 0 end-1] {
switch -exact -- [string tolower $modifier] {
ctrl -
control {
setbits modifiers 2
}
alt -
menu {
setbits modifiers 1
}
shift {
setbits modifiers 4
}
win {
setbits modifiers 8
}
default {
error "Unknown key modifier $modifier"
}
}
}
if {[string length $key] == 1} {
scan $key %c unicode
if {$unicode >= 0x61 && $unicode <= 0x7A} {
set vk [expr {$unicode-32}]
} elseif {($unicode >= 0x30 && $unicode <= 0x39)
|| ($unicode >= 0x41 && $unicode <= 0x5A)} {
set vk $unicode
} else {
error "Only alphanumeric characters may be specified for the key. For non-alphanumeric characters, specify the virtual key code"
}
} elseif {[info exists vk_map($key)]} {
set vk [lindex $vk_map($key) 0]
} elseif {[info exists vk_map([string toupper $key])]} {
set vk [lindex $vk_map([string toupper $key]) 0]
} elseif {[string is integer $key]} {
set vk $key
} else {
error "Unknown or invalid key specifier '$key'"
}
return [list $modifiers $vk]
}
proc twapi::_format_display_device {dev} {
set fields {-name -description -flags -id -key}
set flags [lindex $dev 2]
foreach {opt flag} {
desktop         0x00000001
multidriver     0x00000002
primary         0x00000004
mirroring       0x00000008
vgacompatible   0x00000010
removable       0x00000020
modespruned         0x08000000
remote              0x04000000
disconnect          0x02000000
} {
lappend fields -$opt
lappend dev [expr { $flags & $flag ? true : false }]
}
return [kl_create2 $fields $dev]
}
proc twapi::_format_display_monitor {dev} {
set fields {-name -description -flags -id -key}
set flags [lindex $dev 2]
foreach {opt flag} {
active         0x00000001
attached       0x00000002
} {
lappend fields -$opt
lappend dev [expr { $flags & $flag ? true : false }]
}
return [kl_create2 $fields $dev]
}
proc twapi::_format_monitor_info {hmon} {
return [kl_create2 {-extent -workarea -primary -name} $hmon]
}
proc twapi::_get_message_only_windows {args} {
array set opts [parseargs args {
class.arg
text.arg
single
} -nulldefault -maxleftover 0]
set wins [list ]
set prev 0
while true {
set win [FindWindowEx -3 $prev "" ""]
if {$win == 0} break
lappend wins $win
if {$opts(single)} break
set prev $win
}
return $wins
}
#-- from twapi.dll
MZ       ÿÿ  ¸       @                                     º ´	Í!¸LÍ!This program cannot be run in DOS mode.
$       –c”œÒúÏÒúÏÒúÏ©öÏÓúÏQôÏÕúÏ½ñÏÓúÏ½ğÏ×úÏ½şÏÖúÏÒúÏÚúÏ„éÏÊúÏ°éÏŞúÏ§ÏÍúÏÒûÏ© úÏÔ!ğÏÚúÏÔ!ñÏØúÏüÏÓúÏ-"şÏÓúÏRichÒúÏ        PE  L ¸‘J        à !  È       ÏÏ     à                             –u                        : [    ÷ ô    H                     È_  °ê                                             à ¤
                          .text   OÆ     È                   `.rdata  {Z   à  \   Ì             @  @.data   DÊ  @  Ä  (             @  À.rsrc   H        ì             @  @.reloc  na      b   ğ             @  B                                                                                                                                                                                                                                                                                                                ÃV‹t$WVè4 3ÿY;Ç…<  ¡d	hŒ	hˆ	h„	h€	ÿd  Vè|F ƒÄ…ÀuGh˜ÿäƒøu?jWÿ(êh 	Ç 	”   ÿ ä…Àu¡d	WhÔ@Vÿ¨  ƒÄjXéÁ   ¡d	WWhW hÀ@Vÿˆ  ¡d	WWh[ h´@Vÿˆ  ¡d	WWhP h¤@Vÿˆ  ¡d	WWhÎ# hŒ@Vÿˆ  ¡d	ƒÄPWWh¨Nht@Vÿˆ  ¡d	WWhËMh`@Vÿˆ  ¡d	WWh#GhH@Vÿˆ  ¡d	Wh  ÿ|  ƒÄD3À_^ÃU‹ìì@  SVWjX3ö9E‰uğ‰uØÇEĞÿÿÿ}8¡d	h¸Bÿujÿuÿ(  ¡d	j°°  è¢!  PÿuÿƒÄé	  9E‹}‹]‰Eü¿   ‹Eüÿ4‡¡d	ÿX  Ph¨Bè¶º ƒÄ…ÀuÇEğ   é   ‹Eüÿ4‡¡d	ÿX  Ph˜Bè‡º ƒÄ…Àu	ÇEØ   ëU‹Eüÿ4‡¡d	ÿX  PhˆBè[º ƒÄ…À…û   ‹Eü@;E‰Eü„Ì   MĞQÿ4‡¡d	Sÿ    ƒÄ…À…¶   ÿEü‹Eü;EŒAÿÿÿ¡d	h   VÿwSÿ  ƒÄ;Æ„$  MäQMôQP¡d	Sÿ¼   ƒÄ…À…  EÔPEìP¡d	ÿwSÿ¼   ƒÄ…À…â  }ì€   †˜   ¡d	VhlBSÿ¨  ¡d	j°°  è0   PSÿƒÄé¥  VhLBëVhB¡d	Sÿ¨  ƒÄë+‹Mü¡d	j hBÿ4°   ÿX  YPhôASÿƒÄ¡d	j°°  èÈ  PSÿƒÄé=  9uì‰u:  µÀóÿÿ‹}EøPEèP‹EÔÿ4¸¡d	ÿuÿ¼   ƒÄ…À…  ‹Eø^Sÿ0¡d	ÿ¬   ‰3ÀÇF   ‰F‰Fj.‰Fÿ6¡d	ÿ(  ‹øƒÄ…ÿ„—   +G‰Š:ğAuhğAWèr¸ Y…ÀYu	ÇF   ënŠ:ìAuhìAWèN¸ Y…ÀYu!FëNŠ:äAuhäAWè.¸ Y…ÀYu	ÇF   ë*Š:ÜA…“  hÜAWè¸ Y…ÀY…~  ÇF   ƒ}è~‹Eøƒ}è‹H‰N~‹@‰FÿEƒÆ‹E;EìŒÎşÿÿ3ö¡d	VVÿÜ   ‰EÜ¡d	VVÿÜ   ƒÄ9uô‰Eè‰uÊ  ‹E‹ğEøP‹EäÁæÿ4¡d	ÿ¬   ‹øYY€?-…   ŠG_„À„’  <-u
€ „„  3É9Mì‰Mü  ‹UøIÁàJ9”Äóÿÿu"‹MøIQSÿ´Àóÿÿ¡d	ÿÌ  ‹MüƒÄ…Àt	A;Mì‰Mü|Â;Mì»   IÁàƒ¼Ôóÿÿ…‡   ¡d	jÿÌ   Y‹MüI‰„ÍÌóÿÿéì   ‹MÔ¡d	j hBÿ4¹°   ÿX  YPh¸Aÿuÿ¡d	j°°  è<  PÿuÿƒÄ é¯  ¡d	j hBWh Aÿuÿ   ëÃ‹MôI9Mø   ‹MäÿE‹L‰ŒÌóÿÿëeƒ}ğ „ê   ‹Eäÿ4¡d	ÿuÜÿuÿ¸   ‹EôƒÄH9E}8‹Eäÿt¡d	ÿX  €8-Yt ÿE‹Eä‹Mÿ4ˆ¡d	ÿuÜÿuÿ¸   ƒÄÿE‹E;EôŒ6şÿÿ3Û9]ì9  µÌóÿÿ‹F…ÀtMøQMàQPÿu¡d	ÿ¼   ƒÄ3É9uƒ~t‹Fü;Áu	9MØ„é  ‰‹F+Á„4  H„í   HtVH„ã   é~  j hBWh€Aëj hBWhlAÿu¡d	ÿ   ¡d	j°°  èĞ  PÿuÿƒÄ é  ‹;Áu¡d	j ÿØ   Y‰ëMÀQPÿu¡d	ÿ¤  ƒÄƒø„Å  3ÿ9~„ò   9}à‰}ğæ   EÈP‹Eøÿ4¸¡d	ÿuÿ¤  ƒÄƒø„¬  ‹EÈ;EÀu‹EÌ;EÄ„®   G;}à‰}ğ|¿é    ‹;Áuj ë"MüQPÿu¡d	ÿˆ   ƒÄƒø„ƒ  ÿuü¡d	ÿÌ   ƒeğ Y‰ë`9u¡d	j hœÿè   Y‰Yƒ~ tR3ÿ9}à‰}ğ~6ÿ6¡d	ÿX  YP‹Eøÿ4¸¡d	ÿX  YPèí³ Y…ÀYt	G;}à‰}ğ|Êƒ~ t‹Eà9Eğ„*  ÿvø¡d	ÿvô¸¸   ÿè   Pÿuèÿuÿÿ6¡d	ÿuèÿuÿ¸   ƒÄ CƒÆ;]ìŒÍıÿÿ‹Mô‹E+È9MĞ&  ¡d	j°°  è  Pÿuÿ¡d	j hDAÿuÿ¨  ‹Mä‹EƒÄh@AQ‹Mô+ÈQÿu¡d	ÿ   YPèè
  ƒÄé  [Áàÿ´Äóÿÿÿ´Àóÿÿÿ´Ìóÿÿh4AëB[Áàÿ´Äóÿÿÿ´Àóÿÿÿ´ÌóÿÿhAë [Áàÿ´Äóÿÿÿ´Àóÿÿÿ´ÌóÿÿhAÿuèú   ƒÄé   [Áàÿ´Äóÿÿÿ´Àóÿÿÿ´ÌóÿÿhAÿuèÊ   ¡d	j hô@ÿuÿ   ƒÄ hğ@ÿuøÿuàéÿÿÿ;Eô}#‹u‹Eäÿ4°¡d	ÿuÜÿuÿ¸   ƒÄF;uô|à‹Eh   ÿuÜj ÿp¡d	ÿuÿ  ƒÄ…Àu;‹EÜ…Àtÿƒ8 P¡d	ÿ€   Y‹Eè…Àtÿƒ8 P¡d	ÿ€   YjXëÿuè¡d	ÿuÿ´  Y3ÀY_^[ÉÃU‹ì¡d	VWj hœÿè   Y‹ø¡d	Yj høBÿupDÿX  YPhìBÿuWÿÿu¡d	ÿuWÿPH¡d	jhBWÿPH¡d	Wÿuÿ´  ƒÄ8_^]ÃU‹ìƒì$S‹]VƒûWŒ´  û€   ¨  ‹ÃÁàƒÀ$üè± …Û‹ü~‹M‹Ç+Ï‹Ó‹4‰0ƒÀJuõƒeô j^‰};Ş   ÇEø   ÇEü   _ÿ3¡d	ÿX  PhÌCè¶° ƒÄ…Àu‹Eü;E1  ƒEüƒÆƒÃƒEøëIÿ3¡d	ÿX  PhÄCè{° ƒÄ…À…1  ‹Eø;Eò   ƒ}ô …  ƒEü‰uôFƒÃFƒEø;uŒsÿÿÿ‹]¡d	j ÿwSÿœ  ƒÄƒø‰E…{  P¡d	j h¸CSÿĞ  ƒÄ…À„\  MğQMìQP¡d	Sÿ¼   ƒÄ…À…<  ƒ}ì ¸œ‰Eü‰Eø~/‹Eğÿ0¡d	ÿX  ƒ}ìY‰Eü~‹Eğÿp¡d	ÿX  Y‰Eø‹EjYƒÀş;Á‰M‰EÜå  w‹E;EôuxÿMƒîé(  ÿu¡d	ÿl  ¡d	Ç$|Cÿujÿuÿ(  ƒÄjXéñ  ÿu¡d	ÿl  ¡d	Yj h<Cÿ7°   ÿX  YPh CÿuÿƒÄë¾EPEèP¡d	ÿ6Sÿ¼   ƒÄ…Àu¡9Eè„­   ‹Eÿ0¡d	ÿX  PÿuüèÆ® ƒÄ…Àuuƒ}è„ƒ   ‹Eÿp¡d	ÿX  Pÿuøè›® ƒÄ…ÀtbEàP‹Eÿp¡d	Sÿ    ƒÄ…Àu-‹Eø€8 t%EäP‹Eğÿp¡d	Sÿ    ƒÄ…Àu‹Eä;EàtƒEƒÆ‹E;EÜ”   é­şÿÿ¡d	Sp|ÿ   Pÿ‹ğSÿ¡d	ÿl  SèÕ  ƒÄƒø‰EtH¡d	h   Vj hCSÿü  ƒÄ…ÀuÇE   ƒ}t‹Ej ÿt‡¡d	Sÿœ  ƒÄ‰Eÿƒ> ¡d	Vÿ€   Yƒ}ô tLÿuSèŒ  ‹ğ¡d	Sÿl  ‹Eôj ÿt‡¡d	Sÿœ  ƒÄƒø‰EVSu	è[  YYë
è<  Y‰EY‹EeĞ_^[ÉÃU‹ìQƒ}SVWŒİ   ƒ}Ó   ‹]EüPEP¡d	ÿsÿuÿ¼   ƒÄ…À…Ç   öEtP¡d	hDÿuÿ¨  ƒÄé¥   ÿs¡d	ÿX  3öY9u‹ø~,‹Eüÿ4°¡d	ÿX  YŠ:uPWè«¬ Y…ÀYt$FF;u|Ôƒ}u ÿsÿu¡d	ÿ´  Y3ÀYëG‹Eüÿt°ëã¡d	j høCWhìCÿuÿ   ƒÄë¡d	hÔCÿujÿuÿ(  ƒÄjX_^[ÉÃU‹ìƒì8¡d	SVÿup|ÿ   Pÿ‹ØEÈ¾@@P¡d	Vÿuÿ„  ƒÄ…ÀuP¡d	h\Dÿuÿ   ƒÄé¤   ¡d	WƒÏÿWVÿè   ‰Eè¡d	WhCÿè   ‰Eì¡d	WhPDÿè   ‰Eğ¡d	Wh¸Cÿè   ƒÄ ‰EôMèj_‹×‹Ïÿ Ju÷EèPWÿuÿuĞÿUÌƒÄ‰Eøuè‰}ü‹ÿ‹ƒ8 P¡d	ÿ€   Y÷ÿMüuáƒ}ø_uÿƒ; ¡d	Sÿ€   YjXë¡d	Sÿuÿ´  Y3ÀY^[ÉÃU‹ìƒìƒ=€	…Æ   ƒ=„	…¹   ¡d	S‹]VWS‹³   x|ƒæÿ   Pÿj‰Eì¡d	j hPDSÿĞ  ƒÄ‰Eğ…Àu¡d	ÿä   ‰Eğ¡d	jj h¸CSÿĞ  ƒÄ‰Eô…Àu¡d	ÿä   ‰Eô¡d	Vÿà   ÿu‰Eø¡d	ÿØ   ‰EüEìP¡d	jÿÜ   ƒÄÿ _^[ÉÃÿu¡d	ÿuÿd  YYÉÃU‹ìƒìƒ=€	…î   ƒ=„	…á   SV‹uEWPEü3ÛP¡d	VSÿ¼   ƒÄ…Àu@ƒ}üu:EøP‹Eÿp¡d	Sÿ¤   ƒÄ…ÀuEôP‹Eÿp¡d	Sÿ    ƒÄ…Àt¡d	hxDÿPY‹E‹}jÿp¡d	Sh¸CWÿü  ‹Ejÿp¡d	ShPDWÿü  ‹Eÿ0¡d	Wÿ´  ‹EøƒÄ0	‡   ÿ9¡d	Vÿ€   Y‹Eô_^[ÉÃÿu¡d	ÿuÿh  YYÉÃƒ=€	u"ƒ=„	u‹D$ÿƒ8 P¡d	ÿ€   YÃÿt$¡d	ÿl  YÃ¡d	j j ÿÜ   P¡d	ÿt$ÿ´  ƒÄ3ÀÃU‹ìƒìPÿuÿ$åY‹M…À‰t3ÀÉÃƒ} t:ÿuE°h˜DjPPÿ(åj E°ÿuP¡d	ÿuÿ   j jÿuèÀ  ƒÄ,h €ÿäjXÉÃU‹ìQQWÿuèn¨ 3ÿY9}‰Eü~OSV‹uEøP¡d	ÿ6ÿ¬   Y‹Ø…ÿY~ÿuü¡d	ÿuÿuÿPHƒÄÿuø¡d	SÿuÿPHƒÄGƒÆ;}|¸^[‹E_ÉÃSV‹t$ÿt$ƒf ƒf ƒf Ç   ÇF   ÿä‹Ø…Ûth¸DSÿä…ÀtVÿĞSÿä^[ÃW‹|$…ÿt¡d	VW°ğ  ÿ0æPWÿYY^_Ã¡d	j hœÿè   YY_ÃU‹ìƒìPEP¡d	ÿuÿuÿ    ƒÄ…ÀuO‹E;E|;E‹M…Ét‰3ÀÉÃƒ} t/ÿuÿuPhÈDE°jPPÿ(åE°jP¡d	ÿuÿ¨  ƒÄ$jXÉÃU‹ìƒìV‹u·P¡d	ÿØ   ‰Eä·FP¡d	ÿØ   ‰Eè·FP¡d	ÿØ   ‰Eì·FP¡d	ÿØ   ‰Eğ·F
P¡d	ÿØ   ‰Eô·FP¡d	ÿØ   ‰Eø·FP¡d	ÿØ   ‰EüEäP¡d	jÿÜ   ƒÄ$^ÉÃU‹ìQQSVEüWPEøP¡d	ÿuÿuÿ¼   ƒÄ…À…Z  ƒ}ø‹}}Wÿä‹Eø3Û3ö+Ãf‰_
f‰_f‰_„<  H„  H„à   H„´   H„…   HtYHt,EP‹Eühkx  Sÿ0ÿuèUşÿÿƒÄ…À…ë   f‹Ejf‰^EP‹Eüjjÿ4°ÿuè*şÿÿƒÄ…À…À   f‹EFf‰GEP‹EüjSÿ4°ÿuèşÿÿƒÄ…À…—   f‹EFf‰GEP‹Eühç  Sÿt°ÿuèÔıÿÿƒÄ…Àunf‹Ef‰GEP‹Eüj<Sÿt°ÿuè¯ıÿÿƒÄ…ÀuIf‹Ef‰GEP‹Eüj;Sÿt°ÿuèŠıÿÿƒÄ…Àu$f‹Ef‰G
EP‹EüjSÿ4°ÿuèfıÿÿƒÄ…ÀtjXë
f‹Ef‰G3À_^[ÉÃ‹D$ÿpÿ0¡d	ÿ¨  YYÃU‹ìQQEøP¡d	ÿuÿuÿ¤  ƒÄ…ÀtjXÉÃ‹E…Àt‹Mø‰‹Mü‰H3ÀÉÃ‹D$ÿpÿ0¡d	ÿ¨  YYÃU‹ìQQEøP¡d	ÿuÿuÿ¤  ƒÄ…ÀtjXÉÃ‹E…Àt‹Mø‰‹Mü‰H3ÀÉÃU‹ìQVEü3öPVVÿu‰uüÿ\æ…Àt¡d	Vhœÿè   YYëÿuüè0üÿÿY‹ğÿuüÿXæ‹Æ^ÉÃU‹ìƒì‹EV3ö;ÆuEğP¡d	VVVÿuÿĞ  YYPÿ`æ;Æ}9utVPÿuèÑ  ƒÄjXë3À^ÉÃ‹T$V‹Â¶J¶2ÁáÎt¶4Á¶HÁáëí+Â@@P¡d	RÿĞ   YY^ÃU‹ìEVP¡d	ÿuÿŒ   ƒ}YY‹ğ}‹Eƒ  ëW‹ÎŠ„Òu8Qt¶A¶ÒÁàÂ‹UƒÂş;Â8)EÈëØÿuÿ,ê‹M…À‰u9Et2PhEëÿuVPÿåƒÄ3Àëj hìDÿu¡d	ÿ¨  ƒÄjX^]Ãƒ|$ t
ÿt$ÿ0êÃU‹ìƒìPƒ} t&E°j(Pÿuÿ4ê…ÀtE°jÿP¡d	ÿğ  ë¡d	j hœÿè   YYÉÃU‹ìEPÿuÿ¨æ…Àt3À]Ã¡d	Vjÿÿuÿè   Y‹ğYEPÿ¬æ‹Æ^]Ãÿt$¡d	ÿt$ÿX  YPÿ æ…ÀuÃj Pÿt$è(
  ƒÄjXÃ‹D$·ÑéQÿp¡d	ÿğ  YYÃU‹ììÔ   …,ÿÿÿVP¡d	ÿğ  …,ÿÿÿPÿuÿuè%   ‹ğƒÄ…öu…,ÿÿÿP¡d	ÿuÿô  YY‹Æ^ÉÃU‹ìQÿu¡d	ÿğ  YEüPÿuÿpá…Àu59Et+P¡d	h0Eÿuÿ¨  ƒÄj ÿüãPÿuèb	  ƒÄjXÉÃ¡d	jÿÿuüÿuÿÜ  ƒÄÿuüÿ ä3ÀÉÃU‹ììÔ   …,ÿÿÿVP¡d	ÿğ  …,ÿÿÿPÿuÿuèVÿÿÿ‹ğƒÄ…öu-¡d	jÿÿµ,ÿÿÿÿè   ‹M‰…,ÿÿÿP¡d	ÿè  ƒÄ‹Æ^ÉÃU‹ìƒì‹ESVW3ÿ‹]‰8EP¡d	W3öÿu‰}üSÿÀ   ƒÄƒø„Á   9}t2ÿu¡d	ÿø  ‹MüFD‰EüEP¡d	VÿuSÿÀ   ƒÄëÀÿEüEôP‹EüÀPWSè1÷ÿÿƒÄ…Àuo‹uôEP‰}øWÿu¡d	SÿÀ   ƒÄƒøtC9}tMEüP¡d	ÿuÿĞ  Y;ÇYtÿEü‹MüÉQPVÿå‹EüƒÄ4FÿEøEPÿuøë¦ÿuôÿåYjXë‹Mf‰>‹Eô‰3À_^[ÉÃU‹ìQ¡d	SV3öWVVÿÜ   ‹}Y;şY‰EütYf97tTWÿå‹Ø¡d	SWÿğ  ‹ğVÿuüÿ¡d	ÿuÿ¸   ƒÄƒøt(ÿƒ> ¡d	Vÿ€   Yfƒ|_ |_u¬‹Eü_^[ÉÃÿƒ> ¡d	Vÿ€   Yÿuüè0  Y3ÀëÚU‹ìEP¡d	ÿuÿuÿ¤   ƒÄ…Àu(‹E©  ÿÿt#ƒ} t¡d	j hPEÿuÿ¨  ƒÄjX]Ã‹Mf‰3À]ÃU‹ìSV‹5àèW‹}j WÿÖjW‰EÿÖjW‹ØÿÖÿu3ö;ŞÿuÿuWt9PÿuÿÓƒÄƒ}‹Øu09utÿu¡d	ÿh  YVV‹5äèWÿÖj jWÿÖëÿèè‹Ø_‹Ã^[]Â U‹ìƒì4SV3öWf95 ¿xEu=j0EÌ[SVPè ƒÄEÌ‰]Ì‰uàPÇEÜ   ÇEÔI. ‰}ôÿÔèf;Æf£ tVVVVVVVVVVWVÿØè;Æ‰EüuVÿüãPÿuèÈ  ƒÄé   ÿu¡d	ÿ,  YVÿäÿu‹=äèVÿuüÿ×‹üã…ÀuÿÓ…Àu(ÿujÿuüÿ×…ÀuÿÓ…Àuÿujÿuüÿ×…Àu(ÿÓ…Àt"VÿÓPÿuèW  ÿu¡d	ÿh  ƒÄjXë‹E;Æt‹Mü‰VVh €  ÿuüÿÜè3À_^[ÉÃU‹ìƒì S3ÛV‹uW‰]è‰]ü‰]ø¡ åj_98~¶jPÿåYYë‹å¶‹	ŠAƒà…ÀtFëÌŠ<-uF‰}øë<+uF‹M…Éu6€>0u%ŠFF<xt<Xt‰}üÇE   ë8FÇE   é   ÇE
   éˆ   ƒùu€>0…æ   €~x…Ü   FFƒùud¾>ƒï0ƒÿ‡º  ‹EèjY‹Óè j‰EğY‰Uôèïœ ;Eè…Ä  ;Ó…¼  3Û}ğ]ô‰}è;]ô‚¨  w	;}ğ‚  ÇEü   Fëœƒù
ug¾>ƒï0ƒÿ	‡Q  j j
SÿuèèTœ j j
RP‰Eğ‰UôèÓ› ;Eè…X  ;Ó…P  3Û}ğ]ô‰}è;]ô‚<  w	;}ğ‚1  ÇEü   Fë™ƒùut¾ƒè0ƒøJ‡å   ¾¸œEƒÿ‡Õ   ‹EèjY‹Óè8œ j‰EğY‰Uôè
œ ;Eè…ß   ;Ó…×   3Û}ğ]ô‰}è;]ô‚Ã   w	;}ğ‚¸   ÇEü   FëŒƒù|{ƒù$v¾ƒè0ƒøJwkë‹M¾¸œE;ùs[‹ÁSÿuè™RP‰Eà‰UäèW› ÿuä‰Eğ‰UôÿuàRPèÔš ;Eèu];ÓuY3Û}ğ]ô‰}è;]ôrIw;}ğrB¾FFƒè0ƒøJÇEü   v—3É9Møt‹Eè÷ØÙ‰Eè÷Û9Müu‹u‹E;Át‰0‹Eè‹Ó_^[ÉÃÿå‹MÇ "   …Ét¾ƒè0ƒøJw¾€œE;EsFëæ‰1ƒÊÿ‹ÂëÅU‹ìì€   ‹M…É|ƒùs9ÍèEu	‹ÍìEë3Ò¸èE9tƒÀB= Frñë‹ÕìE…ÀuQE€hğFPÿüäƒÄE€jÿP¡d	ÿè   YYÉÃU‹ìƒì¡d	jh Gÿè   ÿu‰Eô¡d	ÿØ   ÿu‰EøèZÿÿÿ‰EüEôP¡d	jÿÜ   ƒÄÉÃU‹ìƒì`VWj ÿuè  ‹øY…ÿYur}4  ‹5øãr6}·  w-¡¤…ÀujPh¤GÿÖ…À£¤tPÿuèÑ  ‹øY…ÿYu-¡¨…ÀujPh”GÿÖ…À£¨tPÿuè¤  Y‹øY…ÿt‹Çë5ƒ}xuh0GÿôäYë!ÿuE hGj0PÿøäE PÿôäƒÄ_^ÉÃU‹ìƒì8¡d	VjhĞGÿè   ÿu‰Eğ¡d	ÿà   ÿu‰Eôèÿÿÿ‹ğƒÄ…öt#VÿåP¡d	Vÿğ  V‰EøÿåƒÄë+ÿuEÈh¼Gj(Pÿ(åEÈjÿP¡d	ÿè   ƒÄ‰Eø‹EMğQ3É…À•Á‰Eü¡d	ƒÁQÿÜ   YY^ÉÃU‹ìW‹}…ÿujXé˜   Sÿuÿuè0ÿÿÿ‹ØEP¡d	jSj ÿÀ   ƒÄ…Àu\9EtW¡d	VWÿ   ‹ğ¡d	Vÿø  Y…ÀYt¡d	jhÜGVÿ  ƒÄÿu¡d	Vÿ€  ¡d	VWÿ´  ƒÄ^¡d	SWÿ°  YYjX[_]ÃU‹ìQQSV‹u3ÀWP‰EüPEü»   ÷ŞPSÿuöÿufæ øÆ   Î   Vÿìã‹ø…ÿ~‹uüVÿôäY‰EüVëIj Eøj PSÿuÿuVÿğã‹ø3Û;û~1w6Pÿ$å;ÃY‰EütEVf‰ÿuüVÿuøSSÿôãÿuøÿ ä‹Eü…Àt"…ÿ~fƒ|xş
uO…ÿ~	fƒ|xşuOfƒ$x ‹Eü_^[ÉÃU‹ìì
  V¾¸  9uu$…øıÿÿh   P…øõÿÿh   PEøPèì’ ‰Eüj ÿuÿuè;şÿÿƒÄ9uuiƒ}ü ucÿu¡d	ÿ   ‹ğ¡d	jhÜGVÿ  …øıÿÿjÿP¡d	Vÿ  ¡d	jhàGVÿ  …øõÿÿjÿP¡d	Vÿ  ƒÄ4jX^ÉÃU‹ìƒ} t¡d	jÿuÿuÿ¨  ƒÄj ÿuÿuè˜ıÿÿƒÄjX]ÃU‹ìƒì‹ESVWj3É^;Á‰Mô‰Mü‰Mø‰uìu¡d	Qhÿuÿ¨  ƒÄ‹ÆéÓ  ‹}‹@;ş‹u‰Eğı   ¡d	Qÿvÿ¬   »‰ESPè¨” ƒÄ…Àujë]hÿuè” Y…ÀY„¶   ƒÿu‹EÇEø   ‰Eüé¦   ƒÿŒ   ‹Ej ÿv‰Eü¡d	ÿ¬   SPèI” ƒÄ…ÀurjX;Ç  ÿ4†¡d	ƒeì ÿP|ƒ}ü Y‹ğuj ¡d	Vÿ¬   Y‰EüY‹]j‹Cÿ0EôPVÿuè4  ƒÄƒøurÿƒ> Ø   ¡d	Vÿ€   YéÆ   ÇEø   3Û9]ğ„   ‹Eø+ø†QWÿuSÿUğƒÄ;Ã…›   ¡d	ÿup|ÿ   Pÿ9]üYY‹ğ…uÿÿÿSé^ÿÿÿjÿ$å‹øY‰7ÿ‹Eô‰_‰G‹Eì…À‰Gt	ÿuôèO   Y¡d	hú< WhH= ÿuüÿuÿˆ  ƒÄ‰G3Àë#j hüëShàÿu¡d	ÿ¨  ƒÄjX_^[ÉÃU‹ìQƒ=@ V¾Pu¡d	jVÿÜ  YÇ@   YEüPÿuVÿ€ƒÄ^ÉÃU‹ìÿu¡d	ÿuÿuj ÿuÿ¬   YYPÿuè   ƒÄ]ÃU‹ìƒì\SV‹uW3ÿ€>_„#  ‹Eh”V‰8èn’ Y…ÀY„š  ¡d	jÿVÿè   ‰Eô¡d	jÿhŒÿè   ‰Eø¡d	jÿhÿè   ‰Eü‹Eô‹]Wÿ ‹Eøÿ ‹Eüÿ EôP¡d	jSÿ˜  ‹ğ‹EôƒÄ(ÿ‹Eô98P¡d	ÿ€   Y‹Eøÿ‹Eø98P¡d	ÿ€   Y‹Eüÿ‹Eü98P¡d	ÿ€   Y;÷…¨   ¡d	MQS°¬   ÿ   YPÿYY‹MƒùPƒ€   AQPE¤Pÿå¡d	Su¤ÿl  ƒÄ€}¤_…İşÿÿjFÿuVè@  ‹uƒÄ;÷t{VPè{   ‹ØY;ßYuOöEt'¡d	Whtÿuÿ¨  ÿ6¡d	ÿuÿ  ƒÄjXë<öEtõ¡d	WhTSÿ¨  ƒÄëŞöE‹utÿ6è–   Yÿ6Sèq   Y‰Y3À_^[ÉÃVW‹|$…ÿtW‹wÿt$ÿ6è« Y…ÀYt‹v…öt<;wt7ëá;wt,‹F‹N‰H‹F…Àt‹N‰H‹G‰F‹G…Àt‰p‰w‰~‹Æë3À_^Ã‹D$…Àt‹@…Àtÿt$ÿĞYÃ‹D$Ãƒ=@ t&ÿt$hPÿ|Y…ÀYtP¡d	ÿ¸  YjXÃ3ÀÃSV‹t$W‹|$V2ÛèB Y‹L$	;Â|N…É~J¾Fƒø0|
ƒø9Ààëƒøa|ƒøf	ÀàŠØ¾Fƒø0|	ƒø9,0ëƒøa|	ƒøf,W
ØˆGIu¶‹Æ_^[ÃV‹t$…öt#ƒ~ tÿvèDÿÿÿ…ÀYt‹F‹@…ÀtÿvÿĞY‹ÿ‹ƒ8 P¡d	ÿ€   YVÿåY^ÃU‹ìì   SVWjX3Û9E‰]ø‰Eè}ShüéÁ  ‹}¡d	Sÿwÿ¬   ‹ğh,V‰uüè ƒÄ…Àu‹EÿpÇ@   èêûÿÿYé_  h$VèÛ Y…ÀYu‹u9^t	ÿvè„şÿÿY‰^é5  hVè± Y…ÀYu‹Eÿp¡d	ÿuÿ¨  Yë¨‹uƒàşÿÿÿàşÿÿ‹F‰]ğ‰…àıÿÿ…àıÿÿ‰E‹‹Mƒøÿ‹	t$‹I‹…ÉtƒE@ÿEø‰‹EƒÃ‰]ğƒÿ‰ëĞ…ÉuÿMøƒmƒëƒ}ø ‰]ğŒ‚  ë³‹I@…É‰‰Mt$ë‹M‹	…ÉtÿuüQè Y…ÀY„‚  ƒEuŞhŒÿuüèä Y…ÀY…ƒ   ƒ}PŒşÿÿÿw¡d	ÿ¬   ‰E‹EY‹ Y‹X…Ût#‹…ÀtÿuPè¡ Y…ÀYu	9C…`  ƒÃuİhÿuè€ Y…ÀY„‡  hÿuèi Y…ÀY„‹  ‹]ğéèşÿÿhÿuüèJ Y…ÀY…Ñşÿÿƒ}Œ  jX9E‰Eì¸şÿÿ_¡d	j ÿ3ÿ¬   ‰E‹EY‹ Y‹@…À‰Eôttë‹Eô‹ …ÀtiÿuPèíŒ Y…ÀYuT‹Mô9AtL‹‰Eà‹‰‹ÿ CüPjÿuVÿQ‰Eä‹Eà‰‹ƒÄÿ‹ƒ8 P¡d	ÿ€   Y‹Eä…À…Ã  ƒEèƒEôuƒEìƒÃ‹Eì;EŒVÿÿÿéÿÿÿ‹‹_W‰Gÿu‹ÿuÿ ‹EVÿP‰Eä‰_‹ƒÄÿ‹6ƒ> ¡d	Vÿ€   Y‹Eäé^  ‹GW‰Eà‹j‰Gÿu‹ÿ VÿS‹Ø‹Eà‰G‹ƒÄÿ‹6ƒ> ¡d	Vÿ€   Y‹Ãé  ¡d	ÿ6¸´  ÿP|PÿuÿƒÄëMÿvèı   Y…Àj th ëhüÿu¡d	ÿ¨  ëĞj éqüÿÿhÿuüè•‹ Y…ÀYu‹E9Eè|3Àé¬   hŒÿuüès‹ Y…ÀYuj häÿu¡d	ÿ¨  ƒÄë|¡d	3ÛShœÿuÿ¨  ‹FƒÄ;Ãt\‹x…ÿtEƒ? t@ÿu¡d	ÿÀ  Yÿ7j:PÿìäYYPÿğäY…ÀYuÿ7¡d	ÿuÿ  YYƒÇu»‹F‹@‹ƒÃ…Àu¤jX_^[ÉÃƒ=@ u3ÀÃÿt$hPÿ|÷ØYÀY÷ØÃ¡d	Vjÿ¼  jÿ‹ğÿt$¡d	VÿP  ¡d	VÿP  ƒÄ^Ã‹L$…Ét‹…À‰¡d	Qÿ€   YÃè   ÿt$…ÀtÿĞÃèm€ Ãƒ=4 u.¡Ü…ÀuhPÿä…À£Üth8Pÿä£4¡4Ãÿüã…ÀujWXj Pÿt$èeòÿÿƒÄÃ‹L$‹T$¡d	Vÿ4
°´  ÿØ   Pÿt$ÿƒÄ3À^Ã‹L$‹T$¡d	Vÿt$Ñ°´  RÿĞ   Pÿt$ÿƒÄ3À^Ã‹L$‹T$¡d	Vÿt$Ñ°´  Rÿè   Pÿt$ÿƒÄ3À^Ã‹D$ƒÉÿ;ÁtÑè‹È‹T$¡d	VQ‹L$°´  ÑRÿğ  Pÿt$ÿƒÄ3À^ÃU‹ì‹EH;Mv7¡d	Vj°°  èµïÿÿPÿuÿ¡d	j h\ÿuÿ¨  ƒÄjX^]Ã‹U‹M‰3À]ÃU‹ì‹E‹M;U~7¡d	Vj°°  è`ïÿÿPÿuÿ¡d	j h\ÿuÿ¨  ƒÄjX^]ÃQ‹MÿuÈQÿåƒÄ3À]ÃU‹ìVWÿuè®ˆ ƒ} Y‹ø|9}s‹}‹uD7;Ev5¡d	j°°  èéîÿÿPÿuÿ¡d	j h\ÿuÿ¨  ƒÄjXëS‹]Wÿu3PÿåûƒÄ€$7 3À[_^]ÃU‹ìÿuÿåƒ} Y|9Es‹E‹MVTA;Uv5¡d	j°°  èjîÿÿPÿuÿ¡d	j h\ÿuÿ¨  ƒÄjXë ‹UW< W4
ÿuVÿåfƒ$7 ƒÄ3À_^]Ãÿt$ÿèã…Àt3ÀÃÿüãÃÿt$ÿäã…ÀtÿüãÃ3ÀÃ‹D$Ã‹D$ÃU‹ìQSVEüWP¡d	ÿuÿ¬   3ÛY9]üYu‹E‰ë~ÿu¡d	ÿX  PèŠ   ‹uY;ÃY‰u_ÿüã‰EEüP¡d	ÿuÿŒ   ƒ}üYY‹ør>Wÿà…Àt3Wÿà;Eüu'VÿuüSÿuèŞÿÿƒÄ…Àu'ÿuüWÿ6ÿåƒÄ3Àë9]tSÿuÿuèõîÿÿƒÄjX_^[ÉÃU‹ìVEWPÿu3ÿÿà…Àu!Eë-ÿuÿà‹ğVÿ$å‹øY…ÿuj^ëÿuWVÿà…Àu.ÿüã‹ğƒ} t	ÿuÿ ä…ÿtWÿåYVÿä3Àëÿuÿ ä‹Ç_^]ÃSV‹t$3Û;ót"9U‹-åvW~ÿ7ÿÕCƒÇ;Yró_VÿÕY]^[ÃU‹ìƒì(SVW3À}Ø‹5há«««Eè3ÿPEğPEìWPWÇEô   ÿu‰}ğ‰}ìÿuÿÖ…Àu:ÿüã‹Ø;ßt.ƒûzt)¡d	Wh|ÿuÿ¨  WSÿuèÃíÿÿƒÄjXél  ‹]EüP‹EğÀPWSèŠÜÿÿƒÄ…À…,  EøPÿuìWSèqÜÿÿƒÄ…À…  EèPEğPEìÿuüPÿuøÿuÿuÿÖ…Àu+¡d	Wh|Sÿ¨  ƒÄWÿüãPSè?íÿÿƒÄéÊ   ƒ}èuhÿu‹5åÿÖÿu‹Ğ‰UäÿÖ‹MätEP6PWSèìÛÿÿƒÄ…À…   ÿuÿuhpVÿuÿøäÿuÿuSè¨şÿÿÿu‰EôÿåƒÄ$ë\EØPÿuøSè…ãÿÿƒÄ;Ç‰EôuE¡d	jÿÿuüÿğ  ÿuè‰EÜ¡d	ÿØ   ‰Eà¡d	MØQj°´  ÿÜ   PSÿƒÄ‰}ô9}üt
ÿuüÿåY9}øt
ÿuøÿåY‹Eô_^[ÉÃU‹ìQVW‹}EP‹7v…   Pj j è
ÛÿÿƒÄ…Àt3Àëh‹E‰0‹M3À9E•À‰A‹ÆN…Àt$vNÁàT8‹uI|0‹ò¥¥ƒèƒê…É¥wéEüPÿuÿuÿlá‹ğ…öt‹E‹Mü‰ÿuÿåY‹Æ_^ÉÃU‹ìQQSVW‹}3Ûƒÿ‰]üÇEø   tƒÿtWÿuè³  Y‹ğYëCjMXQ‰EPEPWÿuÿ à…Àt$¡d	ÿu°´  ÿØ   PÿuÿƒÄ3Àéû  3ö;óu2¡d	Shÿuÿ¨  ƒÄSÿüãPÿuèëÿÿƒÄjXéÃ  Gÿ‹}ƒø‡m  ÿ$…ÑL VWè  Y;ÃY‰Eü„  éê   ¡d	SSÿÜ   Y‰Eü‰]9Yv1‹EDÆPWèã  Y;ÃYtP¡d	ÿuüWÿ¸   ƒÄÿE‹E;rÏ‹E;…&  é   VWèó  ë‹EüPÿ6Wè/áÿÿƒÄ‰Eøéè  ¡d	SSÿÜ   ‰Eü¡d	jVÿè   P¡d	ÿuüWÿ¸   FPè   ƒÄ ;ÃtP¡d	ÿuüWÿ¸   ƒÄëShàWéd  ÿ6¡d	ÿØ   Y‰Eü‰]øéu  ¡d	SSÿÜ   V‰EüèÉ  ƒÄ;Ã„h  P¡d	ÿuüWÿ¸   FPè¥  ƒÄ;Ã„D  P¡d	ÿuüWÿ¸   ÿv¡d	ÿv˜¸   ÿ¨  PÿuüWÿ¡d	ÿv˜¸   ÿØ   PÿuüWÿ¡d	ÿv˜¸   ÿØ   PÿuüWÿ¡d	ƒÄ@ÿv ˜¸   ÿØ   PÿuüWÿ¡d	ÿv$˜¸   ÿØ   PÿuüWÿ¡d	ÿv(˜¸   ÿØ   PÿuüWÿ¡d	ÿv,˜¸   ÿØ   PÿuüWÿƒÄ@F0Pè»   …ÀYt^P¡d	ÿuüWÿ¸   ƒÄƒeø ë3Sh¼ÿu¡d	ÿ¨  ƒÄë.¡d	ShœWÿ¨  ƒÄ9]øuÿuü¡d	Wÿ´  Yë3Û9]üt	ÿuüè^õÿÿYVÿå‹EøY_^[ÉÃJ 8J ’J ›J ›J lL ²J K K *K 8J …L lL lL U‹ìƒì‹Eÿ0ÿpEìh4jPÿ(å€eı EìjÿP¡d	ÿè   ƒÄÉÃU‹ìQQV‹uEøPÿ6ÿuè}ŞÿÿƒÄ…Àt3Àë%ÿv¡d	ÿà   ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃ‹D$ÿ0ƒÀPÿt$è   ƒÄÃU‹ì¡d	SVW3ÿWWÿÜ   9}YY‹Ø~.‹uVÿuè4   Y…ÀYt#P¡d	Sÿuÿ¸   ƒÄGƒÆ;}|Õ‹Ã_^[]ÃSè"ôÿÿY3ÀëğU‹ìQQV‹uVèùşÿÿj ‰Eøÿv¡d	ÿ¨  ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃU‹ìQSVWEü3ÿ‹5 àPWW‰}üÿuÿuÿÖ…Àu<ÿüã‹Øƒûzu3…ÿtWÿåYj[ÿuüÿ$å‹øY…ÿt EüPÿuüWÿuÿuë¾‹Çë…ÿtWÿåYSÿä3À_^[ÉÃU‹ì‹E…Àu]Ã‰EEjPjÿuÿdá]ÃU‹ì‹E…Àu]Ã‰EEjPjÿuÿdá]ÃD$Pÿt$ÿt$ÿt$ÿ`áÃU‹ìEPEPÿuÿuÿuÿ\á]ÃU‹ì¸    è`} VEWP… àÿÿ‹5XáPh    ÿuÿuÿuÿÖ…Àu
PÿüãPë'ÿüã¿  ;Çu*j j … àÿÿj PÿuÿuÿÖj WÿuèmåÿÿƒÄjX_^ÉÃ… àÿÿPÿuèÓıÿÿY…ÀYtäP¡d	ÿuÿ´  Y3ÀYëÒU‹ìV3ö9ut%}ê   uÿuèVx VÿuÿuèåÿÿƒÄjXëg¡d	SWVVÿÜ   ‹Ø‹EY;ÆY~/‹}‰E¡d	jÿÿ7°¸   ÿğ  PSÿuÿ}ƒÄÿMuÙë‹}¡d	Sÿuÿ´  YYWèßw _3À[^]ÃU‹ìQEüj PEPEjÿPÿuj ÿuè½w jÿuÿuPÿuè4ÿÿÿƒÄÉÃU‹ìQQEøj PEPEüjÿPj ÿuèw jÿuÿuüPÿuèÿşÿÿƒÄÉÃU‹ìQQEøj PEPEüjÿPj ÿuè_w jÿuÿuüPÿuèÊşÿÿƒÄÉÃU‹ìQEüPEPEjÿPj ÿuÿuè0w jÿuÿuPÿuè•şÿÿƒÄÉÃU‹ìEPEPEjÿPÿuj ÿuÿuèÿv jÿuÿuPÿuè^şÿÿƒÄ]ÃU‹ìQEüj PEPEjÿPjÿuÿuèÎv jÿuÿuPÿuè'şÿÿƒÄÉÃU‹ìQEüj PEPEjÿPj ÿuÿuèv jÿuÿuPÿuèğıÿÿƒÄÉÃU‹ìƒì ‹EV‰Eà‹E‰Eä‹E‰Eì‹E‰Eğ‹E ‰Eô‹E$‰Eø‹E(‰EüEWPEà3öPjÿu‰uèèDv ‹ø;şu3Àé‘   ¡d	Vh¬ÿuÿ¨  ‹EƒÄ+Æt=Ht3HHt(HtHtHt
HuP¸ ë(¸˜ë!¸ë¸€ë¸pë¸dë¸X;ÆtVhLP¡d	h@ÿuÿ   ƒÄVWÿuèCâÿÿƒÄjX_^ÉÃU‹ìƒ}VW‡¡   ‹Eƒè t*HtHtj hDé   ¸ˆÈ¿ü\ ë¸‚È¿+[ ë
¸|È¿£S MQÿuÿuÿuÿĞ‹ğ…öt%¡d	j hÿuÿ¨  j Vÿuè¹áÿÿƒÄëCÿu¡d	ÿu°´  ÿuÿ×PÿuÿƒÄÿuèÆt 3Àëj hÈÿu¡d	ÿ¨  ƒÄjX_^]Ã¡d	SUVW3ÿWWÿÜ   ‹\$‹ğ‹D$$Y+Ç‹|$Y„  H„4  H„G  H…A  ¡d	jh¨¸   ÿè   PVSÿU ¡d	ÿw`¨¸   ÿà   PVSÿU ¡d	jhx¨¸   ÿè   PVSÿU ¡d	ÿwd¨¸   ÿà   PVSÿU ¡d	ƒÄHjhh¨¸   ÿè   PVSÿU ‹GhƒÄ…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhP¨¸   ÿè   PVSÿU ‹GlƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jh8¨¸   ÿè   PVSÿU ¡d	ÿwp¨¸   ÿà   PVSÿU ƒÄ8¡d	jh$¨¸   ÿè   PVSÿU ¡d	ÿw ¨¸   ÿà   PVSÿU ¡d	jh¨¸   ÿè   PVSÿU ‹G$ƒÄ8…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jh ¨¸   ÿè   PVSÿU ‹G(ƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhô¨¸   ÿè   PVSÿU ‹G,ƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhà¨¸   ÿè   PVSÿU ‹O0ƒÄ(…Éu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhÌ¨¸   ÿè   PVSÿU ¡d	ÿw4¨¸   ÿà   PVSÿU ¡d	jh¸¨¸   ÿè   ƒÄ@PVSÿU ¡d	ÿw8¨¸   ÿà   PVSÿU ¡d	jh¤¨¸   ÿè   PVSÿU ¡d	ÿw<¨¸   ÿà   PVSÿU ¡d	ƒÄ@jh¨¸   ÿè   PVSÿU ¡d	ÿw@¨¸   ÿà   PVSÿU ¡d	¨¸   jhxÿè   PVSÿU ¡d	ÿwD¨¸   ÿà   PVSÿU ¡d	ƒÄHjÿhd¨¸   ÿè   PVSÿU ¡d	jÿwH¨¸   ÿĞ   PVSÿU ¡d	jhP¨¸   ÿè   PVSÿU ¡d	ÿwL¨¸   ÿà   ƒÄ@PVSÿU ¡d	jh<¨¸   ÿè   PVSÿU ¡d	ÿwP¨¸   ÿà   PVSÿU ¡d	jh(¨¸   ÿè   PVSÿU ‹GTƒÄD…Àu¸ô‹d	jÿP©¸   ÿ‘ğ  PVSÿU ¡d	jh¨¸   ÿè   PVSÿU ¡d	ÿwX¨¸   ÿà   PVSÿU ¡d	jh¨¸   ÿè   ƒÄ@PVSÿU ¡d	ÿw\¨¸   ÿà   PVSÿU ƒÄ¡d	jhô¨¸   ÿè   PVSÿU ‹OƒÄ…Éu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhà¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	j
hÔ¨¸   ÿè   ƒÄ@PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhÄ¨¸   ÿè   PVSÿU ‹GƒÄ0…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jh´¨¸   ÿè   PVSÿU ‹GƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jh¨¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jh”¨¸   ÿè   ƒÄ@PVSÿU ‹GƒÄ…Àu¸ô‹d	jÿP©¸   ÿ‘ğ  PVSÿU ƒÄ¡d	j
hˆ¨¸   ÿè   PVSÿU ‹?ƒÄ…ÿu¿ô¡d	jÿW¨¸   ÿğ  PVSÿU ƒÄ‹Æ_^][ÃU‹ì¡d	SVWj j ÿÜ   ‹u‹]‹ø‹EY…ÀY„Q  ƒø„ò   †‘  ƒø‡ˆ  ¡d	jhÜˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	ƒÄ$ƒ}ˆ¸   jÿ‰Mu7hÌÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰MÿØ   P‹EWSÿƒÄ$ëQh¼ÿè   P‹EWSÿEPÿvSè·ÏÿÿƒÄ …Àt¡d	jÿhœÿè   Y‰EYÿu¡d	WSÿ¸   ƒÄ¡d	jh¬ˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿƒÄ¡d	j
h ˆ¸   ‰Mÿè   P‹EWSÿ‹6ƒÄ…ö‹Îu¹ô¡d	jÿQ°¸   ÿğ  PWSÿƒÄ‹Ç_^[]ÃU‹ì¡d	Sj j ÿÜ   ‹Ø‹EYHY…   ¡d	VWjh °¸   ÿè   PSÿuÿ‹}ƒÄ‹…À‹Èu¹ô¡d	jÿQ°¸   ÿğ  PSÿuÿ¡d	jhğ°¸   ÿè   PSÿuÿ‹ƒÄ(…ÿu¿ô¡d	jÿW°¸   ÿğ  PSÿuÿƒÄ_^‹Ã[]Ãj ÿt$ÿt$ÿt$ÿt$èşôÿÿƒÄÃU‹ì‹Ej ‰EEPj ÿuÿuè˜j ]ÃU‹ì‹Ej ‰EEPhë  ÿuÿuèwj ]ÃU‹ì‹Ej ‰EEPhí  ÿuÿuèVj ]ÃU‹ì‹Ej ‰EEPhî  ÿuÿuè5j ]ÃU‹ì‹Ej ‰EEPhï  ÿuÿuèj ]ÃU‹ì‹Ej ‰EEPhğ  ÿuÿuèói ]ÃU‹ì‹Ej ‰EEPhñ  ÿuÿuèÒi ]ÃU‹ì‹Ej ‰EEPhò  ÿuÿuè±i ]ÃU‹ì‹Ej ‰EEPhó  ÿuÿuèi ]ÃU‹ì‹Ej ‰EEPhù  ÿuÿuèoi ]ÃU‹ì‹Ej ‰EEPh   ÿuÿuèNi ]ÃU‹ì‹Ej ‰EEPh  ÿuÿuè-i ]ÃU‹ì‹Ej ‰EEPh  ÿuÿuèi ]Ãjÿt$ÿt$ÿt$ÿt$è9óÿÿƒÄÃU‹ìƒ}t¡d	j hÈÿuÿ¨  ƒÄjX]ÃjjÿuÿuÿuèıòÿÿƒÄ]ÃU‹ìQQ‹Ej ‰Eø‹E‰EüEøPjÿuè—h ÉÃU‹ìQQ‹Ej ‰Eø‹E‰EüEøPjÿuèzh ÉÃU‹ì‹Ej‰EEPjÿuÿuèbh ]ÃU‹ì‹Ej‰EEPjÿuÿuèJh ]ÃU‹ìƒìEèjPÿTá…ÀuPÿüãPÿuè‰ÔÿÿƒÄëEüPEèPÿuè#   ƒÄ…ÀtjXÉÃÿuü¡d	ÿuÿ´  Y3ÀYÉÃU‹ìƒì,SVW3ÿ9}‰}Ô‰}Ø‰}Ü‰}à‰}äu¡d	WWÿÜ   YY‹M‰3À_^[ÉÃEøPEşPÿuÿ@á…À„9  ƒ}øt9}„  Wh(ÿués  ·EşP¡d	ÿØ   ‹];ÇY‰EÔ„I  EìPEôPÿuÿDá…À„ç   9}ô¾œu¡d	jÿVÿè   Y;ÇY‰EØ„  ëEØPÿuôSè>ÊÿÿƒÄ…À…
  EìPEôPÿuÿHá…À„   9}ôu¡d	jÿVÿè   Y;ÇY‰EÜ„¸   ëEÜPÿuôSèëÉÿÿƒÄ…À…·   EìPEğPEèPÿuÿLá…Àt<9}èu‰}ğÿuğSè®   Y;ÇY‰Eà„€   EìPEğPEèPÿuÿPá…Àuë‹];ßt^WÿüãPSè°ÒÿÿëK9}èu‰}ğÿuğSè^   Y;ÇY‰Eät4EÔP¡d	jÿÜ   Y;ÇY…Vşÿÿ;ßtWhS¡d	ÿ¨  ƒÄ‰}ø‹Eøÿt…ÔèbßÿÿÿEøƒ}øYrêjXé#şÿÿU‹ìƒìSVW3ÿ9}‰}ô‰}øu¡d	jÿhpÿè   YYé  ‹58ájEüjPÿuÿÖ…À„â   jEèjPÿuÿÖ…À„Í   ÿuü¡d	ÿØ   ‰Eô¡d	WWÿÜ   ‹]ƒÄ9}ô‰Eøt`;Çt\3ö9}èv>EPVÿuÿ<á…ÀtpÿuSèš   Y;ÇYtMP¡d	ÿuøSÿ¸   ƒÄ…Àu6F;uèrÂEôP¡d	jÿÜ   Y;ÇYu[;ßt¡d	WhPSÿ¨  ƒÄÿuôèDŞÿÿÿuøè<ŞÿÿYYë,;ßtèWÿüãPSèÑÿÿëÕ9}tWÿüãPÿuèşĞÿÿƒÄ3À_^[ÉÃU‹ìQSV‹u3Û;óW‰]üu%9]„S  ¡d	Shxÿuÿ¨  ƒÄé7  ¡d	SSÿÜ   ‹}Y;ÃY‰E„Ö   ¶P¡d	ÿØ   ;ÃY‰Eü„»   P¡d	ÿuWÿ¸   ƒÄ…À…Ò   ¶FP¡d	ÿØ   ;ÃY‰Eü„„   P¡d	ÿuWÿ¸   ƒÄ…À…›   €>wJÿv¡d	ÿØ   ;ÃY‰EütNP¡d	ÿuWÿ¸   ƒÄ…ÀuiEüƒÆPVW‰]üè¸ÆÿÿƒÄ…ÀuQÿuüë6·FP¡d	VÿĞ   Y;ÃY‰Eüu;ût.¡d	ShPWÿ¨  ƒÄëPÿu¡d	Wÿ¸   ƒÄ…Àtÿuüè Üÿÿÿuè˜ÜÿÿYY3Àë‹E_^[ÉÃU‹ìQQƒ} uÇE   EPEPEPEüPEøPÿuÿuÿuÿ4á…ÀtPÿä3ÀÉÃ‹EÉÃU‹ìQQƒ} uÇE   EPEPEPEüPEøPÿuÿuÿuÿ0á…ÀtPÿä3ÀÉÃ‹EÉÃD$Pÿt$ÿt$ène ¶ÀÃÿt$ÿ¤æ=   u	ƒ|$ t3ÀÃU‹ì‹Efƒ8 u3ÀMQÿuÿuPèÍ\ …ÀtPè½ÛÿÿYPÿäƒe ‹E]ÃU‹ìQSVWj^EPEPÿuÿuè¡\ ‹ø3Û;ûSt,¡d	hŒÿuÿ¨  ƒÄSWèiÛÿÿYPÿuè0ÎÿÿƒÄëf¡d	SÿÜ   Y3ÿ9]Y‰Eüv/¡d	°¸   ‹EøPèÛÃÿÿPÿuüÿuÿ‹ğƒÄ;óuG;}rÑÿuè\ ;óuÿuü¡d	ÿuÿ´  YY‹Æ_^[ÉÃU‹ìQQSVWj[EPEPÿuÿuèç[ ‹ø3ö;şVt,¡d	h´ÿuÿ¨  ƒÄVWè©ÚÿÿYPÿuèpÍÿÿƒÄëu¡d	VÿÜ   Y3ÿ9uY‰Eüv>EøP‹Eÿ4¸ÿuè
Äÿÿ‹ØƒÄ;Şu#ÿuø¡d	ÿuüÿuÿ¸   ‹ØƒÄ;ŞuG;}rÂÿuèH[ ;Şuÿuü¡d	ÿuÿ´  YY_‹Ã^[ÉÃU‹ìVÿuÿuÿuÿuè'[ ‹ğ…öt2¡d	j hğÿuÿ¨  ƒÄj VèãÙÿÿYPÿuèªÌÿÿƒÄjXë3À^]ÃU‹ìVÿuÿuÿuÿuÿuèØZ ‹ğ…öt2¡d	j hÿuÿ¨  ƒÄj VèÙÿÿYPÿuèUÌÿÿƒÄjXë3À^]ÃU‹ìQQEøVPEüPèÚb 3ö;ÆtVPèWÙÿÿYPÿuèÌÿÿƒÄë\¡d	SVVÿÜ   9uüYY‹Øv)W¡d	¸¸   ‹EøğPèæãÿÿPSÿuÿƒÄF;uürÙ_¡d	Sÿuÿ´  YYÿuøè_b 3À[^ÉÃU‹ìEPÿuèVb 3É;ÁtQPèÍØÿÿYPÿuè”ËÿÿƒÄ]Ã9Mu3À]Ã¡d	SVWQQÿÜ   ‹ğ¡d	jh¨˜¸   ÿè   ‹}PVWÿ¡d	˜¸   ‹EƒÀPè9ãÿÿPVWÿ¡d	jhœ˜¸   ÿè   PVWÿ¡d	ƒÄ@˜¸   ‹EƒÀPèàÀÿÿPVWÿ¡d	jh˜¸   ÿè   PVWÿ¡d	˜¸   ‹EƒÀPè§ÀÿÿPVWÿ¡d	jhx˜¸   ÿè   PVWÿ¡d	ƒÄH˜¸   ‹EƒÀPèkÀÿÿPVWÿ¡d	j	hl˜¸   ÿè   PVWÿ‹M¡d	ÿq$˜¸   ÿà   PVWÿ¡d	jhd˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq(˜¸   ÿà   PVWÿ‹Eÿp,èt  ‰E¡d	jh`˜¸   ÿè   PVWÿ‹EƒÄ(…ÀuP¡d	hœÿè   YYP¡d	VWÿ¸   ¡d	j	hT˜¸   ÿè   PVWÿ‹M¡d	ÿq4˜¸   ÿq0ÿ¨  PVWÿ‹EƒÄ4ƒ88v<¡d	jhH˜¸   ÿè   PVWÿ¡d	˜¸   ‹EƒÀ8Pè ¿ÿÿPVWÿƒÄ$‹Eƒ8@v<¡d	jh8˜¸   ÿè   PVWÿ¡d	˜¸   ‹EƒÀ@PèÜ¾ÿÿPVWÿƒÄ$‹Eƒ8Hv<¡d	jh4˜¸   ÿè   PVWÿ¡d	˜¸   ‹EƒÀHPè˜¾ÿÿPVWÿƒÄ$¡d	VWÿ´  YYÿuè9_ _^3À[]ÃU‹ìEPÿuj èK¿ÿÿƒÄ…Àu‹E]Ã¡d	j hœÿè   YY]ÃU‹ìƒìEWPÿuÿuè£V 3ÿ;ÇtWPèlÕÿÿYPÿuè3ÈÿÿƒÄéÜ   ƒ}V„   ƒ}t¡d	Wh°ÿuÿ¨  ƒÄj_é¡   ÿuèÒ½ÿÿ‰Eì‹EƒÀPèÃ½ÿÿ‰Eğ‹EƒÀPè´½ÿÿ‰Eô‹EƒÀPè6½ÿÿ‰Eø‹Eÿp(è%ÿÿÿ‰Eü¡d	MìQj°´  ÿÜ   PÿuÿƒÄ$ë9ÿuèj½ÿÿ‰Eì‹Eÿpèêşÿÿ‰Eğ¡d	MìQj°´  ÿÜ   PÿuÿƒÄÿuèU ‹Ç^_ÉÃD$Pÿt$ÿàãÃD$Pÿt$ÿt$ÿÜãÃU‹ì‹E¹ $  öÄt¹ &  ÿu%ÿ   Áÿuj j ÿuPÿuè   ƒÄ]ÃU‹ìjÿhĞêh Îd¡    Pd‰%    ƒìhSVW‰eèÇEä   €M3ÿ‰}üÿu ÿuEPÿuÿuÿuÿuÿìã…Àt0¡d	°´  jÿÿuÿğ  PÿuÿƒÄÿuÿ ä‰}äé   WÿüãPÿuè[ÆÿÿƒÄëx‹Eì‹ ‹ ‰EˆjXÃ‹eè}ˆ  Àt+ÿuˆhxE”PÿĞèjE”Pÿu¡d	ÿ¨  ƒÄë3j¡d	ÿ”  ÿu¡d	ÿ8  j hÿu¡d	ÿ¨  ƒÄƒMüÿ‹Eä‹Mğd‰    _^[ÉÃU‹ì‹E¹ (  öÄt¹ *  ÿu %ÿ   ÁÿuÿuÿuÿuPÿuè£şÿÿƒÄ]ÃU‹ìƒìLEÜVPÿØã·EÜP¡d	ÿØ   ÿuà‰E´¡d	ÿà   ÿuä‰E¸¡d	ÿà   ÿuè‰E¼¡d	ÿà   ÿuì‰EÀ¡d	ÿà   ÿuğ‰EÄ¡d	ÿà   ÿuô‰EÈ¡d	ÿà   ÿuø‰EÌ¡d	ÿà   ‰EĞ·EüP¡d	ÿØ   ‰EÔ·EşP¡d	ÿØ   ‰EØ¡d	M´Qj
°´  ÿÜ   PÿuÿƒÄ83À^ÉÃÿt$ÿÔãÃU‹ìƒìpEVPÇE@   ÿÌã…ÀtDÿuœ¡d	ÿu˜ÿ¨  ÿu¤‰Eğ¡d	ÿu ÿ¨  ÿu¬‰Eô¡d	ÿu¨ÿ¨  ÿu´‰Eøÿu°ëMEĞÇEĞ    PÿĞã¡d	3öVÿuØÿ¨  V‰EğÿuÜ¡d	ÿ¨  V‰Eôÿuà¡d	ÿ¨  V‰Eøÿuä¡d	ÿ¨  ‰Eü¡d	MğQj°´  ÿÜ   PÿuÿƒÄ03À^ÉÃU‹ìQVW‹=å¾@  EüPVj ÿuè„²ÿÿƒÄ…Àut9Et&9EtÿuVÿuüÿuÿÀãëVÿuüÿuÿÄãëÿuVÿuüÿÈãNş;Ár
ÿuüÿ×Yöë¡…Àtÿuü¡d	ÿu°´  èv»ÿÿPÿuÿƒÄÿuüÿ×Y3À_^ÉÃÿt$ÿt$ÿt$èPÿÿÿƒÄÃÿt$j ÿt$è=ÿÿÿƒÄÃU‹ìƒì8SVWè™  3ö‰Eğ;ÆuVjÿuëPEÈPÿØã‹EÜ‹]<@EüÁçPWVSèœ±ÿÿƒÄ…Àu/EìPWÿuüjÿUğ‹ø;şt$ÿuüÿåYVWèºÏÿÿYPSèƒÂÿÿƒÄjXé#  ¡d	VVÿÜ   9uÜYY‰Eğ‰uô†è  ‰uøë3ö¡d	VVÿÜ   ‹Mø‹ø‹Eüjhà4¡d	ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvÿ6ˆ¸   ‰Mÿ¨  P‹EWSÿ¡d	j
hÔˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄDÿvˆ¸   ÿv‰Mÿ¨  P‹EWSÿ¡d	jhÈˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvÿvˆ¸   ‰Mÿ¨  P‹EWSÿ¡d	jhÀˆ¸   ‰Mÿè   ƒÄDP‹EWSÿ¡d	ÿvÿvˆ¸   ‰Mÿ¨  P‹EWSÿ¡d	jh°ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿv$ÿv ˆ¸   ‰Mÿ¨  P‹EWSÿ¡d	ƒÄHˆ¸   jh ‰Mÿè   P‹EWSÿ¡d	ÿv(ˆ¸   ‰Mÿà   P‹EWSÿ¡d	WÿuğSÿ¸   ƒEø0ƒÄ0ÿEô‹Eô;EÜ‚şÿÿÿuğ¡d	Sÿ´  ÿuüÿåƒÄ3À_^[ÉÃƒ=Ô u.¡ …ÀuhPÿä…À£ thìPÿä£Ô¡ÔÃU‹ìƒìSVWèµÿÿÿ3ÿ‰Eø;ÇuWjÿuë`‹]¾   ‰}ü9}üt
ÿuüÿåYEüPVWSè´®ÿÿƒÄ…Àu;EôPVÿuüjÿUøö=  À‰EtÅ;Çt&ÿuüÿåYWÿuèÆÌÿÿYPSè¿ÿÿƒÄjXép  ¡d	WWÿÜ   ‹uüYY‰Eø¡d	WWÿÜ   ‹ø¡d	jh, ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	j	h  ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄ@ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh ˆ¸   ‰Mÿè   P‹EWSÿƒÄH¡d	¸   ‰EFPè:´ÿÿP‹EWSÿ¡d	WÿuøSÿ¸   ‹ƒÄ…Àt	ğ3ÿéÂşÿÿÿuø¡d	Sÿ´  ÿuüÿåƒÄ3À_^[ÉÃU‹ìƒì Vj ^EàVj PèàU ‹EƒÄ‰Eè‹E‰EìEàP‰uàÿuÿTé…ÀuPÿüãPÿuèÆ½ÿÿƒÄjXë&¡d	j ÿ5¤°´  ÿuüè   PÿuÿƒÄ3À^ÉÃU‹ìì   ÿu… şÿÿÿuÿuPè   … şÿÿjÿP¡d	ÿè   ƒÄÉÃU‹ìƒ} t#‹EMjQÆ _@Pè!   ‹Mÿ1PèPV ƒÄ]Ãh”ÿuè>V YY]Ã‹D$V‹t$W‹|$…ÿ~!¶‹ÑƒáÁêŠ’èGˆŠ‰èG@ˆ@FOuß_^Ãè   …Àujÿä2ÀÃ¶L$QÿĞÃƒ= u.¡ğ…ÀuhX ÿä…À£ğth8 Pÿä£¡Ãè   …Àujÿä2ÀÃÿt$ÿĞÃƒ=¸ u.¡Ğ…ÀuhX ÿä…À£Ğthh Pÿä£¸¡¸Ãè   …Àujÿä2ÀÃÿt$ÿĞÃƒ=Œ u.¡œ…ÀuhX ÿä…À£œthˆ Pÿä£Œ¡ŒÃƒì SUVWè…ûÿÿ3í‰D$ ;Åu	Ujÿt$<ëg‹t$4¿PÃ  ‰l$9l$tÿt$ÿåYD$PWUVè}ªÿÿƒÄ…Àu=D$,PWÿt$jÿT$0‹Øÿû  Àt¿;İt%ÿt$ÿåYUSèÈÿÿYPVèV»ÿÿƒÄjXéÇ  ¡d	UUÿÜ   ‹|$YY‰D$ ‹D$8ƒøÿt	;GD…r  ¡d	ÿwD˜¸   ÿà   Pÿt$(VÿƒÄ9l$<„B  ¡d	UUÿÜ   ‹è¡d	j	h¬#˜¸   ÿè   PUVÿ¡d	ÿwD˜¸   ÿà   PUVÿƒÄ,öD$<„¨   ¡d	jh”#˜¸   ÿè   PUVÿ¡d	ÿwH˜¸   ÿà   PUVÿ¡d	j	hˆ#˜¸   ÿè   PUVÿ¡d	ÿwP˜¸   ÿà   PUVÿ¡d	ƒÄHjhx#˜¸   ÿè   PUVÿ¡d	ÿw@˜¸   ÿà   PUVÿƒÄ$öD$<t9¡d	jhl#˜¸   ÿè   PUVÿ¡d	˜¸   G8Pè¥¯ÿÿPUVÿƒÄ$öD$<„   ¡d	jh`#˜¸   ÿè   PUVÿ¡d	ÿwL˜¸   ÿà   PUVÿ¡d	jhT#˜¸   ÿè   PUVÿ¡d	ÿw˜¸   ÿà   PUVÿ¡d	ƒÄHj
hH#˜¸   ÿè   PUVÿÿw$¡d	ÿw ˜¸   ÿ¨  PUVÿ¡d	jhÈ˜¸   ÿè   PUVÿÿw,¡d	ÿw(˜¸   ÿ¨  ƒÄDPUVÿ¡d	j
hÔ˜¸   ÿè   PUVÿÿw4¡d	ÿw0˜¸   ÿ¨  PUVÿƒÄ4öD$<„g  ¡d	jh,#˜¸   ÿè   PUVÿ¡d	ÿwX˜¸   ÿà   PUVÿ¡d	jh#˜¸   ÿè   PUVÿ¡d	ÿw\˜¸   ÿà   PUVÿ¡d	ƒÄHjhø"˜¸   ÿè   PUVÿ¡d	ÿw`˜¸   ÿà   PUVÿ¡d	jhØ"˜¸   ÿè   PUVÿ¡d	ÿwd˜¸   ÿà   PUVÿ¡d	ƒÄHjh¼"˜¸   ÿè   PUVÿ¡d	˜¸   ÿwhÿà   PUVÿ¡d	j"h˜"˜¸   ÿè   PUVÿ¡d	ÿwl˜¸   ÿà   PUVÿ¡d	ƒÄHjhx"˜¸   ÿè   PUVÿ¡d	ÿwp˜¸   ÿà   PUVÿ¡d	j%hP"˜¸   ÿè   PUVÿ¡d	ÿwt˜¸   ÿà   PUVÿ¡d	ƒÄHj!h,"˜¸   ÿè   PUVÿ¡d	ÿwx˜¸   ÿà   PUVÿ¡d	jh"˜¸   ÿè   PUVÿ¡d	ÿw|˜¸   ÿà   PUVÿ¡d	ƒÄHjhğ!˜¸   ÿè   PUVÿ¡d	ÿ·€   ˜¸   ÿà   PUVÿƒÄ$öD$<„“  ƒ=¤	‚†  ¡d	jhĞ!˜¸   ÿè   PUVÿÿ·Œ   ¡d	ÿ·ˆ   ˜¸   ÿ¨  PUVÿ¡d	jh°!˜¸   ÿè   PUVÿÿ·”   ¡d	ÿ·   ˜¸   ÿ¨  ƒÄDPUVÿ¡d	jh!˜¸   ÿè   PUVÿÿ·œ   ¡d	ÿ·˜   ˜¸   ÿ¨  PUVÿ¡d	jhp!˜¸   ÿè   PUVÿ¡d	ƒÄHÿ·¤   ˜¸   ÿ·    ÿ¨  PUVÿ¡d	jhP!˜¸   ÿè   PUVÿÿ·¬   ¡d	ÿ·¨   ˜¸   ÿ¨  PUVÿ¡d	jh0!˜¸   ÿè   ƒÄDPUVÿÿ·´   ¡d	ÿ·°   ˜¸   ÿ¨  PUVÿƒÄ öD$< „«  ¡d	jh(!˜¸   ÿè   PUVÿ¡d	j j ÿÜ   ƒÄƒ=¤	‰D$Ÿ¸   sŸˆ   ƒd$ ƒ †@  ‹D$<%€   ‰D$$‹D$<ƒà@‰D$(¡d	j j ÿÜ   ÿs$‰D$¡d	ˆ¸   ‰L$@ÿà   P‹D$Dÿt$,Vÿ¡d	jh!ˆ¸   ‰L$Tÿè   P‹D$Xÿt$4Vÿ¡d	ÿs ˆ¸   ‰L$dÿà   P‹D$hÿt$DVÿ¡d	jhø ˆ¸   ‰L$xÿè   ƒÄDP‹D$8ÿt$Vÿ¡d	ÿs$ˆ¸   ‰L$Dÿà   P‹D$Hÿt$$VÿƒÄƒ|$$ „…  ¡d	jhx#ˆ¸   ‰L$<ÿè   P‹D$@ÿt$Vÿ¡d	ÿs,ˆ¸   ‰L$Lÿà   P‹D$Pÿt$,Vÿ¡d	jhì ˆ¸   ‰L$`ÿè   P‹D$dÿt$@Vÿ¡d	ÿs(ˆ¸   ‰L$pÿà   P‹D$tÿt$PVÿ¡d	ƒÄHˆ¸   jhÜ ‰L$<ÿè   P‹D$@ÿt$Vÿ¡d	ÿsˆ¸   ‰L$Lÿà   P‹D$Pÿt$,Vÿ¡d	jhÔ ˆ¸   ‰L$`ÿè   P‹D$dÿt$@Vÿ¡d	ÿs4ˆ¸   ‰L$pÿà   Pÿt$P‹D$xVÿ¡d	ƒÄHˆ¸   j
hÈ ‰L$<ÿè   P‹D$@ÿt$Vÿ¡d	ÿs8ˆ¸   ‰L$Lÿà   P‹D$Pÿt$,VÿƒÄ$ƒ|$( „  ¡d	jh¼ ˆ¸   ‰L$<ÿè   P‹D$@ÿt$Vÿ¡d	ÿsˆ¸   ‰L$Lÿà   P‹D$Pÿt$,Vÿ¡d	jh¨ ˆ¸   ‰L$`ÿè   P‹D$dÿt$@Vÿ¡d	ÿs0ˆ¸   ‰L$pÿà   P‹D$tÿt$PVÿ¡d	ƒÄHˆ¸   j
hH#‰L$<ÿè   P‹D$@ÿt$Vÿ¡d	ÿsÿsˆ¸   ‰L$Pÿ¨  P‹D$Tÿt$0Vÿ¡d	jhÈˆ¸   ‰L$dÿè   P‹D$hÿt$DVÿ¡d	ÿsÿsˆ¸   ‰L$xÿ¨  ƒÄDP‹D$8ÿt$Vÿ¡d	j
hÔˆ¸   ‰L$Hÿè   P‹D$Lÿt$(Vÿ¡d	ÿsÿ3ˆ¸   ‰L$\ÿ¨  P‹D$`ÿt$<VÿƒÄ4ÿt$¡d	ÿt$ Vÿ¸   ƒÄÿD$‹D$ƒÃ@;G‚Øûÿÿÿt$¡d	UVÿ¸   ƒÄ¡d	Uÿt$$Vÿ¸   ƒÄ3íƒ|$8ÿu‹;Åtøéoôÿÿÿt$ ¡d	Vÿ´  ÿt$ÿåƒÄ3À_^][ƒÄ ÃU‹ìì¨  S‹]V…XşÿÿW‰Eü¿  ÇEô   ‹E3ö+Æt'HtHu0EøPWÿuüèQB ëEøPWÿuüÿuè9B ëEøPWÿuüè$B ‹Ø;Şt5‹Eø;ÇrF…XşÿÿÇ  9EüWuÿ$åë
ÿuüÿàäY;ÆYti‰EüëˆVÿüãPÿuèĞ®ÿÿƒÄéØ   Áè‹ø¡d	VV‰uôÿÜ   Y;şY‹Ø¦   ‹uü‰}ƒ} u\¡d	ÿ6¸¸   ÿà   PSÿuÿƒÄëo¡d	°”  ÿåÿ0ÿ¡d	Yj ÿu°   ÿ8  YPhÀ#ÿuÿƒÄëOÿ6Eèh¸#Pÿüä¡d	MèjÿQ¸¸   ÿè   PSÿuÿƒÄ ƒÆÿM…`ÿÿÿ¡d	Sÿuÿ´  YY…Xşÿÿ_9Eü^[t
ÿuüÿåY‹EôÉÃj j ÿt$èJşÿÿƒÄÃÿt$jÿt$è7şÿÿƒÄÃj jÿt$è&şÿÿƒÄÃU‹ìVÿuÿuÿÌè…Àt7=  t!‹5üãÿÖ…Àt$j ÿÖPÿuèj­ÿÿƒÄjXë-¡d	j °´  ë¡d	j°´  ÿØ   PÿuÿƒÄ3À^]ÃU‹ìƒìSV‹uWjD3Û_WSVè E E‰>‹}PEôP¡d	ÿuWÿ¼   ƒÄ…À…™  ƒ}ôt¡d	Sh@$Wÿ¨  ƒÄéy  EøP‹Eÿp$¡d	Wÿ¤   ƒÄ…À…X  ‹Eø‰F,‹Eÿ0¡d	ÿ   Ç$,$P‰FÿÜäY…ÀYu‰^‹Eÿp¡d	ÿ   öEøY‰FtNEüP‹Eÿp¡d	Wÿ¤   ƒÄ…À…ì   ‹Eü‰FEüP‹Eÿp¡d	Wÿ¤   ƒÄ…À…Å   ‹Eü‰FöEøtJEüP‹Eÿp¡d	Wÿ¤   ƒÄ…À…˜   ‹Eü‰FEüP‹Eÿp¡d	Wÿ¤   ƒÄ…Àuu‹Eü‰FöEøtFEüP‹Eÿp¡d	Wÿ¤   ƒÄ…ÀuL‹Eü‰F EüP‹Eÿp¡d	Wÿ¤   ƒÄ…Àu)‹Eü‰F$öEøt+EüP‹Eÿp ¡d	Wÿ¤   ƒÄ…ÀtjXéŞ   ‹Eü‰F(j[„]øt)EüP‹Eÿp(¡d	Wÿ¤   ƒÄ…À…©   f‹Eüf‰F0öEù„›   EPEôP‹Eÿp,¡d	Wÿ¼   ƒÄ…Àuvƒ}ôtP¡d	hğ#Wÿ¨  ƒÄëYSF8ÿ5¤P‹Eÿ0Wè„¯ÿÿƒÄ…Àu<SF<ÿ5¤P‹EÿpWèf¯ÿÿƒÄ…Àu‹ESÿ5¤ƒÆ@VÿpWèH¯ÿÿƒÄ…Àt‹Ãë3À_^[ÉÃU‹ìƒì¡d	V‹uÿ6ÿà   ÿv‰Eè¡d	ÿà   ÿv‰Eì¡d	ÿà   ÿv‰Eğ¡d	ÿà   ÿv‰Eô¡d	ÿà   ÿv‰Eø¡d	ÿà   ‰EüEèP¡d	jÿÜ   ƒÄ ^ÉÃU‹ìƒìEèjPj ÿuÿuè2   ƒÄ…ÀtjXÉÃ¡d	V°´  EèPÿuè=ÿÿÿPÿuÿƒÄ3À^ÉÃU‹ìQè=   …ÀuPjë MüQÿuÿuÿuÿuÿĞ…À}j Pèœ¶ÿÿYPÿuèc©ÿÿƒÄjXÉÃ3ÀÉÃƒ=@ u.¡ì…ÀuhPÿä…À£ìth|$Pÿä£@¡@ÃU‹ìƒì ¡d	V‹uÿvÿà   ÿv‰Eø¡d	ÿà   ÿ6‰Eü¡d	ÿà   ÿv‰Eà¡d	ÿà   ‰EäEøP¡d	jÿÜ   ÿv‰Eè¡d	ÿà   ÿv‰Eì¡d	ÿà   ÿv‰Eğ¡d	ÿà   ‰EôEàP¡d	jÿÜ   ƒÄ,^ÉÃU‹ìƒìEäjPj ÿuÿuè2   ƒÄ…ÀtjXÉÃ¡d	V°´  EäPÿuèÿÿÿPÿuÿƒÄ3À^ÉÃU‹ìQè=   …ÀuPjë MüQÿuÿuÿuÿuÿĞ…À}j Pè#µÿÿYPÿuèê§ÿÿƒÄjXÉÃ3ÀÉÃƒ=ˆ u.¡D…ÀuhPÿä…À£Dth˜$Pÿä£ˆ¡ˆÃU‹ìQQSEWPÿuÿäæ‹Ø3ÿ;ß‰]øWuÿüãPÿuèr§ÿÿƒÄjXë`¡d	WÿÜ   9}YY‰Eü~,V¡d	jÿÿ3°¸   ÿğ  PÿuüÿuÿƒÄGƒÃ;}|Ö^ÿuü¡d	ÿuÿ´  YYÿuøÿäã3À_[ÉÃV‹t$Wÿt$Vÿt$ÿ¼ã‹ø…ÿu9D$~f!ÿüãƒøtƒÈÿë‹Ç_^ÃV‹t$Wÿt$Vÿt$ÿ¸ã‹ø…ÿu9D$~f!ÿüãƒøtƒÈÿë‹Ç_^ÃU‹ì¸ @  è> SVW½ Àÿÿ»    SWÿuÿ´ã‹ğ…övfƒ|wş ufƒ|wü „†   ë;ów:ÿüãƒøzuuÛû ô }a… Àÿÿ;øtWÿåYPÿ$å‹øY…ÿtHë›jzÿäj ÿüãPÿuèû¥ÿÿƒÄj^…ÿt… Àÿÿ;øtWÿåY‹Æ_^[ÉÃjz3öÿä…öt¾WÿuèÿÿY…ÀYtÃP¡d	ÿuÿ´  Y3öYë±U‹ìQVEüWPÿuè¯; ‹ø…ÿt5Wÿ$å‹ğY…öt'VWj ÿuè‰; …ÀuÿüãV‹øÿåYWÿä3Àë‹Æ_^ÉÃƒ|$ tÿt$ÿåYÃU‹ìQEüPEPh|%ÿuèD; …ÀuÉÃ¡d	SVWj j ÿÜ   ‹ğ¡d	jhp%˜¸   ÿè   ‹}PVWÿ‹M¡d	ÿ1˜¸   ÿà   PVWÿ¡d	jh`%˜¸   ÿè   PVWÿ‹M¡d	ƒÄ@ÿq˜¸   ÿà   PVWÿ¡d	jhP%˜¸   ÿè   PVWÿ‹M¡d	ÿq˜¸   ÿà   PVWÿ¡d	jh@%˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq˜¸   ÿà   PVWÿ¡d	jh,%˜¸   ÿè   PVWÿ‹M¡d	ÿq˜¸   ÿà   PVWÿ¡d	jh%˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq˜¸   ÿà   PVWÿ¡d	jh%˜¸   ÿè   PVWÿ‹M¡d	ÿq˜¸   ÿà   PVWÿ¡d	jhü$˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq˜¸   ÿà   PVWÿ¡d	jhğ$˜¸   ÿè   PVWÿ‹M¡d	ÿq ˜¸   ÿà   PVWÿ¡d	j
hä$˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq$˜¸   ÿà   PVWÿ¡d	jhÔ$˜¸   ÿè   PVWÿ‹M¡d	ÿq(˜¸   ÿà   PVWÿ¡d	jhÄ$˜¸   ÿè   PVWÿ‹M¡d	ƒÄHÿq,˜¸   ÿà   PVWÿ¡d	jh´$˜¸   ÿè   PVWÿ¡d	‹M˜¸   ÿq0ÿà   PVWÿ¡d	VWÿ´  ƒÄ<3À_^[ÉÃU‹ìì   ÿu… şÿÿÿuh€%h   PÿøäƒÄEPEP… şÿÿPÿuèà7 …Àt+ƒ} t%¡d	Vjÿÿu°´  ÿğ  PÿuÿƒÄ3À^ÉÃ3ÀÉÃU‹ìƒìEPEüPh¸%ÿuèŒ7 …ÀuÉÃ¡d	SVj j ÿÜ   ‹uü‹Ø‹EYYDü;ğwNW·FP·Ph¬%Eğj
Pÿ(å¡d	MğjQ¸¸   ÿè   PSÿuÿ‹E‹MüƒÆƒÄ(Dü;ğv´_¡d	Sÿuÿ´  Y3ÀY^[ÉÃWÿt$ÿ°ã‹ø…ÿuÿüã…ÀtWPÿt$è· ÿÿƒÄjX_Ã¡d	VW°´  ÿà   Pÿt$ÿƒÄ3À^_ÃU‹ìVEW‹}PEP¡d	ÿuWÿ¼   ƒÄƒøtƒ}t¡d	j hÔ%Wÿ¨  ƒÄjX_^]Ã‹u‹EVÿ0¡d	Wÿ¤   ƒÄ…ÀuİFP‹Eÿp¡d	Wÿ¤   ƒÄ…ÀuÀFP‹Eÿp¡d	Wÿ¤   ƒÄ…Àu£‹EƒÆVÿp¡d	Wÿ¤   ƒÄ…Àu†ë‡U‹ìƒì¡d	V‹uÿ6ÿØ   ÿv‰Eğ¡d	ÿØ   ÿv‰Eô¡d	ÿØ   ÿv‰Eø¡d	ÿØ   ‰EüEğP¡d	jÿÜ   ƒÄ^ÉÃU‹ìQQ¡d	V‹uÿ6ÿØ   ÿv‰Eø¡d	ÿØ   ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃU‹ìVEW‹}PEP¡d	ÿuWÿ¼   ƒÄƒøtƒ}t¡d	j h&Wÿ¨  ƒÄjX_^]Ã‹u‹EVÿ0¡d	Wÿ¤   ƒÄ…Àuİ‹EƒÆVÿp¡d	Wÿ¤   ƒÄ…ÀuÀëÁ¡d	SUV3ÛWSSÿÜ   ‹ğ¡d	jhø&¸¸   ÿè   PVSÿ‹|$0¡d	ÿ7¨¸   ÿà   PVSÿU ¡d	jhğ&¨¸   ÿè   PVSÿU ¡d	ƒÄ@ÿw¨¸   ÿà   PVSÿU ¡d	jhà&¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhĞ&¨¸   ÿè   PVSÿU ¡d	ƒÄHÿw¨¸   ÿà   PVSÿU ¡d	jhÄ&¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jh¸&¨¸   ÿè   PVSÿU ¶O¡d	ƒÄHQ¨¸   ÿà   PVSÿU ¡d	jh¬&¨¸   ÿè   PVSÿU ¶O¡d	Q¨¸   ÿà   PVSÿU ¡d	jh &¨¸   ÿè   PVSÿU ¶O¡d	ƒÄHQ¨¸   ÿà   PVSÿU ¡d	j	h”&¨¸   ÿè   PVSÿU ¶O¡d	Q¨¸   ÿà   PVSÿU ¡d	jh„&¨¸   ÿè   PVSÿU ¶O¡d	ƒÄHQ¨¸   ÿà   PVSÿU ¡d	jht&¨¸   ÿè   PVSÿU ¶O¡d	Q¨¸   ÿà   PVSÿU ¡d	j	hh&¨¸   ÿè   PVSÿU ¶O¡d	ƒÄHQ¨¸   ÿà   PVSÿU ¡d	jhT&¨¸   ÿè   PVSÿU ¶O¡d	Q¨¸   ÿà   PVSÿU ¡d	j
hH&¨¸   ÿè   PVSÿU ƒÇƒÄH;ûu¿ô¡d	jÿW¨¸   ÿğ  PVSÿU ƒÄ‹Æ_^][ÃVWÿt$è@+ ‹ø…ÿu!‹5üãÿÖ…ÀtWÿÖPÿt$è›ÿÿƒÄjXë¡d	W°´  ÿØ   Pÿt$ÿƒÄ3À_^ÃU‹ìƒìVEôÿuh¸#Pÿüä¡d	MôjÿQ°¸   ÿè   P‹Eÿpÿ0ÿƒÄ jX^ÉÂ U‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPhš ÿXè…ÀuPÿüãPVèhšÿÿÿuüèq§ÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃU‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPhš ÿuÿTè…Àu-ÿüã…Àt#ƒøtƒø~tj PVèï™ÿÿÿuüèø¦ÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃj ÿäÿt$ÿt$ÿt$ÿPè…ÀtjXÃÿüã÷ØÀ@Ãj ÿäÿt$ÿt$ÿt$ÿäè‹L$…À‰uÿüã…Àt3ÀÃjXÃU‹ìƒìPSV¡d	Wj^jÿ‰uèÿuÿè   ‹}MøQ‰EìP¡d	WÿÄ   ƒÄ…ÀuE3ÛP‹EøkÀPSWèû‡ÿÿƒÄ…Àt‹ÆéÕ  9]ø‰]ôø  Eğ3öP¡d	ÿuôÇEØl(ÇEÜd(‰uàÿuìWÿÀ   ƒÄ…À…s  9uğ„»  E°P¡d	VÿuğWÿÀ   ƒÄ…À…K  9u°„“  EäPjEØhP(P¡d	ÿu°Wÿ˜   ƒÄ…À…  ‹Eä+Æ„§   H…{  ÇEü   |5´¡d	WÿuüÿuğÿuÿÀ   ƒÄ…À…Ü  ‹?…ÿ„N  D5ÈP¡d	Wÿuÿ¤   ƒÄ…À…³  ÿEüƒÆƒş|¨‹M‰‹M‹UÈ‰T‹M‹UÌ‰T‹M‹UĞ‰T‹M‹UÔ‰T‹M‰D‹M‰Dé£   ÇEü   |5´¡d	WÿuüÿuğÿuÿÀ   ƒÄ…À…<  ‹?…ÿ„·   D5ÈP¡d	Wÿuÿ¤   ƒÄ…À…  ÿEüƒÆƒş|¨9EÈŒ˜   }Èş   ‹   9EÌ|~}Ìÿÿ  uÿuĞ‹EÃÿuÈPè©  ‹Ef‹MÌƒÄf‰LÿEô‹}‹EôƒÃ;EøŒşÿÿ‹Eô;EøtHj h(W¡d	ÿ¨  ƒÄéŒ   Vhü'ëäj hÔ'ëj h°'ÿuëĞPhl'ëóPh$'ëë…Àt<jÿuPÿLè…À‰Eøu)ÿüã‹ğ¡d	j h'Wÿ¨  j VWèx–ÿÿƒÄë¡d	ÿuø°´  ÿØ   PWÿƒÄƒeè ƒ}ì t	ÿuìèW£ÿÿYƒ} t
ÿuÿåY‹Eè_^[ÉÃU‹ìƒì SV¡d	Wj_jÿ‰}èÿuÿè   ‰EøP¡d	ÿø  ‹ğƒÄ‰uìÿ¬ã%ÿ   ƒøEP‹Æ†ƒ   kÀ83ÛPSÿuè´„ÿÿƒÄ…À…‚   ;ó‰]üñ  3öÿuü¡d	ÿuøÿü  ‹ø‹EjÆj Pè  ‹EƒÆjj f‰|ê‹EÆCPèû  ‹EƒÄ Cf‰|ƒÆÿEü‹Eü;Eì|©éR  iÀ  3ÛPSÿuè.„ÿÿƒÄ…Àt‹Çé·  ;ó‰]üh  3öÿuü¡d	ÿuøÿü  YYPÿHè3ÉŠÌ%ÿ   ‰Eğ‹Áƒà‰Môf…À‰Eàt‹Ej_Æj jPC÷èd  ƒÄëj_‹Eôƒàf…À‰Eät‹Ej ÆjPC÷è<  ƒÄ‹Eôƒàf…À‰Eôt‹Ej ÆjPC÷è  ƒÄ‹Ej ÿuğÆC÷Pè  ‹EjÿuğÆC÷Pèğ   ƒÄfƒ}ô t‹EjÆjPC÷èÔ   ƒÄfƒ}ä t‹EjÆjPC÷è¸   ƒÄfƒ}à t‹EjÆjPC÷èœ   ƒÄÿEü‹Eü;EìŒÛşÿÿ…Ût=jÿuSÿLè…Àu/ÿüãj h'ÿu‹ğ¡d	ÿ¨  j VÿuèÌ“ÿÿƒÄë"3À‹d	P±´  ÿ‘Ø   PÿuÿƒÄƒeè ƒ}ø t	ÿuøè¨ ÿÿYƒ} t
ÿuÿåY‹Eè_^[ÉÃ‹D$f‹L$‹T$f‰H3ÉÇ    f‰H‰P‰H‰HÃ¡d	Vjÿÿt$°¸   ÿğ  P‹D$ÿpÿ0ÿƒÄjX^Â U‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPh¶¡ ÿDè…ÀuPÿüãPVèè’ÿÿÿuüèñŸÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃU‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPh¶¡ ÿuÿ@è…ÀuPÿüãPVè~’ÿÿÿuüè‡ŸÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃU‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPhš ÿuÿüç…Àu(ÿüã…Àtƒøtj PVè
’ÿÿÿuüèŸÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃ¡d	SUVW3ÿWWÿÜ   ‹\$‹è¡d	USÿ´  ƒÄWÿPç‹ø…ÿt¡d	W°¸   ÿØ   PUSÿë×ÿüã‹ğ…öt¡d	Sÿl  j VSèt‘ÿÿƒÄjXë3À_^][ÃU‹ìƒìS3ÛöEVWt‰]ë*‹E‰Eè‹E ‰Eì‹E$‰Eğ‹E(‰Eô‹E,‰Eø‹E0‰EüEè‰ESSÿu‹5¨ãÿuÿuÿuÿÖ‹ø;ûu9]t.SÿüãPÿuèôÿÿƒÄëEPD?PSÿuèÃÿÿƒÄ…ÀtjXëZWÿuÿuÿuÿuÿuÿÖ;ÃuSÿüãPÿuè«ÿÿƒÄj[ë ‹d	HPÿu±´  ÿ‘ğ  PÿuÿƒÄÿuÿåY‹Ã_^[ÉÃU‹ìƒì S3ÛöEVWt‰]ë6‹E‰Eà‹E ‰Eä‹E$‰Eè‹E(‰Eì‹E,‰Eğ‹E0‰Eô‹E4‰Eø‹E8‰EüEà‰ESSÿu‹5¤ãÿuÿuÿuÿÖ‹ø;ûu9]t.SÿüãPÿuèõÿÿƒÄëEPD?PSÿuèÄ~ÿÿƒÄ…ÀtjXëZWÿuÿuÿuÿuÿuÿÖ;ÃuSÿüãPÿuè¬ÿÿƒÄj[ë ‹d	HPÿu±´  ÿ‘ğ  PÿuÿƒÄÿuÿåY‹Ã_^[ÉÃj ÿ5ìÿt$èÍÑÿÿƒÄÃj ÿ5´ÿt$è¸ÑÿÿƒÄÃjÿ5ìÿt$ÿt$ÿt$èø“ÿÿƒÄÃjÿ5´ÿt$ÿt$ÿt$èÛ“ÿÿƒÄÃU‹ìƒìEüVP¡d	ÿuj ÿ    ƒÄ…Àu‹Ef‹Müf‰3ÀéÀ   ‹u¡d	VÿuÿX  YPÿuè§   ƒÄ…ÀtÖEøPEğP¡d	ÿuj ÿ¼   ƒÄ…Àu{ƒ}ğ|uEüP‹Eøÿ0¡d	j ÿ    ƒÄ…Àu‹Eü‰Eôë'EôP‹Eøÿ0¡d	ÿX  YPj è9   ƒÄ…Àu,‹Eôf= tf= tf= uÿuf‰¡d	ÿl  Yé<ÿÿÿjX^ÉÃU‹ìƒìPSVW‹}…ÿt(3Û¾H‹Š:uWPè|% Y…ÀYtLƒÆCşäHrßƒ} t2…ÿu¿œ(Whp(E°jPPÿ(åE°jP¡d	ÿuÿ¨  ƒÄjX_^[ÉÃ‹E…Àtf‹İ Hf‰3ÀëåU‹ìƒì SV‹u3Û;óuEàPÿdæuàf‹öÄ töÄ@t‹Fÿ0èÅ  ëÿvëôf=@u‹N;ËtQè±ÿÿÿYéñ  ·À€ä¿WP¡d	ÿØ   Y‰Eøf‹‰]ü·Áƒø$–   t+ƒÀşƒø‡  ÿ$…Ìª Sÿ5ìÿvé³  Sÿ5´ëï‹F‰];Ã„q  ‹N;Ë„f  ‹}WQPÿRD…À…S  Sÿ5tÿvèÏÿÿS‰Eğÿ5@ÿuèşÎÿÿ‰EôEğP¡d	jÿÜ   ƒÄ é  ş¿ÿÿƒø‡  ÿ$…$« fƒùu¿Fë‹F¿ Pé¤  fƒù…”  ‹vé‘  fƒùuÙFë‹FÙ ¡d	QQİ$ÿÔ   éŸ  fƒùé•   fƒùuƒÆë‹vVèFÿÿéŒ  ¡d	fƒù¸ğ  uÿvÿ0æPÿvÿéX  ‹Fÿ0ÿ0æP‹Fÿ0ëæ‹F‹ P‹ÿQSÿ5ìëjfƒù
éVÿÿÿfƒùu¿Fë‹F¿ P¡d	ÿÌ   é  fƒùuİFéCÿÿÿ‹Fİ é9ÿÿÿfƒùt‹vVèõ~ÿÿéè   ‹F‹ P‹ÿQSÿ5´‹Fÿ0èœÍÿÿƒÄéÅ   fƒùu	¾FéÊşÿÿ‹F¾ é¿şÿÿfƒùu	¶Fé°şÿÿ‹F¶ é¥şÿÿfƒùu	·Fé–şÿÿ‹F· é‹şÿÿfƒùë@fƒùu‹F‹vë‹N‹‹qVPë<fƒùëäfƒùéfşÿÿ‹F‹0V¡d	ÿØ   ë4fƒùu‹vë‹F‹0÷Æ   €tSV¡d	ÿ¨  Yë¡d	Vÿà   Y‰EüEøP3À9]ü•À@P¡d	ÿÜ   YY_^[ÉÃ«¨ Ã¨ Õ¨ ú¨ © ”© © ¨ h© q© ¬ª $¨ ¬© ¬ª ä© ş© ª 2ª 8ª Rª Xª tª «¨ Ã¨ Õ¨ ú¨ © ”© © T© h© q© ¬ª À© ¬© ¬ª ä© ş© ª 2ª 8ª Rª Xª tª U‹ìƒì$S‹]Vj^EşPS‰uìÿTæ…À…[  ·Eş€Ì P¡d	ÿØ   ‰EÜYEôPSÿlæ…ÀŒE  ¡d	W3ÿWWÿÜ   f9;YY‰Eà‰}øv]ƒÃ¡d	ÿsˆ¸   ‰Mğÿà   P‹EğÿuàWÿ¡d	ÿ3ˆ¸   ‰Mğÿà   P‹EğÿuàWÿ‹ƒÄ ¯ğ‹EÿEøƒÃ· 9Eø|¦¡d	WWÿÜ   ‰EäY·EşƒÀşYƒøÇEì   ‡‚  ÿ$…'± ;÷‰}øp  ‹Mô‹Uø¡d	¿QQ˜¸   ÿØ   PÿuäWÿƒÄÿEø9uø|Òé=  ;÷‰}ø2  ‹Mô‹Uø¡d	ÿ4‘˜¸   ÿà   PÿuäWÿƒÄÿEø9uø|Ôé  ;÷‰}øö  ‹Mô‹Uø¡d	QÙ‘Q˜¸   İ$ÿÔ   PÿuäWÿƒÄÿEø9uø|ÏéÀ  ;÷‰}øµ  ‹Mô‹Uø¡d	QİÑQ˜¸   İ$ÿÔ   PÿuäWÿƒÄÿEø9uø|Ïé  ;÷‰}øt  ¡d	‹Mø˜¸   ‹EôÈPèÈzÿÿPÿuäWÿƒÄÿEø9uø|ÔéC  ;÷‰}ø8  ‹Mô‹Uø¡d	QİÑQ˜¸   İ$ÿÔ   PÿuäWÿƒÄÿEø9uø|Ïé  ;÷‰}ø÷  ‹Eô‹Mø‹ˆ¡d	Q‰Mğ˜¸   ğ  ‰Eèÿ0æP‹EèÿuğÿPÿuäWÿƒÄÿEø9uø|¿é±  ;÷‰}ø¦  ‹Eô‹MøW‹ˆÿ5ì‹d	P™¸   èÉÿÿPÿuäWÿƒÄÿEø9uø|Ìém  ;÷‰}øb  ‹Mô‹Uø¡d	ÿ4‘˜¸   ÿØ   PÿuäWÿƒÄÿEø9uø|Ôé1  ;÷‰}ø&  ‹Mô‹Uø¡d	¿QQ˜¸   ÿÌ   PÿuäWÿƒÄÿEø9uø|Òéó  ;÷ë  3Û‰uğ‹Eô‹d	ÃP±¸   èbøÿÿPÿuäWÿƒÄƒÃÿMğu×é¸  ;÷°  3Û‰uğ¡d	°¸   ‹EôÃPèVyÿÿPÿuäWÿƒÄƒÃÿMğuØé~  ;÷‰}øs  ‹Eô‹MøW‹ˆÿ5´‹d	P™¸   èÚÇÿÿPÿuäWÿƒÄÿEø9uø|Ìé:  ;÷‰}ø/  ‹Mô‹Uø¡d	¾
Q˜¸   ÿØ   PÿuäWÿƒÄÿEø9uø|Òéü   ;÷‰}øñ   ‹Mô‹Uø¡d	¶
Q˜¸   ÿØ   PÿuäWÿƒÄÿEø9uø|Òé¾   ;÷‰}ø³   ‹Mô‹Uø¡d	·QQ˜¸   ÿØ   PÿuäWÿƒÄÿEø9uø|Òé€   3Û;÷~z‹Eô‹˜©   €tWP¡d	ÿ¨  YëP¡d	ÿà   YP¡d	ÿuäWÿ¸   ƒÄC;Ş|¾ë63Û;÷~0¡d	ˆ¸   ‰Mğ‹MôÿtÙÿ4Ùÿ¨  P‹EğÿuäWÿƒÄC;Ş|Ğÿuÿhæ_ë¡d	h    ÿØ   Y‰EÜEÜP¡d	ÿuìÿÜ   YY^[ÉÃt¬ ²¬ î¬ /­ p­ ¬­ í­ >® ‚® ¾® ü® q¯ 7¯ ï° µ¯ ó¯ 1° o° ¹° ¹° ²¬ o° U‹ìƒìlEPÿuÿuÿuÿuÿ8ê…À}j PÿuècƒÿÿƒÄjXÉÃVE”ÿuh¬(jPPÿ(åjEäj Pè  E”j ‰Eä¡d	°´  EäPÿuè…ÅÿÿPÿuÿƒÄ03À^ÉÃU‹ìƒìl‹EURÿu‹Pÿ…À|OVE”ÿuh¬(jPPÿ(åjEäj Pè¸ E”j ‰Eä¡d	°´  EäPÿuèÅÿÿPÿuÿƒÄ03À^ÉÃ=@ €u3ÀÉÃj Pÿuè‚ÿÿƒÄÉÃU‹ìQV‹uEüWP‹ÆÁà3ÿPWÿuèQqÿÿƒÄ…ÀtjXé¶   ‹ESÿuü‹]‹ÿuVShxëPÿQ;ÇW|v¡d	WÿÜ   Y;÷Y‰E~J¡d	jÿÿ4»°¸   ÿğ  Pÿuÿuÿ‹Mü¡d	ÿ4¹°¸   ÿØ   PÿuÿuÿƒÄ$G;}|¸3ÿÿu¡d	ÿuÿ´  Y3öYëPÿuè¾ÿÿƒÄj^9}ü[t
ÿuüÿåY‹Æ_^ÉÃU‹ìQ‹EUüRP‹ÿQ3É;ÁŒÏ  ¡d	SVWQQÿÜ   ‹ğ¡d	jhŒ)˜¸   ÿè   ‹}PVWÿ¡d	ÿuü˜¸   èjvÿÿPVWÿ¡d	jh„)˜¸   ÿè   PVWÿ‹Mü¡d	ƒÄ@ÿq˜¸   ÿà   PVWÿ¡d	j
hx)˜¸   ÿè   PVWÿ‹Mü¡d	ÿq˜¸   ÿà   PVWÿ¡d	jhd)˜¸   ÿè   PVWÿ‹Mü¡d	ƒÄHÿq˜¸   ÿà   PVWÿ¡d	jhT)˜¸   ÿè   PVWÿ‹Mü¡d	ÿq˜¸   ÿà   PVWÿ‹EüƒÄ4ƒx  ¡d	jhH)˜¸   t=ÿè   PVWÿ‹EüƒÄ‹@ …À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿƒÄë+ÿè   PVWÿ¡d	j hœ˜¸   ÿè   PVWÿƒÄ(¡d	jh8)˜¸   ÿè   PVWÿ‹Mü¡d	ÿq$˜¸   ÿà   PVWÿ¡d	jh,)˜¸   ÿè   PVWÿ‹Mü¡d	ÿq(˜¸   ÿà   PVWÿ¡d	ƒÄHjh$)˜¸   ÿè   PVWÿ‹Mü¡d	·I,Q˜¸   ÿà   PVWÿ¡d	jh)˜¸   ÿè   PVWÿ‹Mü¡d	·I.Q˜¸   ÿà   PVWÿ¡d	ƒÄHj
h)˜¸   ÿè   PVWÿ‹Mü¡d	·I0Q˜¸   ÿà   PVWÿ¡d	j	h)˜¸   ÿè   PVWÿ‹Mü¡d	·I2Q˜¸   ÿà   PVWÿ¡d	ƒÄHjhø(˜¸   ÿè   PVWÿ‹Mü¡d	·I4Q˜¸   ÿà   PVWÿ¡d	j
hì(˜¸   ÿè   PVWÿ‹Mü¡d	·I6Q˜¸   ÿà   PVWÿ¡d	ƒÄHjhÜ(˜¸   ÿè   PVWÿ‹Mü¡d	·I8Q˜¸   ÿà   PVWÿ¡d	jhÌ(˜¸   ÿè   PVWÿ‹Mü¡d	·I:Q˜¸   ÿà   PVWÿ¡d	ƒÄHj
hÀ(˜¸   ÿè   PVWÿ‹EüƒÄƒx(uÿuƒÀ<PWè˜   ƒÄ…Àu¡d	j j ÿÜ   YYP¡d	VWÿ¸   ¡d	jh´(˜¸   ÿè   PVWÿ‹Mü¡d	·IHQ˜¸   ÿØ   PVWÿ‹EƒÄ0ÿuü‹PÿQL¡d	VWÿ´  Y3ÀY_^[ÉÃQPÿuè®|ÿÿƒÄjXÉÃU‹ìƒìSV‹u3Û;óWu9]tj¡d	Sh”)ÿuÿ¨  ƒÄëQ·FƒøŒÔ   ƒø¬   ƒøtƒø…½   ÿ6¡d	ÿØ   Y‰Eøé£   ÿuÿ6ÿuè‰ÿÿÿƒÄ;Ã‰Eøu3Àé²   ¡d	SSÿÜ   Y‰EüY‹f9YvL¡d	ÿtÙ¸¸   ÿØ   Pÿuüÿuÿ‹¡d	ÿtÙ¸¸   ÿØ   Pÿuüÿuÿ‹ƒÄ C·A;Ø|´jë!ÿuÿ6ÿuèÿÿÿƒÄ;Ã‰Eø„tÿÿÿjëj·F_P¡d	ÿØ   ‰EôEôP¡d	WÿÜ   ƒÄ_^[ÉÃU‹ìV‹uMW‹QÿuVÿP…À}j PÿuèC{ÿÿƒÄjX_^]ÃVÿuÿuè'   ƒÄ‹ø‹ÿuVÿPT…ÿtÛ¡d	Wÿuÿ´  Y3ÀYëÉU‹ì¡d	SVWj j ÿÜ   ‹ø¡d	jh *°¸   ÿè   ‹]PWSÿ¡d	‹uÿ6ˆ¸   ‰Mÿà   P‹EWSÿ¡d	ƒÄ,ƒ~ ˆ¸   j‰MhH)tCÿè   P‹EWSÿ‹FƒÄ…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿƒÄë4ÿè   P‹EWSÿ¡d	j hœˆ¸   ‰Mÿè   P‹EWSÿƒÄ(‹F …ÀŒ   ƒø~Fƒøtƒøt<ë¡d	j
h*ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿv¸   ‰Eè:ìÿÿë:¡d	jh*ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿƒÄ$¡d	jhø)ˆ¸   ‰Mÿè   P‹EWSÿÿuFPSè¨üÿÿƒÄ …ÀuPP¡d	ÿÜ   YYP¡d	WSÿ¸   ¡d	jhà)ˆ¸   ‰Mÿè   P‹EWSÿÿuFPSè·   ƒÄ,…ÀuPP¡d	ÿÜ   YYP¡d	WSÿ¸   ¡d	jhØ)ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿv ˆ¸   ‰Mÿà   P‹EWSÿ¡d	j	hÌ)ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄDˆ¸   ‰M·NQÿà   P‹EWSÿƒÄ‹Ç_^[]ÃU‹ìQQV‹u·FP¡d	ÿØ   ƒeü ‰Eøf‹FY¨t¨ t‹6…ötƒÆVè|êÿÿY‰EüEøP3À9Eü•À@P¡d	ÿÜ   YY^ÉÃU‹ìV‹uMW‹QÿuVÿP…À}j PÿuèÁwÿÿƒÄjX_^]ÃVÿuÿuè'   ƒÄ‹ø‹ÿuVÿPP…ÿtÛ¡d	Wÿuÿ´  Y3ÀYëÉU‹ìƒì¡d	SVWj j ÿÜ   ‹Ø¡d	jh *°¸   ÿè   ‹}PSWÿ¡d	‹uÿ6ˆ¸   ‰Mÿà   P‹ESWÿ¡d	jh°*ˆ¸   ‰Mÿè   P‹ESWÿ¡d	ƒÄ@ÿvˆ¸   ‰Mÿà   P‹ESWÿ¡d	jh¨*ˆ¸   ‰Mÿè   P‹ESWÿ¡d	ÿvˆ¸   ‰Mÿà   P‹ESWÿ¡d	jhœ*ˆ¸   ‰Mÿè   PSW‹Eÿ¡d	ƒÄHÿvˆ¸   ‰Mÿà   P‹ESWÿ¡d	jh”*ˆ¸   ‰Mÿè   P‹ESWÿ¡d	ˆ¸   ‰M¿NQÿà   P‹ESWÿ¡d	j
hˆ*ˆ¸   ‰Mÿè   P‹ESWÿ¡d	ƒÄHˆ¸   ‰M¿NQÿà   P‹ESWÿ¡d	jh€*ˆ¸   ‰Mÿè   P‹ESWÿ¡d	ˆ¸   ‰M¿NQÿà   P‹ESWÿ¡d	ˆ¸   j
ht*‰Mÿè   P‹ESWÿ¡d	ƒÄHˆ¸   ‰M·N0Qÿà   P‹ESWÿ¡d	jh`*ˆ¸   ‰Mÿè   P‹ESWÿÿuF PWèqøÿÿƒÄ0…ÀuPP¡d	ÿÜ   YYP¡d	SWÿ¸   ¡d	jhH*ˆ¸   ‰Mÿè   P‹ESWÿÿuF(PWè€üÿÿƒÄ,…ÀuPP¡d	ÿÜ   YYP¡d	SWÿ¸   ¡d	j j ÿÜ   ‰Eø3ÀƒÄ9Ft=f9F‰E~4¡d	‹Uˆ¸   ‰M‹Nÿ4‘ÿØ   P‹ESWÿ¿FƒÄÿE9E|Ì¡d	j	h<*ˆ¸   ‰Mÿè   P‹ESWÿÿuø¡d	SWÿ¸   ¡d	j j ÿÜ   ‰Eø3ÀƒÄ(9F„§   f9F‰Eš   ‰Eü‹EüÿuFPWè-÷ÿÿƒÄ‰Eğ…ÀuPP¡d	ÿÜ   Y‰EğY‹F‹MüÿuDPWè`ûÿÿƒÄ‰Eô…ÀuPP¡d	ÿÜ   Y‰EôY¡d	ˆ¸   ‰MMğQjÿÜ   P‹EÿuøWÿ¿FƒEüƒÄÿE9EŒiÿÿÿ¡d	jh(*°¸   ÿè   PSWÿÿuø¡d	SWÿ¸   ƒÄ ‹Ã_^[ÉÃU‹ìQV‹uEüWP‹ÆÁà3ÿPWÿuèİaÿÿƒÄ…ÀtjXé®   ‹ESÿuü‹]‹VSPÿQ(;ÇW|v¡d	WÿÜ   Y;÷Y‰E~J¡d	jÿÿ4»°¸   ÿğ  Pÿuÿuÿ‹Mü¡d	ÿ4¹°¸   ÿØ   PÿuÿuÿƒÄ$G;}|¸3ÿÿu¡d	ÿuÿ´  Y3öYëPÿuèRrÿÿƒÄj^9}ü[t
ÿuüÿåY‹Æ_^ÉÃU‹ìì„   V3öh€   …|ÿÿÿVPèÿ	 ‹EƒÄUü‹R•|ÿÿÿj RÿuPÿQ;ÆV|}¡d	VÿÜ   9uüYY‰E‰u~MSWµ|ÿÿÿ¡d	ÿ6¸¸   ˜ğ  ÿ0æPÿ6ÿPÿuÿuÿƒÄÿ6ÿXæƒ& ÿE‹EƒÆ;Eü|½_[ÿu¡d	ÿuÿ´  Y3ÀYëPÿuèqqÿÿƒÄ^ÉÃU‹ìQ‹EUüRP‹ÿQ3É;ÁŒ›  ¡d	SVWQQÿÜ   ‹ğ¡d	jhŒ)˜¸   ÿè   ‹}PVWÿ¡d	ÿuü˜¸   è{fÿÿPVWÿ¡d	jh„)˜¸   ÿè   PVWÿ‹Mü¡d	ƒÄ@ÿq˜¸   ÿà   PVWÿ¡d	jhÈ*˜¸   ÿè   PVWÿ‹Mü¡d	ÿq˜¸   ÿà   PVWÿ¡d	jhÜ(˜¸   ÿè   PVWÿ‹Mü¡d	ƒÄH·IQ˜¸   ÿà   PVWÿ¡d	jhÌ(˜¸   ÿè   PVWÿ‹Mü¡d	·IQ˜¸   ÿà   PVWÿ¡d	j	h¼*˜¸   ÿè   PVWÿ‹Mü¡d	ƒÄH·IQ˜¸   ÿà   PVWÿ‹EƒÄÿuü‹PÿQ0¡d	VWÿ´  Y3ÀY_^[ÉÃQPÿuè«oÿÿƒÄÉÃU‹ìƒì8SVWj3ÿ^9}‰}ô‰uÜ‰}ğ‰}ì‰}ütvEìPEğP¡d	ÿuÿuÿ¼   ƒÄ…Àu'9uğ|QEàPEüP‹Eìÿ0¡d	ÿuÿ¼   ƒÄ…Àt‹ÆéŸ  9}üt?ƒ}ü9EP‹Eàÿ0ÿuèàÿÿƒÄ…Àu!j3ÿ^‹]9}ğf‰3u.ÇE   ƒ}üË  j h„+ÿu¡d	ÿ¨  ƒÄé  9uğı   EèPEäP‹Eìÿp¡d	ÿuÿ¼   ƒÄ…À…í  9Eä™   EØP‹Eèÿ0¡d	j ÿ    ƒÄ…Àu‹EØ…ÀujXf‰ëmEøP‹Eèÿ0¡d	ÿ¬   ƒ}ø YY‹øtJh€+WèĞ Y…ÀYt9¾|+VWè¾ Y…ÀYufÇ ë%VWèª Y…ÀYufÇ ëj h`+éÿÿÿfÇ ƒ}ä~.EôP‹Eèjÿp¡d	ÿuÿÀ   ƒÄ…À…   ‹Eô…Àtÿ fƒ}„Òşÿÿfƒ}ucƒ}ü…ÁşÿÿEĞPEÔP‹Eàÿp¡d	ÿuÿ¼   ƒÄ…À…Ô  ƒ}Ô…şÿÿEP‹EĞÿ0ÿuèbŞÿÿƒÄ…À…tşÿÿ€M@‹u‹}ë8fƒ}…Sşÿÿ3ö9ut\EP¡d	ÿuVÿ¤   ƒÄ…Àu!ÇE   ‹}‹÷f‹¨u8ƒf fÇ é  EÈP¡d	ÿuVÿ”   ƒÄÇE   …ÀtÅÇE   ë¼¨t!ƒ} t!¡d	j j ÿuÿuÿ  ƒÄ‰Eƒ} u%öt‹÷ÇE
   ë‹Eô…ÀuPh$+é«ıÿÿ‰E‹M·Á€ä¿ƒÀşƒø‡»  ÿ$…{Ë FP¡d	ÿuÿuÿ¤   ƒÄ…À…Ÿ  fÇ é  FP¡d	ÿuÿuÿ”   ƒÄ…À…u  fÇ éâ  FPÿuÿuè{_ÿÿƒÄ…À…Q  fÇ é¾  FP¡d	ÿuÿuÿ”   ƒÄ…À…'  fÇ é”  öÅ@„	  ¡d	~W3ÛÿuSÿ¤   ƒÄ…ÀufÇ ë¡d	WÿuSÿ”   ƒÄ…ÀufÇ ‹}éD  EøP¡d	ÿuÿĞ  YYÿuøPÿPæ;Ã‰uSh+éküÿÿfÇ ëÂEøP¡d	ÿuÿĞ  YYÿuøPÿPæ…À‰FuPëÇfÇ éÜ   jFÿ5ìPÿuÿuèÎoÿÿƒÄ…À…C  fÇ	 é°   fÇ
 ÇF €éŸ   ¡d	~Wÿuÿuÿˆ   ƒÄ…À…  ‹fÇ ÷ØÀf‰é ÿÿÿjFÿ5´Pÿuÿuè^oÿÿƒÄ…À…Ó   fÇ ëCVÿuÿuèf^ÿÿƒÄ…À…µ   fÇ ë%FP¡d	ÿuÿuÿ¤  ƒÄ…À…   fÇ ‹E‹È€å¿f;t)f=@t#f%ÿ¿Pj VVÿLæ…À}j Pÿuèjÿÿé.ûÿÿöE@tf}@ufÇ@‰wƒeÜ ë7f‹€Ì@f‰·ƒÀşƒøwÿ$…ÛË ƒÆë×j hĞ*éØúÿÿQÿuèà   YY‹Eô…Àtÿ‹Eôƒ8 P¡d	ÿ€   Y‹EÜ_^[ÉÃ–È –È ÀÈ ÀÈ êÈ É ¾É ğÉ Ê -Ê 8É `Ê ‰Ê JË –È –È –È –È §Ê §Ê –È –È Ê –È 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë >Ë 9Ë Ë >Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë 9Ë U‹ìƒìPƒ} t-·EPhÀ+E°jPPÿ(åE°jP¡d	ÿuÿ¨  ƒÄÉÃ‹D$…Àtfƒ8uPÿæÃU‹ìƒìSVEWPEPEP‹uÿu‹ÿuÿuj_WÿHæPÿuVÿS3ö;Æ}VPÿuèDhÿÿƒÄé-  ‹E+Æ„ş   H„¨   Ht\Ht¡d	j$h,ÿè   YYéé   ¡d	jhø+ÿè   V‰Eôÿ50ÿuèRªÿÿ‰EøEôP¡d	jÿÜ   ƒÄé§   ¡d	jhğ+ÿè   ÿu‰Eôÿuÿuè¢ìÿÿV‰Eøÿ5ÜÿuèªÿÿƒÄ ‰Eü‹Eÿu‹PÿQTëG¡d	jhä+ÿè   ÿu‰EôÿuÿuèÛïÿÿV‰Eøÿ5Üÿuè¸©ÿÿƒÄ ‰Eü‹Eÿu‹PÿQPEôPjëVV¡d	ÿÜ   YY3ÿP¡d	ÿuÿ´  Y‹ÇY_^[ÉÃU‹ìì  W3ÿh€   …|ÿÿÿWPèÓş ‹EƒÄ•|ÿÿÿÇEü    ‹RUüRPÿQ8;Ç}WPÿuèÀfÿÿƒÄëV9}üVv)ÿ´½|ÿÿÿ´½|ÿÿÿè¯VÿÿY‰„½üşÿÿÿ6ÿXæG;}ür×¡d	üşÿÿQÿuü°´  ÿÜ   PÿuÿƒÄ3À^_ÉÃÿt$hˆëj ÿt$ÿ<êÃU‹ìƒìVW3ÿ9}uG¡d	jÿÌ   ‰Eğ¡d	WWÿÜ   ‰Eô¡d	MğQj°´  ÿÜ   PÿuÿƒÄ3Àéİ   EüP‹EÁàPWÿuèÈTÿÿƒÄ…Àu)‹EUøRÿuü‹ÿuPÿQ;ÇtƒøtWPÿuèµeÿÿƒÄjXé‘   3É;Ç¡d	S”ÁQÿÌ   ‰Eğ¡d	WWÿÜ   ƒÄ3Û9}ø‰Eôv=¡d	°¸   ‹EüÇPèØ×ÿÿPÿuôÿuÿ‹EüƒÄÇfƒ8uPÿæCƒÇ;]ørÃ¡d	MğQj°´  ÿÜ   PÿuÿƒÄ3À[_^ÉÃU‹ìƒìPè5   ÿpÿpÿpE°h,,jPPÿ(åE°jP¡d	ÿuÿ¨  ƒÄ$3ÀÉÃƒ=H V¾ uVh8,è|TÿÿYÇH   Y‹Æ^Ãè"   …Àujÿä3ÀÃÿt$ÿt$ÿt$ÿt$ÿĞÃƒ=ä u.¡ì…Àuh8,ÿä…À£ìthD,Pÿä£ä¡äÃU‹ìè#   …Àujÿä3À]ÃÿuÿuÿuÿuÿuÿĞ]Ãƒ=4 u.¡à…Àuh8,ÿä…À£àth\,Pÿä£4¡4Ãƒ=L u3èU   …À£èuèîşÿÿƒxuƒx u
ès   £èÇL   ¡è…Àujÿä3ÀÃÿt$ÿt$ÿt$ÿt$ÿĞÃƒ=¤ u.¡Ä…Àuh8,ÿä…À£Äthp,Pÿä£¤¡¤Ãƒ=” u.¡ä…Àuh8,ÿä…À£äth²   Pÿä£”¡”ÃSVW‹|$Š„Àu3ÀéD<  8dI‹5 ãuWhdIÿÖ…À„	9   PI:uWhPIÿÖ…Àujéï8   @I:uWh@IÿÖ…ÀujéÓ8   ,I:uWh,IÿÖ…Àujé·8   I:uWhIÿÖ…Àujé›8   I:uWhIÿÖ…Àujé8   ôH:uWhôHÿÖ…Àuj
éc8   äH:uWhäHÿÖ…Àuj	éG8   ĞH:uWhĞHÿÖ…Àujé+8   ¸H:uWh¸HÿÖ…Àujé8   ¤H:uWh¤HÿÖ…Àujéó7   H:uWhHÿÖ…Àujé×7   xH:uWhxHÿÖ…À„¼7   lH:uWhlHÿÖ…Àt“ \H:uWh\HÿÖ…Àtš PH:uWhPHÿÖ…Àt¡ @H:uWh@HÿÖ…ÀtŒ 0H:uWh0HÿÖ…À„“şÿÿ  H:uWh HÿÖ…À„"ÿÿÿ H:uWhHÿÖ…À„%ÿÿÿ H:uWhHÿÖ…À„(ÿÿÿ  H:uWh HÿÖ…À„ë6   ğG:uWhğGÿÖ…À„Úşÿÿ ÜG:uWhÜGÿÖ…À„Åıÿÿ ÌG:uWhÌGÿÖ…À„Èıÿÿ ¸G:uWh¸GÿÖ…À„Ëıÿÿ ¤G:uWh¤GÿÖ…À„Îıÿÿ ŒG:uWhŒGÿÖ…À„Aşÿÿ xG:uWhxGÿÖ…À„Dşÿÿ dG:uWhdGÿÖ…À„Gşÿÿ LG:uWhLGÿÖ…À„
6   <G:uWh<GÿÖ…À„5ıÿÿ 0G:uWh0GÿÖ…À„üıÿÿ $G:uWh$GÿÖ…À„ãıÿÿ G:uWhGÿÖ…À„Êıÿÿ  G:uWh GÿÖ…À„yıÿÿ ôF:uWhôFÿÖ…À„|ıÿÿ èF:uWhèFÿÖ…À„ıÿÿ ØF:uWhØFÿÖ…À„B5   ÌF:uWhÌFÿÖ…À„1ıÿÿ ÀF:uWhÀFÿÖ…À„4ıÿÿ ´F:uWh´FÿÖ…À„Wüÿÿ ¤F:uWh¤FÿÖ…À„Êüÿÿ ˜F:uWh˜FÿÖ…À„	üÿÿ F:uWhFÿÖ…À„´üÿÿ „F:uWh„FÿÖ…À„·üÿÿ tF:uWhtFÿÖ…À„¢ûÿÿ dF:uWhdFÿÖ…À„a4   LF:uWhLFÿÖ…À„lüÿÿ <F:uWh<FÿÖ…À„7üÿÿ 0F:uWh0FÿÖ…À„üÿÿ $F:uWh$FÿÖ…À„!üÿÿ F:uWhFÿÖ…À„ä3   F:uWhFÿÖ…À„Ë3   øE:uWhøEÿÖ…À„ºûÿÿ ìE:uWhìEÿÖ…À„½ûÿÿ ÜE:uWhÜEÿÖ…À„€3   ÈE:uWhÈEÿÖ…À„«úÿÿ ´E:uWh´EÿÖ…À„:ûÿÿ œE:uWhœEÿÖ…À„]úÿÿ ŒE:uWhŒEÿÖ…À„ûÿÿ „E:uWh„EÿÖ…À„ûÿÿ xE:uWhxEÿÖ…À„ûÿÿ lE:uWhlEÿÖ…À„Ñ2   PE:uWhPEÿÖ…À„üùÿÿ 8E:uWh8EÿÖ…À„Çùÿÿ ,E:uWh,EÿÖ…À„úÿÿ E:uWhEÿÖ…À„‘úÿÿ E:uWhEÿÖ…À„T2   ôD:uWhôDÿÖ…À„›ùÿÿ èD:uWhèDÿÖ…À„*úÿÿ ØD:uWhØDÿÖ…À„-úÿÿ ÈD:uWhÈDÿÖ…À„ğ1   ´D:uWh´DÿÖ…À„ãøÿÿ ˜D:uWh˜DÿÖ…À„rùÿÿ |D:uWh|DÿÖ…À„=ùÿÿ pD:uWhpDÿÖ…À„”ùÿÿ `D:uWh`DÿÖ…À„—ùÿÿ PD:uWhPDÿÖ…À„Z1   8D:uWh8DÿÖ…À„ùÿÿ ,D:uWh,DÿÖ…À„0ùÿÿ D:uWhDÿÖ…À„3ùÿÿ D:uWhDÿÖ…À„ö0   ôC:uWhôCÿÖ…À„Yøÿÿ äC:uWhäCÿÖ…À„èøÿÿ ÜC:uWhÜCÿÖ…À„³øÿÿ ĞC:uWhĞCÿÖ…À„¶øÿÿ ÄC:uWhÄCÿÖ…À„y0   °C:uWh°CÿÖ…À„høÿÿ ¤C:uWh¤CÿÖ…À„Oøÿÿ ˜C:uWh˜CÿÖ…À„Røÿÿ ˆC:uWhˆCÿÖ…À„0   tC:uWhtCÿÖ…À„ü/   hC:uWhhCÿÖ…À„ë÷ÿÿ \C:uWh\CÿÖ…À„î÷ÿÿ LC:uWhLCÿÖ…À„±/   8C:uWh8CÿÖ…À„„÷ÿÿ (C:uWh(CÿÖ…À„‡÷ÿÿ C:uWhCÿÖ…À„Š÷ÿÿ C:uWhCÿÖ…À„‘öÿÿ øB:uWhøBÿÖ…À„4/   èB:uWhèBÿÖ…À„#÷ÿÿ ØB:uWhØBÿÖ…À„&÷ÿÿ ÈB:uWhÈBÿÖ…À„Õöÿÿ ÀB:uWhÀBÿÖ…À„Øöÿÿ ´B:uWh´BÿÖ…À„Ûöÿÿ ¤B:uWh¤BÿÖ…À„.   ŒB:uWhŒBÿÖ…À„Éõÿÿ tB:uWhtBÿÖ…À„Xöÿÿ `B:uWh`BÿÖ…À„?öÿÿ TB:uWhTBÿÖ…À„:.   HB:uWhHBÿÖ…À„Eöÿÿ <B»<B:uWSÿÖ…À„öÿÿ ,B:uWh,BÿÖ…À„î-   TB:uWhTBÿÖ…À„Õ-   HB:uWhHBÿÖ…À„àõÿÿ <B:uWSÿÖ…À„¯õÿÿ  B:uWh BÿÖ…À„Òôÿÿ TB:uWhTBÿÖ…À„u-   HB:uWhHBÿÖ…À„€õÿÿ <B:uWSÿÖ…À„Oõÿÿ B:uWhBÿÖ…À„6õÿÿ TB:uWhTBÿÖ…À„-   HB:uWhHBÿÖ…À„ õÿÿ <B:uWSÿÖ…À„ïôÿÿ B:uWhBÿÖ…À„òôÿÿ TB:uWhTBÿÖ…À„µ,   HB:uWhHBÿÖ…À„Àôÿÿ <B:uWSÿÖ…À„ôÿÿ ôA:uWhôAÿÖ…À„–óÿÿ TB:uWhTBÿÖ…À„U,   HB:uWhHBÿÖ…À„`ôÿÿ <B:uWSÿÖ…À„/ôÿÿ àA:uWhàAÿÖ…À„2ôÿÿ ÔA:uWhÔAÿÖ…À„9óÿÿ ÄA:uWhÄAÿÖ…À„Èóÿÿ ¼A:uWh¼AÿÖ…À„Ëóÿÿ ¬A:uWh¬AÿÖ…À„Òòÿÿ  A:uWh AÿÖ…À„µóÿÿ ”A:uWh”AÿÖ…À„x+   „A:uWh„AÿÖ…À„góÿÿ xA:uWhxAÿÖ…À„Nóÿÿ hA:uWhhAÿÖ…À„óÿÿ `A:uWh`AÿÖ…À„óÿÿ TA:uWhTAÿÖ…À„óÿÿ HA:uWhHAÿÖ…À„â*   8A:uWh8AÿÖ…À„µòÿÿ (A:uWh(AÿÖ…À„œòÿÿ A:uWhAÿÖ…À„Ÿòÿÿ A:uWhAÿÖ…À„¢òÿÿ ü@:uWhü@ÿÖ…À„e*   ô@:uWhô@ÿÖ…À„pòÿÿ ä@:uWhä@ÿÖ…À„òÿÿ Ü@:uWhÜ@ÿÖ…À„"òÿÿ Ğ@:uWhĞ@ÿÖ…À„%òÿÿ Ä@:uWhÄ@ÿÖ…À„è)   ¸@:uWh¸@ÿÖ…À„Ï)   ¨@:uWh¨@ÿÖ…À„¢ñÿÿ œ@:uWhœ@ÿÖ…À„¥ñÿÿ Œ@:uWhŒ@ÿÖ…À„¨ñÿÿ |@:uWh|@ÿÖ…À„k)   t@:uWht@ÿÖ…À„vñÿÿ h@:uWhh@ÿÖ…À„Añÿÿ \@:uWh\@ÿÖ…À„ )   L@:uWhL@ÿÖ…À„óğÿÿ D@:uWhD@ÿÖ…À„î(   8@:uWh8@ÿÖ…À„Áğÿÿ ,@:uWh,@ÿÖ…À„Äğÿÿ @:uWh@ÿÖ…À„Çğÿÿ @:uWh@ÿÖ…À„Š(   ü?:uWhü?ÿÖ…À„µïÿÿ ğ?:uWhğ?ÿÖ…À„|ğÿÿ à?:uWhà?ÿÖ…À„Gğÿÿ Ğ?:uWhĞ?ÿÖ…À„Jğÿÿ ¼?:uWh¼?ÿÖ…À„ïÿÿ °?:uWh°?ÿÖ…À„ïÿÿ  ?:uWh ?ÿÖ…À„ïÿÿ ?:uWh?ÿÖ…À„"ïÿÿ €?:uWh€?ÿÖ…À„•ïÿÿ t?:uWht?ÿÖ…À„˜ïÿÿ d?:uWhd?ÿÖ…À„›ïÿÿ T?:uWhT?ÿÖ…À„^'   @?:uWh@?ÿÖ…À„Áîÿÿ 4?:uWh4?ÿÖ…À„Äîÿÿ $?:uWh$?ÿÖ…À„Çîÿÿ ?:uWh?ÿÖ…À„Êîÿÿ  ?:uWh ?ÿÖ…Àujéà&   ğ>:uWhğ>ÿÖ…ÀujéÄ&   à>:uWhà>ÿÖ…Àujé¨&   Ì>:uWhÌ>ÿÖ…ÀujéŒ&   ¼>:uWh¼>ÿÖ…À„}íÿÿ ¬>:uWh¬>ÿÖ…À„îÿÿ ˜>:uWh˜>ÿÖ…À„+îÿÿ ˆ>:uWhˆ>ÿÖ…À„îÿÿ |>:uWh|>ÿÖ…À„îÿÿ l>:uWhl>ÿÖ…À„îÿÿ \>»\>:uWSÿÖ…À„Ú%   H>:uWhH>ÿÖ…À„éìÿÿ ˆ>:uWhˆ>ÿÖ…À„”íÿÿ |>:uWh|>ÿÖ…À„—íÿÿ l>:uWhl>ÿÖ…À„šíÿÿ \>:uWSÿÖ…À„a%   4>:uWh4>ÿÖ…À„Píÿÿ ˆ>:uWhˆ>ÿÖ…À„íÿÿ |>:uWh|>ÿÖ…À„íÿÿ l>:uWhl>ÿÖ…À„!íÿÿ \>:uWSÿÖ…À„è$    >:uWh >ÿÖ…À„Ï$   ˆ>:uWhˆ>ÿÖ…À„¢ìÿÿ |>:uWh|>ÿÖ…À„¥ìÿÿ l>:uWhl>ÿÖ…À„¨ìÿÿ \>:uWSÿÖ…À„o$   >:uWh>ÿÖ…À„šëÿÿ ˆ>:uWhˆ>ÿÖ…À„)ìÿÿ |>:uWh|>ÿÖ…À„,ìÿÿ l>:uWhl>ÿÖ…À„/ìÿÿ \>:uWSÿÖ…À„ö#   ø=:uWhø=ÿÖ…À„=ëÿÿ ˆ>:uWhˆ>ÿÖ…À„°ëÿÿ |>:uWh|>ÿÖ…À„³ëÿÿ l>:uWhl>ÿÖ…À„¶ëÿÿ \>:uWSÿÖ…À„}#   ì=:uWhì=ÿÖ…À„üêÿÿ Ü=:uWhÜ=ÿÖ…À„Sëÿÿ Ì=:uWhÌ=ÿÖ…À„Vëÿÿ À=:uWhÀ=ÿÖ…À„!ëÿÿ hA:uWhhAÿÖ…À„ìêÿÿ `A:uWh`AÿÖ…À„ïêÿÿ TA:uWhTAÿÖ…À„òêÿÿ HA:uWhHAÿÖ…À„µ"   °=:uWh°=ÿÖ…À„ˆêÿÿ (A:uWh(AÿÖ…À„oêÿÿ A:uWhAÿÖ…À„rêÿÿ A:uWhAÿÖ…À„uêÿÿ ü@:uWhü@ÿÖ…À„8"   ¨=:uWh¨=ÿÖ…À„Cêÿÿ ä@:uWhä@ÿÖ…À„òéÿÿ Ü@:uWhÜ@ÿÖ…À„õéÿÿ Ğ@:uWhĞ@ÿÖ…À„øéÿÿ Ä@:uWhÄ@ÿÖ…À„»!   œ=:uWhœ=ÿÖ…À„¢!   ¨@:uWh¨@ÿÖ…À„uéÿÿ œ@:uWhœ@ÿÖ…À„xéÿÿ Œ@:uWhŒ@ÿÖ…À„{éÿÿ |@:uWh|@ÿÖ…À„>!   =:uWh=ÿÖ…À„1èÿÿ |=:uWh|=ÿÖ…À„Àèÿÿ p=:uWhp=ÿÖ…À„ûèÿÿ d=:uWhd=ÿÖ…À„şèÿÿ T=:uWhT=ÿÖ…À„Á    @=:uWh@=ÿÖ…À„°èÿÿ (=:uWh(=ÿÖ…À„     =:uWh =ÿÖ…À„~èÿÿ =:uWh=ÿÖ…À„èÿÿ =:uWh=ÿÖ…À„D    ø<:uWhø<ÿÖ…À„Sçÿÿ à<:uWhà<ÿÖ…À„rçÿÿ Ô<:uWhÔ<ÿÖ…À„Éçÿÿ Ä<:uWhÄ<ÿÖ…À„Ìçÿÿ ¬<:uWh¬<ÿÖ…À„çÿÿ œ<:uWhœ<ÿÖ…À„Òçÿÿ Œ<:uWhŒ<ÿÖ…À„-çÿÿ €<:uWh€<ÿÖ…À„|   x<:uWhx<ÿÖ…À„‡çÿÿ h<:uWhh<ÿÖ…À„Rçÿÿ \<:uWh\<ÿÖ…À„Éæÿÿ P<:uWhP<ÿÖ…À„Ìæÿÿ @<:uWh@<ÿÖ…À„#çÿÿ 0<:uWh0<ÿÖ…À„Òæÿÿ $<:uWh$<ÿÖ…À„æÿÿ <:uWh<ÿÖ…À„¼æÿÿ <:uWh<ÿÖ…À„¿æÿÿ  <:uWh <ÿÖ…À„‚   è;:uWhè;ÿÖ…À„Uæÿÿ Ø;:uWhØ;ÿÖ…À„<æÿÿ È;:uWhÈ;ÿÖ…À„{åÿÿ ¼;:uWh¼;ÿÖ…À„&æÿÿ ¬;:uWh¬;ÿÖ…À„)æÿÿ œ;:uWhœ;ÿÖ…À„ì   „;:uWh„;ÿÖ…À„Ûåÿÿ t;:uWht;ÿÖ…À„¦åÿÿ d;:uWhd;ÿÖ…À„åäÿÿ X;:uWhX;ÿÖ…À„åÿÿ H;:uWhH;ÿÖ…À„“åÿÿ 8;:uWh8;ÿÖ…À„V    ;:uWh ;ÿÖ…À„=   ;:uWh;ÿÖ…À„åÿÿ  ;:uWh ;ÿÖ…À„Oäÿÿ ô::uWhô:ÿÖ…À„úäÿÿ ä::uWhä:ÿÖ…À„ıäÿÿ Ô::uWhÔ:ÿÖ…À„À   Ä::uWhÄ:ÿÖ…À„ëãÿÿ ´::uWh´:ÿÖ…À„zäÿÿ ¤::uWh¤:ÿÖ…À„¹ãÿÿ ˜::uWh˜:ÿÖ…À„däÿÿ Œ::uWhŒ:ÿÖ…À„gäÿÿ |::uWh|:ÿÖ…À„*   d::uWhd:ÿÖ…À„ãÿÿ T::uWhT:ÿÖ…À„äãÿÿ D::uWhD:ÿÖ…À„#ãÿÿ 8::uWh8:ÿÖ…À„Îãÿÿ (::uWh(:ÿÖ…À„Ñãÿÿ ::uWh:ÿÖ…À„”    ::uWh :ÿÖ…À„£âÿÿ ğ9:uWhğ9ÿÖ…À„Nãÿÿ à9:uWhà9ÿÖ…À„âÿÿ Ô9:uWhÔ9ÿÖ…À„8ãÿÿ Ä9:uWhÄ9ÿÖ…À„;ãÿÿ ´9:uWh´9ÿÖ…À„ş   ˜9:uWh˜9ÿÖ…À„Eâÿÿ ˆ9:uWhˆ9ÿÖ…À„¸âÿÿ x9:uWhx9ÿÖ…À„÷áÿÿ l9:uWhl9ÿÖ…À„¢âÿÿ \9:uWh\9ÿÖ…À„¥âÿÿ L9:uWhL9ÿÖ…À„h   <9:uWh<9ÿÖ…À„sâÿÿ ,9:uWh,9ÿÖ…À„>âÿÿ 9:uWh9ÿÖ…À„   ø8:uWhø8ÿÖ…À„(âÿÿ ä8:uWhä8ÿÖ…À„×áÿÿ Ğ8:uWhĞ8ÿÖ…À„Úáÿÿ ¼8:uWh¼8ÿÖ…À„¹   ¨8:uWh¨8ÿÖ…À„äàÿÿ ”8:uWh”8ÿÖ…À„¯àÿÿ €8:uWh€8ÿÖ…À„Îàÿÿ t8:uWht8ÿÖ…À„yáÿÿ h8:uWhh8ÿÖ…À„€àÿÿ \8:uWh\8ÿÖ…À„áÿÿ T8:uWhT8ÿÖ…À„áÿÿ D8:uWhD8ÿÖ…À„àÿÿ 88:uWh88ÿÖ…À„üàÿÿ ,8»,8:uWSÿÖ…À„¾   8:uWh8ÿÖ…À„­àÿÿ h8:uWhh8ÿÖ…À„Ğßÿÿ \8:uWh\8ÿÖ…À„_àÿÿ T8:uWhT8ÿÖ…À„bàÿÿ D8:uWhD8ÿÖ…À„ißÿÿ 88:uWh88ÿÖ…À„Làÿÿ ,8:uWSÿÖ…À„   8:uWh8ÿÖ…À„ú   h8:uWhh8ÿÖ…À„%ßÿÿ \8:uWh\8ÿÖ…À„´ßÿÿ T8:uWhT8ÿÖ…À„·ßÿÿ D8:uWhD8ÿÖ…À„¾Şÿÿ 88:uWh88ÿÖ…À„¡ßÿÿ ,8:uWSÿÖ…À„h   ğ7:uWhğ7ÿÖ…À„;ßÿÿ h8:uWhh8ÿÖ…À„zŞÿÿ \8:uWh\8ÿÖ…À„	ßÿÿ T8:uWhT8ÿÖ…À„ßÿÿ D8:uWhD8ÿÖ…À„Şÿÿ 88:uWh88ÿÖ…À„öŞÿÿ ,8:uWSÿÖ…À„½   à7:uWhà7ÿÖ…À„èİÿÿ h8:uWhh8ÿÖ…À„Ïİÿÿ \8:uWh\8ÿÖ…À„^Şÿÿ T8:uWhT8ÿÖ…À„aŞÿÿ D8:uWhD8ÿÖ…À„hİÿÿ 88:uWh88ÿÖ…À„KŞÿÿ ,8:uWSÿÖ…À„   Ì7:uWhÌ7ÿÖ…À„!İÿÿ h8:uWhh8ÿÖ…À„$İÿÿ \8:uWh\8ÿÖ…À„³İÿÿ T8:uWhT8ÿÖ…À„¶İÿÿ D8:uWhD8ÿÖ…À„½Üÿÿ 88:uWh88ÿÖ…À„ İÿÿ ,8:uWSÿÖ…À„g   À7:uWhÀ7ÿÖ…À„N   ´7:uWh´7ÿÖ…À„=İÿÿ ¨7»¨7:uWSÿÖ…À„?İÿÿ ”7:uWh”7ÿÖ…À„îÜÿÿ ´7:uWh´7ÿÖ…À„ñÜÿÿ ¨7:uWSÿÖ…À„øÜÿÿ ˆ7:uWhˆ7ÿÖ…À„ÿÛÿÿ |7:uWh|7ÿÖ…À„ªÜÿÿ p7:uWhp7ÿÖ…À„­Üÿÿ `7:uWh`7ÿÖ…À„p   P7:uWhP7ÿÖ…À„{Üÿÿ D7:uWhD7ÿÖ…À„FÜÿÿ 87»87:uWSÿÖ…À„HÜÿÿ $7:uWh$7ÿÖ…À„Üÿÿ D7:uWhD7ÿÖ…À„úÛÿÿ 87:uWSÿÖ…À„Üÿÿ 7:uWh7ÿÖ…À„Ä   7:uWh7ÿÖ…À„ïÚÿÿ ü6:uWhü6ÿÖ…À„~Ûÿÿ ô6:uWhô6ÿÖ…À„Ûÿÿ è6:uWhè6ÿÖ…À„„Ûÿÿ Ü6:uWhÜ6ÿÖ…À„G   Ì6:uWhÌ6ÿÖ…À„Ûÿÿ ¼6:uWh¼6ÿÖ…À„YÚÿÿ ¬6:uWh¬6ÿÖ…À„èÚÿÿ  6:uWh 6ÿÖ…À„ëÚÿÿ ”6:uWh”6ÿÖ…À„îÚÿÿ „6:uWh„6ÿÖ…À„±   t6:uWht6ÿÖ…À„øÙÿÿ d6:uWhd6ÿÖ…À„ÃÙÿÿ T6:uWhT6ÿÖ…À„RÚÿÿ H6:uWhH6ÿÖ…À„UÚÿÿ 86:uWh86ÿÖ…À„XÚÿÿ (6:uWh(6ÿÖ…À„   6:uWh6ÿÖ…À„Ùÿÿ 6:uWh6ÿÖ…À„-Ùÿÿ ø5:uWhø5ÿÖ…À„¼Ùÿÿ ì5:uWhì5ÿÖ…À„¿Ùÿÿ Ü5:uWhÜ5ÿÖ…À„ÂÙÿÿ Ì5:uWhÌ5ÿÖ…À„…   ¼5:uWh¼5ÿÖ…À„°Øÿÿ ¬5:uWh¬5ÿÖ…À„—Øÿÿ œ5:uWhœ5ÿÖ…À„&Ùÿÿ 5:uWh5ÿÖ…À„)Ùÿÿ „5:uWh„5ÿÖ…À„,Ùÿÿ t5:uWht5ÿÖ…À„ï   d5:uWhd5ÿÖ…À„ş×ÿÿ T5:uWhT5ÿÖ…À„Øÿÿ D5:uWhD5ÿÖ…À„Øÿÿ 85:uWh85ÿÖ…À„“Øÿÿ ,5:uWh,5ÿÖ…À„–Øÿÿ 5:uWh5ÿÖ…À„Y   5:uWh5ÿÖ…À„ô×ÿÿ 5:uWh5ÿÖ…À„KØÿÿ ô4:uWhô4ÿÖ…À„¦×ÿÿ è4:uWhè4ÿÖ…À„Øÿÿ Ü4:uWhÜ4ÿÖ…À„ Øÿÿ Ğ4:uWhĞ4ÿÖ…À„ç×ÿÿ À4:uWhÀ4ÿÖ…À„²×ÿÿ ´4:uWh´4ÿÖ…À„µ×ÿÿ  4:uWh 4ÿÖ…À„€×ÿÿ 4:uWh4ÿÖ…À„ƒ×ÿÿ „4:uWh„4ÿÖ…À„F   x4:uWhx4ÿÖ…À„5×ÿÿ l4:uWhl4ÿÖ…À„8×ÿÿ `4:uWh`4ÿÖ…À„×ÿÿ P4:uWhP4ÿÖ…À„×ÿÿ @4:uWh@4ÿÖ…À„µÖÿÿ 44:uWh44ÿÖ…À„¸Öÿÿ $4:uWh$4ÿÖ…À„»Öÿÿ 4:uWh4ÿÖ…À„~   ü3:uWhü3ÿÖ…À„©Õÿÿ ğ3:uWhğ3ÿÖ…À„pÖÿÿ ä3:uWhä3ÿÖ…À„WÖÿÿ Ø3:uWhØ3ÿÖ…À„   Ì3:uWhÌ3ÿÖ…À„	Öÿÿ °3:uWh°3ÿÖ…Àujéç    3:uWh 3ÿÖ…ÀujéË   3:uWh3ÿÖ…À„œÕÿÿ ˆ3:uWhˆ3ÿÖ…À„ŸÕÿÿ |3:uWh|3ÿÖ…À„¢Õÿÿ p3:uWhp3ÿÖ…À„e   d3:uWhd3ÿÖ…ÀujéK   T3:uWhT3ÿÖ…À„äÔÿÿ H3»H3:uWSÿÖ…À„:Õÿÿ <3:uWh<3ÿÖ…À„Õÿÿ 3:uWh3ÿÖ…Àuj$éã   3:uWh3ÿÖ…À„(Ôÿÿ H3:uWSÿÖ…À„×Ôÿÿ <3:uWh<3ÿÖ…À„¢Ôÿÿ ğ2:uWhğ2ÿÖ…Àuj é€   à2:uWhà2ÿÖ…À„qÓÿÿ H3:uWSÿÖ…À„tÔÿÿ <3:uWh<3ÿÖ…À„?Ôÿÿ Ä2:uWhÄ2ÿÖ…Àuj"é   ´2:uWh´2ÿÖ…Àujé   ¤2»¤2:uWSÿÖ…À„ÑÓÿÿ œ2:uWhœ2ÿÖ…À„ÔÓÿÿ 2:uWh2ÿÖ…À„×Óÿÿ „2:uWh„2ÿÖ…À„š   t2:uWht2ÿÖ…Àujé€   d2:uWhd2ÿÖ…À„QÓÿÿ \2:uWh\2ÿÖ…À„TÓÿÿ P2:uWhP2ÿÖ…À„WÓÿÿ D2:uWhD2ÿÖ…À„   42:uWh42ÿÖ…Àujé    $2:uWh$2ÿÖ…À„ÑÒÿÿ 2:uWh2ÿÖ…À„ÔÒÿÿ 2:uWh2ÿÖ…À„×Òÿÿ 2:uWh2ÿÖ…À„š
   ô1:uWhô1ÿÖ…À„mÒÿÿ è1:uWhè1ÿÖ…À„pÒÿÿ Ø1:uWhØ1ÿÖ…À„sÒÿÿ È1:uWhÈ1ÿÖ…À„6
   ¸1:uWh¸1ÿÖ…À„aÑÿÿ ¬1:uWh¬1ÿÖ…À„(Òÿÿ œ1:uWhœ1ÿÖ…À„ë	   Œ1:uWhŒ1ÿÖ…À„ÚÑÿÿ x1:uWhx1ÿÖ…Àujé¸	   3:uWh3ÿÖ…À„‰Ñÿÿ ˆ3:uWhˆ3ÿÖ…À„ŒÑÿÿ |3:uWh|3ÿÖ…À„Ñÿÿ p3:uWhp3ÿÖ…À„R	   d1:uWhd1ÿÖ…Àujé8	   ¤2:uWSÿÖ…À„Ñÿÿ œ2:uWhœ2ÿÖ…À„Ñÿÿ 2:uWh2ÿÖ…À„Ñÿÿ „2:uWh„2ÿÖ…À„Ö   T1:uWhT1ÿÖ…À„Øáÿÿ D1»D1:uWSÿÖ…À„Ğÿÿ 81:uWh81ÿÖ…À„’Ğÿÿ (1:uWh(1ÿÖ…À„•Ğÿÿ 1:uWh1ÿÖ…À„X   1:uWh1ÿÖ…Àujé>   ô0:uWhô0ÿÖ…À„Ğÿÿ ì0:uWhì0ÿÖ…À„Ğÿÿ à0:uWhà0ÿÖ…À„Ğÿÿ Ô0:uWhÔ0ÿÖ…À„Ø   Ä0:uWhÄ0ÿÖ…À„öàÿÿ ´0:uWh´0ÿÖ…À„’Ïÿÿ ¬0:uWh¬0ÿÖ…À„•Ïÿÿ  0:uWh 0ÿÖ…À„˜Ïÿÿ ”0:uWh”0ÿÖ…À„[   „0:uWh„0ÿÖ…À„±àÿÿ D1:uWSÿÖ…À„Ïÿÿ 81:uWh81ÿÖ…À„Ïÿÿ (1:uWh(1ÿÖ…À„Ïÿÿ 1:uWh1ÿÖ…À„â   t0:uWht0ÿÖ…À„É   h0:uWhh0ÿÖ…À„ÔÎÿÿ X0:uWhX0ÿÖ…À„—   H0:uWhH0ÿÖ…À„†Îÿÿ 40:uWh40ÿÖ…Àujéd   ô0:uWhô0ÿÖ…À„5Îÿÿ ì0:uWhì0ÿÖ…À„8Îÿÿ à0:uWhà0ÿÖ…À„;Îÿÿ Ô0:uWhÔ0ÿÖ…À„ş   $0:uWh$0ÿÖ…À„íÍÿÿ ä3:uWhä3ÿÖ…À„ğÍÿÿ Ø3:uWhØ3ÿÖ…À„³   Ì3:uWhÌ3ÿÖ…À„¢Íÿÿ 0:uWh0ÿÖ…Àujé€   ğ/:uWhğ/ÿÖ…Àujéd   3:uWh3ÿÖ…À„5Íÿÿ ˆ3:uWhˆ3ÿÖ…À„8Íÿÿ |3:uWh|3ÿÖ…À„;Íÿÿ p3:uWhp3ÿÖ…À„ş   Ü/:uWhÜ/ÿÖ…À„aÌÿÿ H3:uWhH3ÿÖ…À„ğÌÿÿ <3:u»<3WSÿÖ…Àu
é¹Ìÿÿ»<3 ¸/:uWh¸/ÿÖ…Àuj%é’   ¤/:uWh¤/ÿÖ…À„Ìÿÿ H3:uWhH3ÿÖ…À„‚Ìÿÿ <3:uWSÿÖ…À„QÌÿÿ „/:uWh„/ÿÖ…Àuj!é/   p/:uWhp/ÿÖ…À„äËÿÿ H3:uWhH3ÿÖ…À„Ìÿÿ <3:uWSÿÖ…À„îËÿÿ L/:uWhL/ÿÖ…Àuj#éÌ   ¤2:uWh¤2ÿÖ…À„Ëÿÿ œ2:uWhœ2ÿÖ…À„ Ëÿÿ 2:uWh2ÿÖ…À„£Ëÿÿ „2:uWh„2ÿÖ…À„f   ô1:uWhô1ÿÖ…À„9Ëÿÿ è1:uWhè1ÿÖ…À„<Ëÿÿ Ø1:uWhØ1ÿÖ…À„?Ëÿÿ È1:uWhÈ1ÿÖ…À„   8/:uWh8/ÿÖ…À„Êÿÿ ¬1:uWh¬1ÿÖ…À„ôÊÿÿ œ1:uWhœ1ÿÖ…À„·   Œ1:uWhŒ1ÿÖ…À„¦Êÿÿ $/:uWh$/ÿÖ…À„qÊÿÿ h0:uWhh0ÿÖ…À„Êÿÿ X0:uWhX0ÿÖ…À„S   H0:uWhH0ÿÖ…À„BÊÿÿ ô0:uWhô0ÿÖ…À„Êÿÿ ì0:uWhì0ÿÖ…À„Êÿÿ à0:uWhà0ÿÖ…À„Êÿÿ Ô0:uWhÔ0ÿÖ…À„Ö   ´0:uWh´0ÿÖ…À„©Éÿÿ ¬0:uWh¬0ÿÖ…À„¬Éÿÿ  0:uWh 0ÿÖ…À„¯Éÿÿ ”0:uWh”0ÿÖ…À„r   /:uWh/ÿÖ…À„¬Úÿÿ ´0:uWh´0ÿÖ…À„,Éÿÿ ¬0:uWh¬0ÿÖ…À„/Éÿÿ  0:uWh 0ÿÖ…À„2Éÿÿ ”0:uWh”0ÿÖ…À„õ    /:uWh/ÿÖ…ÀujéÛ    ô.:uWhô.ÿÖ…À„¬Èÿÿ ì.:uWhì.ÿÖ…À„¯Èÿÿ à.:uWhà.ÿÖ…À„²Èÿÿ Ô.:uWhÔ.ÿÖ…Àty Ä.:uWhÄ.ÿÖ…Àujëb ´.:uWh´.ÿÖ…À„3Èÿÿ ¬.:uWh¬.ÿÖ…À„6Èÿÿ  .:uWh .ÿÖ…À„9Èÿÿ ”.:uWh”.ÿÖ…ÀujXé   „.:uWh„.ÿÖ…Àu
¸Ù  éö   t.:uWht.ÿÖ…Àu
¸Ú  é×   d.:uWhd.ÿÖ…Àu
¸Û  é¸   P.:uWhP.ÿÖ…Àu
¸Ü  é™   8.:uWh8.ÿÖ…Àu
¸İ  éz   $.:uWh$.ÿÖ…Àu
¸Ş  é[   .:uWh.ÿÖ…Àu
¸ß  é<   ø-:uWhø-ÿÖ…Àu
¸à  é   à-:uWhà-ÿÖ…Àu
¸á  éş   Ì-:uWhÌ-ÿÖ…Àu
¸â  éß   ¸-:uWh¸-ÿÖ…Àu
¸ã  éÀ   ¤-:uWh¤-ÿÖ…Àu
¸ä  é¡   -:uWh-ÿÖ…Àu
¸å  é‚   |-:uWh|-ÿÖ…Àu
¸æ  éc   l-:uWhl-ÿÖ…Àu
¸ç  éD   \-:uWh\-ÿÖ…Àu
¸è  é%   H-:uWhH-ÿÖ…Àu
¸é  é   4-:uWh4-ÿÖ…Àu
¸ê  éç     -:uWh -ÿÖ…Àu
¸ë  éÈ    -:uWh-ÿÖ…Àu
¸ì  é©    ğ,:uWhğ,ÿÖ…Àu
¸í  éŠ    Ü,:uWhÜ,ÿÖ…Àu¸î  ën È,:uWhÈ,ÿÖ…Àu¸ï  ëR ¸,:uWh¸,ÿÖ…Àu¸‹  ë6 ¨,:uWh¨,ÿÖ…Àu¸¬  ë œ,:u2Whœ,ÿÖ…Àu&¸Ò   ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3Àë;¡d	j°°  è°$ÿÿPÿt$ÿ¡d	j hBWh„,ÿt$,ÿ   ƒÄ jX_^[ÃU‹ìQQVW3ÿ9}‰}ü‰}øu9}ujWXéH  EüPhHëjWh8ëÿ8ê‹ğ;÷Œ%  9}t‹Eüÿu‹PÿQP‹ğ;÷Œı   9}t‹Eüÿu‹PÿQ‹ğ;÷Œâ   9}t‹Eüÿu‹PÿQ,‹ğ;÷ŒÇ   9}t‹Eüÿu‹PÿQ‹ğ;÷Œ¬   f9}t‹Eüÿu‹PÿQ4‹ğ;÷Œ   9} tÿu$‹Eüÿu ‹PÿQD‹ğ;÷|v9}(t‹EüWÿu(‹PÿQH‹ğ;÷|^9},|‹Eüÿu,‹PÿQ<‹ğ;÷|G9}0t‹Eüÿu0‹PÿQ$‹ğ;÷|0‹EüUøRh˜ë‹Pÿ‹ğ;÷|‹Eøjÿu‹PÿQ‹ğ‹EøP‹ÿQ‹Eü;Çt‹PÿQ‹Æ_^ÉÃU‹ìì  VWjEü^3ÿPhHëVWh8ë‰}ü‰}ôÿ8ê;Ç|&‹EüUôRh˜ë‹Pÿ;Ç|‹EôWÿu‹PÿQ;Ç}WPÿuè}$ÿÿƒÄé  ‹EüSÿu‹ÿuPÿQL¡d	WWÿÜ   Y‹ğ‹EüY•è÷ÿÿh  ‹RPÿQ(‹}…À|?¡d	jh˜¸   ÿè   PVWÿ¡d	è÷ÿÿjÿQ˜¸   ÿğ  PVWÿƒÄ(‹Eü•è÷ÿÿh  R‹PÿQ…À|?¡d	jh¸I˜¸   ÿè   PVWÿ¡d	è÷ÿÿjÿQ˜¸   ÿğ  PVWÿƒÄ(‹EüUòRP‹ÿQ0…À|;¡d	jh°I˜¸   ÿè   PVWÿ·Mò¡d	Q˜¸   ÿØ   PVWÿƒÄ$‹EüUøR•è÷ÿÿ‹h  RPÿQ@…À|x¡d	j
h¤I˜¸   ÿè   PVWÿ¡d	ÿuø˜¸   ÿØ   PVWÿ¡d	j	h˜I˜¸   ÿè   PVWÿ¡d	è÷ÿÿjÿQ˜¸   ÿğ  ƒÄ@PVWÿƒÄ‹EüUìRP‹ÿQ…ÀuA¡d	jhI˜¸   ÿè   PVWÿ¡d	ÿuì˜¸   è»ÿÿPVWÿƒÄ$ÿuìÿ0êÿu‹Eü•è÷ÿÿ‹j h  RPÿQ…À|?¡d	jhˆI˜¸   ÿè   PVWÿ¡d	è÷ÿÿjÿQ˜¸   ÿğ  PVWÿƒÄ(‹EüUøRP‹ÿQ8…À|9¡d	jh|I˜¸   ÿè   PVWÿ¡d	ÿuø˜¸   ÿØ   PVWÿƒÄ$‹Eü•è÷ÿÿh  R‹PÿQ …À|?¡d	jhpI˜¸   ÿè   PVWÿ¡d	è÷ÿÿjÿQ˜¸   ÿğ  PVWÿƒÄ(¡d	VWÿ´  Y3ÿY3ö[‹Eü;Çt‹PÿQ‹Eô;Çt‹PÿQ‹Æ_^ÉÃU‹ìQQƒeü ƒeø EüPhhëjj hXëÿ8ê…À|V‹EüVÿu‹ÿuPÿQ‹ğ…ö|0‹EüUøRh˜ë‹Pÿ‹ğ…ö|‹Eøjÿu‹PÿQ‹ğ‹EøP‹ÿQ‹Eü…Àt‹PÿQ‹Æ^ÉÃU‹ìƒìVWjEü^3ÿPhhëVWhXë‰}ü‰}øÿ8ê;Ç|7‹EüUøRh˜ë‹Pÿ;Ç|"‹EøWÿu‹PÿQ;Ç|‹EüUôRP‹ÿQ;Ç}WPÿuèL ÿÿƒÄë*¡d	jÿÿuô°´  ÿğ  PÿuÿƒÄÿuôÿ0ê3ö‹Eü;Çt‹PÿQ‹Eø;Çt‹PÿQ‹Æ_^ÉÃU‹ìƒìƒeü ƒeø EüVPhhëjj hXëÿ8ê‹ğ…ö|S‹EüUøRh˜ë‹Pÿ‹ğ…ö|<‹Eøj ÿu‹PÿQ‹ğ…ö|(‹EUè‰Eì‹E‰Eğ‹E‰Eô‹EüÇEè   R‹PÿQ‹ğ‹Eü…Àt‹PÿQ‹Eø…Àt‹PÿQ‹Æ^ÉÃè   …Àtÿt$ÿt$ÿĞÃ3ÀÃƒ=¬ u.¡…ÀuhĞIÿä…À£thÀIPÿä£¬¡¬Ãè   …Àtÿt$ÿĞÃƒ=´ u.¡¼…ÀuhĞIÿä…À£¼thÜIPÿä£´¡´Ãè
   …ÀtÿĞÃ3ÀÃƒ= u.¡˜…ÀuhĞIÿä…À£˜thìIPÿä£¡Ãè
   …ÀtÿĞÃ3ÀÃƒ=0 u.¡L…ÀuhĞIÿä…À£LthüIPÿä£0¡0ÃU‹ìì  è«   …ÀuPjë*¹   •ôûÿÿQRQôıÿÿQìùÿÿh  QÿĞ…Àtj PÿuèÜÿÿƒÄÉÃV…ìùÿÿjÿP¡d	ÿğ  ‰Eô…ôıÿÿjÿP¡d	ÿğ  ‰Eø…ôûÿÿjÿP¡d	ÿğ  ‰Eü¡d	MôQj°´  ÿÜ   PÿuÿƒÄ(3À^ÉÃƒ=° u.¡ü…ÀuhĞIÿä…À£üthJPÿä£°¡°ÃU‹ìƒìè~   …ÀuPjëMüQÿuÿuÿuÿuÿĞ…Àtj PÿuèúÿÿƒÄÉÃ‹EüVÁè¶ÀP3ÀŠEı¶ÀP¶EüPhJEèjPÿ(å¡d	MèjÿQ°´  ÿè   PÿuÿƒÄ(3À^ÉÃƒ= u.¡8…ÀuhĞIÿä…À£8th0JPÿä£¡ÃU‹ìè   …ÀujX]ÃÿuÿuÿuÿuÿuÿuÿĞ]Ãƒ=ô u.¡…ÀuhĞIÿä…À£th@JPÿä£ô¡ôÃU‹ìƒì(‹ES‰EØ‹E‰EÜ‹E‰Eà‹E‰Eäf‹Ef‰Eè‹E ‰EòEØ3ÛP‰]îÿèæ…Àt¡d	ShPJÿuÿ¨  ƒÄjXé¯   ¡d	VÿuêÿÌ   ‰Eø¡d	SSÿÜ   ‰Eü‹EîƒÄ;Ãt`9‹H~RWqÿvü¡d	ÿvô¸¸   ÿğ  Pÿuüÿuÿÿ6¡d	ÿvø¸¸   ÿğ  Pÿuüÿuÿ‹EîƒÄ(CƒÆ;|³_Pÿüæ¡d	MøQj°´  ÿÜ   PÿuÿƒÄ3À^[ÉÃU‹ìƒì$V3ö9utVj|ë EPEÜj$PVÿuÿá…ÀVuÿüãPÿuè¹ÿÿƒÄjXë,¡d	VÿÜ   ‹ğEÜVPè   ¡d	Vÿuÿ´  ƒÄ3À^ÉÃ¡d	SUVWjhğJ¸¸   ÿè   ‹t$ P3ÛVSÿ‹|$(¡d	ÿ7¨¸   ÿà   PVSÿU ¡d	jhàJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄHjhÌJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jh¼J¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄHj¨¸   h Jÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄHj
h„J¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhxJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄHjhhJ¨¸   ÿè   PVSÿU ¡d	ÿw ¨¸   ÿà   PVSÿU ƒÄ$_^][Ãÿt$ÿt$ÿ5áè   ƒÄÃU‹ìQEüƒeü Pj ÿuÿuÿU…Àuÿüãƒøzt3ÀÉÃÿEü‹EüÀVPÿ$å‹ğY…ötEüPVÿuÿuÿU…Àu
VÿåY3ö‹Æ^ÉÃÿt$ÿt$ÿ5áè‹ÿÿÿƒÄÃU‹ìÿu(ÿu ÿu$ÿuÿuÿuÿuÿuÿuÿá]ÃU‹ìQEüPEjPj ÿuÿ á…Àt‹E‹Mj‰XÉÃ3ÀÉÃU‹ììD  ¼÷ÿÿS‰MüVMôWQMø¸   Q‰EôP…¼÷ÿÿ‹5üàPÿuÿuÿuÿÖ…Àu^‹=üãÿ×ƒøztj ë7Eü3ÛPÿuôSÿuèÿÿƒÄ…Àu,EôPEøPÿuôÿuüÿuÿuÿuÿÖ…ÀuSÿ×PÿuèñÿÿƒÄjXéÿ  3Û¡d	‹uüSSÿÜ   9]øYY‰E†µ  ~8Wÿœã‰EP¡d	Wÿğ  ‰E¼‹EjÿDGP¡d	ÿğ  ‰EÀÿv¡d	ÿØ   ‰EÄÿv¡d	ÿØ   ‰EÈÿv¡d	ÿØ   ‰EÌÿv¡d	ÿØ   ‰EĞÿv¡d	ÿØ   ‰EÔ·FP¡d	ÿØ   ‰EØ·FP¡d	ÿØ   ‰EÜ·FP¡d	ÿØ   ‰Eàÿv ¡d	ÿØ   ‰Eä¡d	SSÿÜ   ‰Eè‹~$ƒÄ<şf9^‰]v@Wÿœã‰E¡d	ÿu˜¸   Wÿğ  Pÿuèÿuÿ‹EƒÄÿE|G·F9E|Â3Û‹F,Æ9^(tMìQPÿuèCÿÿƒÄ…Àt¡d	Shœÿè   Y‰EìY‹F4ÿv0ÆP¡d	ÿĞ   ‰Eğ¡d	M¼Qj¸¸   ÿÜ   Pÿuÿuÿ‹EøƒÄ+‰Eø6;Ã‡Kşÿÿÿu¡d	ÿuÿ´  …¼÷ÿÿY9EüYt
ÿuüÿåY3À_^[ÉÃj ÿt$ÿt$ÿt$ÿt$ÿ˜ãÃÿt$ÿ”ãƒøÿt…Àu
jÿä3ÀÃU‹ìì   }   j v¡d	h Kÿuÿ¨  ë+EP… øÿÿÿuPÿuÿã…ÀuPÿüãPÿuèWÿÿƒÄjXÉÃ¡d	Vÿu øÿÿ°´  Qÿğ  PÿuÿƒÄ3À^ÉÃU‹ì¸  è«« EüÇEü   P…üïÿÿPÿuÿuè6¨ …Àu)¡d	VüïÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃj PÿuèÃÿÿƒÄÉÃU‹ìQVEüÿuƒeü ÿuPj ÿuÿuèß§ …Àt=Ò €uE‹EüÀPÿ$å‹ğY…öt2j EüÿuPVÿuÿuè¬§ …ÀtSÿüãV‹ØÿåYSÿä[3öh4Kj ÿØäY‹ÆY^ÉÃU‹ìƒìSVWEøÿu3ö‰uô‰uüÿu‰uè‰uì‰uğPEğVPV‰uøÿuÿuÿuèD§ ‹å;Æt=Ò €u^‹Eğ‹=$åÀPÿ×;ÆY‰Eô„Ä   ‹Eø;Æt	ÀPÿ×Y‰Eü9uøt	9uü„¦   ÿuEøÿuPEğÿuüPÿuôÿuÿuÿuèÙ¦ ;ÆtVPÿuè„ÿÿƒÄé¨   ÿuôÿuè³
ÿÿY;ÆY‰Eè„›   9uøt ÿuüÿuè–
ÿÿY;ÆY‰Eìtwÿuü‹åÿÓYÿuôÿÓMè¡d	Q3É9uø¸´  •ÁAQÿÜ   PÿuÿƒÄ3ÿëi¡d	¸”  ÿåÿ0ÿ¡d	YVÿu¸   ÿ8  YPh8KÿuÿƒÄ9uètÿuèÿÓY9uìtÿuìÿÓY9uôtÿuôÿÓY9uütÿuüÿÓYj_h4KVÿØäY‹ÇY_^[ÉÃU‹ìƒì‹EW‰Eè‹E‰Eì‹E‰Eğ‹Eÿu$‰Eô‹E3ÿ‰Eø‹E ‰EüEPEèWP‰}èœ¥ ;Çt=Ò €tWPÿuè:ÿÿƒÄjXé…   EVP‹EÀPWÿuè ÿÿƒÄ…Àtj^ëTÿu$EPEèÿuPèI¥ ;ÇtWPÿuèîÿÿƒÄj^ë!¡d	jÿÿu°´  ÿğ  PÿuÿƒÄ3öÿuÿåYh4KWÿØäY‹ÆY^_ÉÃU‹ìQQSVWEøÿu3Û‰]ü‰]øPSÿuèÚ¤ ;Ãt =Ò €tSPÿuèrÿÿƒÄÇE   é   ‹}EüPÿuøSWè8ÿşÿƒÄ…ÀuÜÿuEøPÿuüÿuèŒ¤ ;ÃÇE   StPWè&ÿÿƒÄéÛ  ¡d	SÿÜ   ‹ğY;óY„Ã  ¡d	jhÈK˜¸   ÿè   PVWÿ‹EüƒÄ‹ …À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh¸K˜¸   ÿè   PVWÿ‹EüƒÄ(‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh¨K˜¸   ÿè   PVWÿ‹EüƒÄ(‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh”K˜¸   ÿè   PVWÿ‹EüƒÄ(‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh„K˜¸   ÿè   PVWÿ‹Mü¡d	ÿq˜¸   ÿà   PVWÿ¡d	jhtK˜¸   ÿè   ƒÄ@PVWÿ‹EüƒÄ‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	VWÿ´  ƒe ƒÄ3Ûh4KSÿØä9]üYY_^[t
ÿuüÿåY‹EÉÃU‹ìì€   VEäWPEPÿuÿuèY¢ 3ÿh4KW‹ğÿØäY;÷Y…*  9}ä…!  ‹E‰}ô%   ‰}ø=   ‰}ütw=   tZ=   t@ÿuE€h,LPÿüäÿu¡d	ÿl  E€WP¡d	hLÿuÿ   ƒÄ éú   ÿuğ¡d	ÿuìÿ¨  ëİEì¡d	QQİ$ÿÔ   Yëÿuì¡d	ÿà   ;ÇY‰EôtGÿuE€h,LPÿüäE€jÿP¡d	ÿè   ƒÄ;Ç‰EøtEôP¡d	jÿÜ   Y;ÇY‰Eüu Sjuô[‹;ÇtPèïÿÿYƒÆKuíjX[ëWP¡d	ÿuÿ´  Y3ÀYëBÿuäE€VhØKPÿüäE€jP¡d	ÿuÿ¨  ƒÄ9}ät‹uäWVÿuè€ÿÿƒÄjX_^ÉÃV‹t$W‹F=Ò €u1‹~Ç   ?PÿvÿàäY…ÀYt‰F‰~¸Ô €ë¸» À‰F_^Â U‹ìƒì(Vj(EØj Pè¤ ƒMØh   ÇEè   ÿ$å‰EäEØƒÄ‰EğEØÇEì—(PÇEø  èB  h4Kj ‹ğÿØäY…öYtÿuäÿåYVÿä3Àë‹Eä^ÉÃVÿt$è  h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$èõŸ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$èÜŸ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$ÿt$ÿt$è»Ÿ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$è¢Ÿ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$ÿt$ÿt$ÿt$è}Ÿ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$èdŸ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$èKŸ h4Kj ‹ğÿØäY‹ÆY^ÃVÿt$è2Ÿ h4Kj ‹ğÿØäY‹ÆY^ÃU‹ìƒìV‹ujÿFP¡d	ÿğ  ‰EìFDjÿP¡d	ÿğ  ÿ¶D  ‰Eğ¡d	ÿØ   ‰Eô†H  jÿP¡d	ÿğ  ‰Eø¡d	ÆH  jÿVÿğ  ‰EüEìP¡d	jÿÜ   ƒÄ,^ÉÃU‹ìƒìV‹uWj_FPèjÿÿ‰EğFPèjÿÿÿv$‰Eô¡d	ÿà   ‰Eø‹ƒÄƒøHu¡d	ƒÆ(jÿVÿè   ëƒøhu¡d	ƒÆ(jÿVÿğ  Y‰EüYj_EğP¡d	WÿÜ   YY_^ÉÃU‹ìƒìVj ÿ5TÿuèÉKÿÿj ‰Eôÿ5ÿuè¶Kÿÿÿu‰Eøèriÿÿ‰Eü¡d	MôQj°¸   ÿÜ   P‹Eÿpÿ0ÿƒÄ0jX^ÉÂ U‹ìQQ¡d	V‹uj j ‰uøÿÜ   Y‰EüYEøPh˜+ÿuÿuÿTç…ÀuPÿüãPVèÉÿÿÿuüèÒÿÿƒÄjXëÿuü¡d	Vÿ´  Y3ÀY^ÉÃƒì¡d	SUV3ÛWSSÿÜ   ‹ø¡d	j	hèL°¸   ÿè   PWSÿ‹t$@¡d	·NQ¨¸   ÿà   PWSÿU ¡d	j
hÜL¨¸   ÿè   PWSÿU ·N¡d	ƒÄ@Q¨¸   ÿà   PWSÿU ¡d	jhĞL¨¸   ÿè   PWSÿU ·N¡d	Q¨¸   ÿà   PWSÿU ¡d	j	hÄL¨¸   ÿè   PWSÿU ·N¡d	ƒÄHQ¨¸   ÿà   PWSÿU ¡d	jh¸L¨¸   ÿè   PWSÿU ·N
¡d	Q¨¸   ÿà   PWSÿU ¡d	j	h¬L¨¸   ÿè   PWSÿU ·N¡d	ƒÄHQ¨¸   ÿà   PWSÿU ¡d	jh¤L¨¸   ÿè   PWSÿU ·N¡d	Q¨¸   ÿà   PWSÿU ¡d	j
h˜L¨¸   ÿè   PWSÿU ·N¡d	ƒÄHQ¨¸   ÿà   PWSÿU ¡d	j¨¸   hˆLÿè   PWSÿU ·N¡d	Q¨¸   ÿà   PWSÿU ¡d	jhxL¨¸   ÿè   PWSÿU ¡d	ƒÄHÿv¨¸   ÿà   PWSÿU ¡d	jhhL¨¸   ÿè   PWSÿU ¡d	ÿv¨¸   ÿà   PWSÿU ¡d	jh`L¨¸   ÿè   PWSÿU ¡d	ƒÄHÿv¨¸   ÿà   PWSÿU ¡d	j]ÿv ÿØ   ‰D$$‹F ƒÄH„–   HteHtJH…¡   ·F$P¡d	ÿØ   ‰D$·F&P¡d	ÿØ   ‰D$ ·F(P¡d	ÿØ   ƒÄ‰D$jë]ÿv$¡d	ÿØ   ‰D$·F(ë·F$P¡d	ÿØ   ‰D$·F&P¡d	ÿØ   Y‰D$Yjë·F$P¡d	ÿØ   Y‰D$j]¡d	jhXLˆ¸   ‰L$,ÿè   P‹D$0WSÿ¡d	ˆ¸   ‰L$8L$$QUÿÜ   P‹D$DWSÿ¡d	j	hLL¨¸   ÿè   PWSÿU ·N,¡d	Q¨¸   ÿà   ƒÄ@PWSÿU ¡d	jh4L¨¸   ÿè   PWSÿU ·N.¡d	Q¨¸   ÿà   PWSÿU ƒÄ0‹Ç_^][ƒÄÃU‹ìƒìSVEWPEøP¡d	ÿuÿuÿ¼   ƒÄ…À…ü  öEøtPh8Mÿuéº  ‹uj0j VèÀ› ‹Eøƒeô ƒÄH…ÀfÇ0 †  j_‹Eÿtü¡d	ÿX  ‹ØYŠ:ÜLu3hÜLSè› Y…ÀYu"FP‹Eÿ4ÿuèbüşÿƒÄ…À…s  é  Š:èLuhèLSèàš Y…ÀYuFëÁŠ:ĞLuhĞLSèÀš Y…ÀYuFë¡Š:ÄLuhÄLSè š Y…ÀYuFëŠ:¸Luh¸LSè€š Y…ÀYuF
é^ÿÿÿŠ:¬Luh¬LSè]š Y…ÀYuFé;ÿÿÿŠ:¤Luh¤LSè:š Y…ÀYuFéÿÿÿŠ:˜Luh˜LSèš Y…ÀYuFéõşÿÿŠ:ˆLuhˆLSèô™ Y…ÀYuFéÒşÿÿŠ:xLuhxLSèÑ™ Y…ÀYuFë>Š:hLuhhLSè±™ Y…ÀYuFëŠ:`Lu.h`LSè‘™ Y…ÀYuFP‹Eÿ4¡d	ÿuÿ¤   éişÿÿŠ:LLuhLLSèY™ Y…ÀYuF,é7şÿÿŠ:4Luh4LSè6™ Y…ÀYuF.éşÿÿŠ:XL…u  hXLSè™ Y…ÀY…`  E‹]PEüP‹Eÿ4¡d	Sÿ¼   ƒÄ…À…V  9Eü„  EğP‹Eÿ0¡d	Sÿ¤   ƒÄ…À…-  ‹Eğ‰F H„²   H„‚   HtSH…¾   ƒ}ü…Ï   F$P‹EÿpSèÙùşÿƒÄ…À…´   F&P‹EÿpSè¾ùşÿƒÄ…À…™   F(P‹Eÿpëeƒ}ü…ƒ   F$P‹Eÿp¡d	Sÿ¤   ƒÄ…ÀufF(ë ƒ}üu[F$P‹EÿpSèeùşÿƒÄ…ÀuDF&P‹Eÿpëƒ}üu2F$P‹EÿpSè<ùşÿƒÄ…Àu‹EøƒEôƒÇH9EôŒ}üÿÿ3À_^[ÉÃj hMS¡d	ÿ¨  ƒÄë¡d	j hBShôLÿuÿ   ƒÄjXëÀU‹ìQQV3ö9uuE¡d	jÿÌ   ‰Eø¡d	VVÿÜ   ‰Eü¡d	MøQj°´  ÿÜ   PÿuÿƒÄéÇ   ‹EURU‹RÿuPÿQ;ÆtƒøtVPÿuè€ÿşÿƒÄjXé—   3É;Æ¡d	”ÁQÿÌ   ‰Eø¡d	VVÿÜ   ƒÄ9u‰EütG9uS‹0êv5W‹M¡d	jÿÿ4±¸¸   ÿğ  Pÿuüÿuÿ‹EƒÄÿ4°ÿÓF;urÍ_ÿuÿÓ[¡d	MøQj°´  ÿÜ   PÿuÿƒÄ3À^ÉÃU‹ìƒìSUüV‹ERU‹Rÿu3Û‰]üÿuPÿQ ;Ã‰]øŒâ   ƒø~D= t$= t= …Ä   jh˜Mëj
hŒMëjh€M¡d	ÿè   Y‰EôYëm¡d	WjhxMÿè   ‰Eô¡d	SSÿÜ   ƒÄ3ÿf9]‰Eøv-¡d	°¸   ·ÇÁàEüPèÖîşÿPÿuøÿuÿƒÄGf;}rÓ9]ü_t	ÿuüÿ0êMô¡d	Q3É9]ø°´  •ÁAQÿÜ   PÿuÿƒÄ3ÀëSPÿuèÀışÿƒÄ^[ÉÃU‹ìQ‹EUüRU‹RPÿQ\…À|(·M¡d	VQÿuü°´  ÿĞ   PÿuÿƒÄ3À^ÉÃj PÿuèmışÿƒÄÉÃU‹ìƒì¡d	SV¾è  WVÿPY3ÿMô‰EüQMøQVPjWÿuèE“ ‹üã…Àu,ÿÓƒøz‰Eğt"ÿuü¡d	ÿPWÿuğÿuèışÿƒÄjXé¢  9uøvMÿuü¡d	ÿPÿuø¡d	ÿPY‰EüYMôQMøQÿuøPjWÿuèØ’ …ÀuWÿÓPÿuè¹üşÿƒÄj_éB  ¡d	WWÿÜ   9}ôYY‰Eğ‰}†  ‹Eüpë3ÿ¡d	WWÿÜ   ‹ø¡d	jh¼M˜¸   ÿè   PWÿuÿ‹FüƒÄ…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PWÿuÿ¡d	jh°M˜¸   ÿè   PWÿuÿ‹ƒÄ(…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PWÿuÿ¡d	j
h¤M˜¸   ÿè   PWÿuÿ¡d	ÿv˜¸   ÿà   PWÿuÿ¡d	Wÿuğÿuÿ¸   ƒÄDÿE‹EƒÆ;Eô‚ùşÿÿ3ÿÿuğ¡d	ÿuÿ´  YYÿuü¡d	ÿPY‹Ç_^[ÉÃƒ|$ t	ÿt$è`’ Ãƒ|$ t	ÿt$èU’ ÃU‹ìƒìSVEôWPEü3ÿPjWÿu‰}üè9’ …Àu?ÿüã9}ü‹ğt	ÿuüèµÿÿÿY¡d	WhèMÿuÿ¨  WVÿuèŞúşÿƒÄjXéŞ  ¡d	WWÿÜ   9}ô‹]Y‰EøY‰}†¡  3öë3ÿ¡d	WWÿÜ   ‹ø¡d	j	hˆ#ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ˆ¸   ‰M‹Müÿ4ÿà   P‹EWSÿ¡d	j	h¬#ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄ@ˆ¸   ‰M‹Müÿtÿà   P‹EWSÿ¡d	jhØMˆ¸   ‰Mÿè   P‹EWSÿ‹EüƒÄ$‹D…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jÿhÌMˆ¸   ‰Mÿè   P‹EWSÿ‹EüƒÄ(‹D…Àt+MğQPSèEğşÿƒÄ…À…   ÿuğ¡d	WSÿ¸   ƒÄë&¡d	jÿhœˆ¸   ‰Mÿè   P‹EWSÿƒÄ¡d	WÿuøSÿ¸   ƒÄÿE‹EƒÆ;Eô‚cşÿÿÿuüèÁıÿÿÿuø¡d	Sÿ´  ƒÄ3À_^[ÉÃÿuüè ıÿÿWèóÿÿÿuøèëÿÿƒÄé÷ıÿÿU‹ìƒìVEøWPEü3ÿPjW‰}üÿuèÛ …Àu?ÿüã9}ü‹ğt	ÿuüèQıÿÿY¡d	Wh(Nÿuÿ¨  WVÿuèzøşÿƒÄjXé[  ¡d	SWWÿÜ   9}ø‹]Y‰EôY‰}†  3öë3ÿ¡d	WWÿÜ   ‹ø¡d	j	hˆ#ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ˆ¸   ‰M‹Müÿ4ÿà   P‹EWSÿ¡d	jhNˆ¸   ‰Mÿè   P‹EWSÿ‹EüƒÄ@‹D…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jhÔ ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ˆ¸   ‰M‹Müÿtÿà   P‹EWSÿ¡d	WÿuôSÿ¸   ƒÄDÿE‹EƒÆ;Eø‚èşÿÿÿuüèáûÿÿÿuô¡d	Sÿ´  ƒÄ3À[_^ÉÃU‹ìQV‹uEWPEüPVÿu3ÿ‰}üÿuè …Àu
ÿüã‹ğëV;÷|Oƒş~ƒş~Eƒş~
ƒş	~;ƒş69}üt-¡d	jÿÿuü°´  ÿğ  PÿuÿƒÄ9}üt	ÿuüèJûÿÿY3Àë5j2^9}üt	ÿuüè5ûÿÿY¡d	WhXNÿuÿ¨  WVÿuè^öşÿƒÄjX_^ÉÃU‹ìEPÿuÿuÿuÿuÿuÿ¨å3É;ÁtQPÿuè(öşÿƒÄjX]Ã9M„œ  ¡d	SVWQQÿÜ   ‹ğ¡d	jhO˜¸   ÿè   ‹}PVWÿ‹EƒÄ‹ …À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jhğN˜¸   ÿè   PVWÿ‹EƒÄ(‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jhÔN˜¸   ÿè   PVWÿ‹M¡d	ÿq˜¸   ÿà   PVWÿ¡d	j
hÈN˜¸   ÿè   ƒÄ@PVWÿ¡d	˜¸   ‹EƒÀPè'êşÿPVWÿ¡d	j
h¼N˜¸   ÿè   PVWÿ‹EƒÄ0‹@…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh¬N˜¸   ÿè   PVWÿ‹EƒÄ(‹@ …À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jh¤N˜¸   ÿè   PVWÿ‹M¡d	ÿq$˜¸   ÿà   PVWÿ¡d	j
h˜N˜¸   ÿè   ƒÄ@PVWÿ‹EƒÄ‹@(…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	jhˆN˜¸   ÿè   PVWÿ‹EƒÄ(‹@,…À‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVWÿ¡d	VWÿ´  ƒÄÿuè·† _^[3À]ÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v3GV‰Eÿu¡d	ÿu°¸   è   PÿuüÿuÿƒEƒÄC;rÕ^‹Eü_[ÉÃU‹ìƒìV‹uÿ6èR   ÿv‰Eì¡d	ÿØ   ÿv‰Eğè6   ÿv‰Eôè+   ÿv‰Eø¡d	ÿØ   ‰EüEìP¡d	jÿÜ   ƒÄ^ÉÃ¡d	Vjÿÿt$°è   ÿ„éPÿYY^ÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v6GV‰Eÿu¡d	ÿu°¸   è    PÿuüÿuÿE\  ƒÄC;rÒ^‹Eü_[ÉÃU‹ìƒìX¡d	S3ÛVShœÿè   ‹u‰E¨¡d	ÿ¶   ÿØ   ÿ¶  ‰E¬¡d	ÿØ   ÿ¶  ‰E°¡d	ÿØ   ÿ¶  ‰E´¡d	ÿØ   ÿ¶  ‰E¸†  P¡d	ÿĞ   ÿ¶  ‰E¼¡d	ÿØ   ÿ¶   ‰EÀ¡d	ÿØ   ÿ¶$  ‰EÄ¡d	ÿØ   S‰EÈÿ¶(  ¡d	ÿ¨  S‰EÌÿ¶,  ¡d	ÿ¨  S‰EĞÿ¶0  ¡d	ÿ¨  ƒÄD‰EÔ¡d	Sÿ¶4  ÿ¨  S‰EØÿ¶8  ¡d	ÿ¨  ÿ¶<  ‰EÜ¡d	ÿØ   S‰Eàÿ¶@  ¡d	ÿ¨  S‰Eäÿ¶D  ¡d	ÿ¨  S‰Eèÿ¶H  ¡d	ÿ¨  S‰Eìÿ¶L  ¡d	ÿ¨  S‰Eğÿ¶P  ¡d	ÿ¨  ÿ¶T  ‰Eô¡d	ÿØ   ‰Eø‹†X  ƒÄ@8œ0[  uHP¡d	Æ\  Vÿè   ‰EüE¨P¡d	jÿÜ   ƒÄ^[ÉÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v3GV‰Eÿu¡d	ÿu°¸   è   PÿuüÿuÿƒEƒÄC;rÕ^‹Eü_[ÉÃU‹ìƒì¡d	V‹uÿ6ÿØ   ÿv‰EğFP¡d	ÿĞ   ÿv‰Eôèëüÿÿÿv‰Eø¡d	ÿØ   ‰EüEğP¡d	jÿÜ   ƒÄ^ÉÃU‹ìì<  ¡d	SV‹uWÿ6ÿØ   ÿv‰EÜè™üÿÿ‹=ˆé‰Eà¡d	YY˜Ø   f‹FPÿ×·ÀPÿÿv‰Eäèküÿÿ‰Eè¡d	Y˜Ø   f‹FYPÿ×·ÀPÿƒ}Y‰EìsEÜPjé»   ÿv¡d	ÿØ   }    Y‰EğsEÜPjé•   ÿv¡d	ÿvÿ¨  Y‰EôYèŒ   …ÀÇE  t?MQÄûÿÿQj VÿĞ…Àu+¡d	jÿÿµÄûÿÿÿğ  jÿ‰EøÿµÈûÿÿ¡d	ÿğ  ë$¡d	¾œjÿVÿè   ‰Eø¡d	jÿVÿè   ƒÄ‰EüEÜPj	¡d	ÿÜ   YY_^[ÉÃƒ=è u.¡8…Àuh<Oÿä…À£8th OPÿä£è¡èÃU‹ìì0  V‹uWÿ6èûÿÿ‰Eè¡d	Y¸Ø   f‹FPÿˆé·ÀPÿƒ}Y‰EìsEèPjé»   ÿv¡d	ÿØ   }    Y‰EğsEèPjé•   ÿv¡d	ÿvÿ¨  Y‰EôYè‹   …ÀÇE  t?MQĞûÿÿQj VÿĞ…Àu+¡d	jÿÿµĞûÿÿÿğ  jÿ‰EøÿµÔûÿÿ¡d	ÿğ  ë$¡d	¾œjÿVÿè   ‰Eø¡d	jÿVÿè   ƒÄ‰EüEèPj¡d	ÿÜ   YY_^ÉÃƒ=¨ u.¡ğ…Àuh<Oÿä…À£ğthLOPÿä£¨¡¨ÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v5GV‰E¡d	jÿu°¸   ÿuèÜüÿÿPÿuüÿuÿƒEƒÄC;rÓ^‹Eü_[ÉÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v5GV‰E¡d	jÿu°¸   ÿuèüÿÿPÿuüÿuÿƒEƒÄC;rÓ^‹Eü_[ÉÃU‹ìQQ¡d	SV3öVVÿÜ   ‹]YY‰Eø93‰uüv=CW‰E¾    ¡d	Vÿu¸¸   ÿuèüÿÿPÿuøÿuÿuƒÄÿEü‹Eü;rĞ_‹Eø^[ÉÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v5GV‰E¡d	jÿu°¸   ÿuèJıÿÿPÿuüÿuÿƒEƒÄC;rÓ^‹Eü_[ÉÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v5GV‰E¡d	jÿu°¸   ÿuèíüÿÿPÿuüÿuÿƒEƒÄC;rÓ^‹Eü_[ÉÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v;GV‰E¡d	h¨   ÿu°¸   ÿuèüÿÿPÿuüÿuÿE    ƒÄC;rÍ^‹Eü_[ÉÃÿt$ÿt$èşÿÿYYÃÿt$ÿt$è#ÿÿÿYYÃU‹ìƒ}uR‹E…À|Kƒø~$ƒø~ƒø<ÿuÿuè0şÿÿëÿuÿuèÆıÿÿëÿuÿuè\ıÿÿYYP¡d	ÿuÿ´  Y3ÀY]Ãj jWÿuèÎéşÿƒÄ]ÃU‹ìƒ}u‹Eƒè t1Ht!Htj jWÿuè¦éşÿƒÄ]ÃÿuÿuèŞşÿÿëÿuÿuètşÿÿëÿuÿuè
şÿÿYYP¡d	ÿuÿ´  Y3ÀY]ÃU‹ìƒì8V‹uWƒÏÿFWP¡d	ÿè   ‰EÈ†  WP¡d	ÿè   ÿ¶  ‰EÌ†”  P¡d	ÿĞ   ÿ¶œ  ‰EĞ¡d	ÿØ   ÿ¶   ‰EÔ¡d	ÿØ   ÿ¶¤  ‰EØ¡d	ÿØ   ‰EÜ†¬  Pÿuè¸   ‰Eà†Ø  WP¡d	ÿè   ‰Eä†   WP¡d	ÿè   ÿ¶$  ‰Eè¡d	ÿØ   ƒÄ@‰Eì†,  WP¡d	ÿè   ‰Eğ†T  WP¡d	ÿè   ‰Eô‹†x  ™RP¡d	ÿ¨  ‰Eø‹†|  ™RP¡d	ÿ¨  ‰EüEÈP¡d	jÿÜ   ƒÄ(_^ÉÃU‹ìƒì¡d	SVj j ÿÜ   ‹uY…öY‹ØthW€~ FtWjÿP¡d	ÿè   ‰EôFjÿP¡d	ÿè   ‰Eøÿv$¡d	ÿØ   ‰Eü¡d	MôQj¸¸   ÿÜ   PSÿuÿƒÄ(‹6…öuš_‹Ã^[ÉÃ¡d	SVj j ÿÜ   ‹t$Y…öY‹Øt(W¡d	Vÿt$¸¸   èèıÿÿPSÿt$ ÿ‹6ƒÄ…öuÚ_‹Ã^[ÃU‹ììl  VEüWP…”ıÿÿÇEüH  Pµ”ıÿÿè;} ‹øƒè tdƒèotƒèyuD¡d	j hhOÿuÿ¨  ë8ÿuüÿ$å‹ğY…ötEüPVèù| ‹ø…ÿt#VÿåYëj_j Wÿuè®æşÿƒÄjXéØ   ¡d	jÿVÿè   ‰EÜ†„   jÿP¡d	ÿè   ‰Eà†  Pÿuè¥   ‰Eäÿ¶4  ¡d	ÿØ   ‰Eè†8  jÿP¡d	ÿè   ‰Eìÿ¶<  ¡d	ÿØ   ‰Eğÿ¶@  ¡d	ÿØ   ‰Eôÿ¶D  ¡d	ÿØ   ‰Eø…”ıÿÿƒÄ0;ğtVÿåY¡d	MÜQj°´  ÿÜ   PÿuÿƒÄ3À_^ÉÃ¡d	SWj j ÿÜ   ‹|$Y…ÿY‹Øt0V€ Ot¡d	jÿQ°¸   ÿè   PSÿt$ ÿƒÄ‹?…ÿuÒ^‹Ã_[Ãj j hMh@Ëÿt$è   ƒÄÃU‹ìQQSV3öW9uuVjÿuè@åşÿƒÄjXé¨   ‹]jzÇEø   ‰uü_ƒÿztƒÿouL3ÿ9}üt
ÿuüÿåYEüPÿuøWSèâÓşÿƒÄ…Àu¸9}tÿuEøPÿuüÿUë
EøPÿuüÿUF‹øƒş
|ª…ÿuÿuü¡d	S°´  ÿUPSÿƒÄëj WSè§äşÿƒÄƒ}ü t
ÿuüÿåY3À…ÿ•À_^[ÉÃU‹ìì”   VEüWP…lÿÿÿÇEü„   Pµlÿÿÿÿuè–z ‹øƒè tdƒèotƒèyuG¡d	j h Oÿuÿ¨  ë;ÿuüÿ$å‹ğY…ötEüPVÿuèQz ‹ø…ÿt VÿåYëj_j WÿuèúãşÿƒÄjXëgÿ6¡d	ÿØ   ‰Eğÿv¡d	ÿØ   ‰EôFPÿuèşıÿÿ‰Eø…lÿÿÿƒÄ;ğtVÿåY¡d	MğQj°´  ÿÜ   PÿuÿƒÄ3À_^ÉÃj j h¡QhLËÿt$èşÿÿƒÄÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9~6GV‰Eÿu¡d	ÿu°¸   è    PÿuüÿuÿE  ƒÄC;|Ò^‹Eü_[ÉÃU‹ìQQ¡d	V‹uÿ6ÿØ   ‰Eø¡d	ƒÆjÿVÿğ  ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃU‹ìì\  ‹E‰…¤şÿÿ…¤üÿÿPèñx …Àtj PÿuèâşÿƒÄjXÉÃ¡d	V°´  …¤üÿÿPÿuè>ğÿÿPÿuÿƒÄ3À^ÉÃÿt$jhsBhXËÿt$èùüÿÿƒÄÃÿt$jh–Ah^Ëÿt$èÜüÿÿƒÄÃÿt$jh×DhdËÿt$è¿üÿÿƒÄÃÿt$jhShjËÿt$è¢üÿÿƒÄÃU‹ìQ¡d	S3ÛWSSÿÜ   ‹}YY‰Eü9v3GV‰Eÿu¡d	ÿu°¸   è   PÿuüÿuÿƒE8ƒÄC;rÕ^‹Eü_[ÉÃU‹ìƒì8V‹uÿ6èÓîÿÿÿv‰EÈèÈîÿÿÿv‰EÌ¡d	ÿØ   ÿv‰EĞè¬îÿÿÿv‰EÔ¡d	ÿØ   ÿv‰EØ¡d	ÿØ   ÿv‰EÜ¡d	ÿØ   ÿv‰Eà¡d	ÿØ   ÿv ‰Eä¡d	ÿØ   ÿv$‰Eè¡d	ÿØ   ÿv(‰Eì¡d	ÿØ   ÿv,‰Eğ¡d	ÿØ   ÿv0‰Eô¡d	ÿØ   ÿv4‰Eø¡d	ÿØ   ‰EüEÈP¡d	jÿÜ   ƒÄ@^ÉÃU‹ìVèW   3ö;ÆVujÿuè‡àşÿƒÄë>ÿuMÿuÿuQÿuÿĞ;Æt	ƒøztVPëÔ¡d	ÿu°´  ÿØ   PÿuÿƒÄ3À^]Ãƒ=Ì u.¡à…Àuh<Oÿä…À£àthØOPÿä£Ì¡ÌÃU‹ìVèW   3ö;ÆVujÿuèêßşÿƒÄë>ÿuMÿuÿuQÿuÿĞ;Æt	ƒøztVPëÔ¡d	ÿu°´  ÿØ   PÿuÿƒÄ3À^]Ãƒ= u.¡<…Àuh<Oÿä…À£<thìOPÿä£¡ÃU‹ìQSVWèô   ‹ø3Û;ûtU‹5ˆãjÿu‰]üÿÖPEüÿuPÿ×‹ø;û…‹   ÿuü¡d	ÿu¸´  èÄôÿÿPÿuÿƒÄÿuüSÿÖPÿŒãé   ÿuE‰]PSèQu ‹øƒÿzuCÿuÿ$å‹ØY…ÛuP¡d	hÿuÿ¨  ë'ÿuEPSèu ‹ø…ÿtSÿåY3ÛSWÿuèšŞşÿƒÄjXë&¡d	Sÿu°´  èéñÿÿPÿuÿSÿåƒÄ3À_^[ÉÃƒ=È u.¡ø…Àuh<Oÿä…À£øth PPÿä£È¡ÈÃU‹ìQSVWèô   ‹ø3Û;ûtU‹5ˆãjÿu‰]üÿÖPEüÿuPÿ×‹ø;û…‹   ÿuü¡d	ÿu¸´  è—óÿÿPÿuÿƒÄÿuüSÿÖPÿŒãé   ÿuE‰]PSèt ‹øƒÿzuCÿuÿ$å‹ØY…ÛuP¡d	hÿuÿ¨  ë'ÿuEPSèàs ‹ø…ÿtSÿåY3ÛSWÿuè]İşÿƒÄjXë&¡d	Sÿu°´  èÏñÿÿPÿuÿSÿåƒÄ3À_^[ÉÃƒ=À u.¡H…Àuh<Oÿä…À£Hth$PPÿä£À¡ÀÃU‹ìì,  ¡ø…Àujè’   £øVMØÿuj QÔûÿÿh  QjÿuÿĞ‹ğVÿŒé…ötj VÿuèšÜşÿƒÄjXëM…ÔûÿÿjÿP¡d	ÿè   ‰EøEØjÿP¡d	ÿè   ‰Eü¡d	MøQj°´  ÿÜ   PÿuÿƒÄ 3À^ÉÃU‹ìì0  ƒ=ü ÇEäŒPÇEèZÇEì€PÇEğÆ_ÇEôpPÇEøRZt·E‹Å\Pé7  SVW…Ğıÿÿh  Pÿ„ã…À„  …ĞıÿÿP…ØşÿÿPèßt …ØşÿÿhPPPèæt ‹=äƒÄ…ØşÿÿPÿ×‹ä‹ğ…öthŒPVÿÓ…Àu	Vÿä3ö…öuO…ĞıÿÿP…ØşÿÿPè„t …ØşÿÿhHPPè‹t ƒÄ…ØşÿÿPÿ×‹ğ…ötqhŒPVÿÓ…Àu	Vÿä3ö…ötXƒeü ƒ=Üê ~+}èÿwüVÿÓ…À‰tÿEüƒÇ‹Eü;Üê|ãë	Vÿä3ö…öt‹Üê3À…É~‹TÅè‰Å\P@;Á|ğ·E_^‹Å\PÇü   [ÉÂ SV‹t$…ö‹Şt+W‹=å‹F…ÀtPÿ×Y‹F…ÀtPÿ×Y‹vSÿ×…öY‹Şuİ_^[Â U‹ìƒì$SVW‹}3Û3ö9]‰]ø‰]ô‰]ä‰]ü‰]ğ‰]à‰]ì‰]Ü‰]è‰u9]u
¸ù*  é-  ‹E;Ãty9X…µ   9X…¬   9X…£   9X…š   ‹öÁ‰Môt9]u
¸&'  éé  ‹H;Ëtƒùt
¸?'  éÓ  ‹p;ótƒştƒştƒşt
¸<'  é³  ‹@‰Eä9]„Ñ   Eàj
PÿuÿĞä‹MàƒÄ‰Eü8u*Pÿ˜é;ó‰Eè‰Eü…    j^‰uìé•   ¸û*  é^  ‹=”é;ótƒşuhœPÿuÿ×;Ãt
f‹@‰Eè‰Eü;ótƒşuh˜Pÿuÿ×;Ãt	f‹@‰Eüë‹EÜf9]üu‹Æ÷ØÀf%„üù*  éú   ;óu 3Éf;Ã”ÁAf;Ã‹ñtf9]èÇEì   u‰]ì‹}9]t<EğPÿuè   …ÀuI‹Eô¨tÇEøù*  éŸ   ƒàWPÿuüÿuäVÿuèy  ‰Eøëk‹Eô$öØÀ%ÿÿÿ€  Pÿ¬é‰EğÿuğÿuüÿuäVèâ   ;Ã‰u	ÇEø   ëK9]t0ƒöEôt'ÿuğÿ„éPèA   ‹‰A‹9XuÇEø   9]øu9]ìtÿ7ÿuèè  ;Ã‰Eøt	ÿ7è[ıÿÿ‰‹Eø_^[ÉÂ VW‹|$…ÿtWèÉo @PjÿÌä‹ğƒÄ…öu3ÀëWVèõp Y‹ÆY_^Â ‹L$V3ö‹ÑŠ„Àt<.uFŠBB„ÀuóƒşuQÿœéƒøÿu3Àë	‹L$j‰X^Â VW‹=Ìäj jÿ×‹ğY…öYtjjÿ×Y…ÀYuVÿåY3Àë3f‹T$jf‰P‹T$Y‰Pf‰‰N‹L$‰F‰N‹L$‰NÇF   ‹Æ_^Â U‹ìì  ŠœSV¾   W‹Î3À½ùûÿÿˆ•øûÿÿƒeü ó«‹Î½õ÷ÿÿh   ˆ•ô÷ÿÿÿuµô÷ÿÿó«…øûÿÿ½øûÿÿPÿÈäƒÄ…ô÷ÿÿ€eø ÿuPÿuÿuÿuÿuè   ‹Ø…Ûur‹Eƒ8 uIVèjn …ÀYt9VWèn Y…ÀYt,ÿEüƒ}üt#ÿu‹Ç‹ş‹ğPÿuÿuÿuÿuè7   ‹Ø…Ût¶ë»û*  …Ûu9]tVè?şÿÿ‹M‹‰B‹9Xuj[_‹Ã^[ÉÂ U‹ì‹ESVW‹}ÿuƒ' €  ÿ¤é‹Ø…ÛtYfƒ{u3fƒ{
u,‹s‹…Àt#ÿ0ÿuÿuÿuèQşÿÿ…À‰txƒÆëÜjXëE‹uh   ÿ3VÿÈä€¦    ƒÄ3Àë&ÿ é‹È¸ù*  +ÈtItItIë¸û*  ë¸ú*  _^[]Â V‹t$…öt1‹Fÿpÿt$ÿvjèÕıÿÿ…Àt‹N‰H‰F‹p…öuØ…ötjXë3À^Â U‹ìƒìSVW¾¤P}ô3É¥f¥‹}Eô;ù‰Eü„4  ƒ}‚*  fƒ?t
¸?'  é  9Mt9Mu9M„@  9M„7  ‹] ‰]ƒetöÃt
¸&'  éè   9Mto9Mtjf‹wöÃu'‹Ã$öØÀ%œPP·ÆPÿ€é…Àt‹ …Àt‰EüëVÿˆé·ÀPEôh PPÿüäƒÄÿuüè?l 9EYv~ÿuüÿuèxm YY3É9M„›   9M„’   ‹G9M‰EtPëejEjPÿ¨é…Àt!‹ …ÀtöÃ‹ğtNj.VÿìäY…ÀYt?€  ë:öÃt*ÿ é‹È¸ù*  +ÈtItIu¸û*  _^[ÉÂ ¸ú*  ëòÿuÿ„é‹ğVè—k 9EYvÖVÿuèÒl YY3ÀëÌ¸ù*  ëÅU‹ìƒì,SVW3ÿj EÔWPè|k ‹EƒÄ‰Eà¡j;Ç[‰]ØuWè5÷ÿÿ£MüQMÔQÿuÿuÿĞ‹ğVÿŒé;÷WtVÿuèKÓşÿƒÄjXéÒ   ¡d	WÿÜ   ‰E‹EüY;ÇY‰E„   9X‹puuƒxuof9uj¡d	jÿÿv¸è   ÿ„éPÿ‰Eô¡d	Y¸Ø   f‹FYPÿˆé·ÀPÿ‰Eø¡d	MôQS°¸   ÿÜ   Pÿuÿuÿ‹EüƒÄ3ÿ‹@‰Eü;Ç…{ÿÿÿ¡ ;ÇuSèKöÿÿ£ ÿuÿĞÿu¡d	ÿuÿ´  Y3ÀY_^[ÉÃU‹ìƒì8EÈPÿuÿuèÃh …Àu&¡d	V°´  EÈPÿuè›ğÿÿPÿuÿƒÄ3À^ÉÃj PÿuèÒşÿƒÄjXÉÃ‹D$ƒøw-t%HtHHtHt	Hu0¸4RÃ¸RÃ¸äQÃ¸¼QÃ¸ˆQÃƒèt%HtHt-ì  t¸hQÃ¸4QÃ¸QÃ¸àPÃ¸¬PÃU‹ìQW3ÿ9}t%}ê   uÿuèÍd WÿuÿuèˆÑşÿƒÄjXë_¡d	SVWWÿÜ   9}‹uY‹ØY~'‹}EüPÿuVÿUuüP¡d	Sÿuÿ¸   ƒÄOuÜ¡d	Sÿuÿ´  YYÿuè^d ^3À[_ÉÃU‹ìƒì(‹EV‰EØ‹E‰EÜ‹E‰Eà‹E‰Eè‹E ‰Eğ‹E$‰EüEWPEØ3ÿPhö  ÿu‰}ä‰}ì‰}ô‰}øètd ‹ğ;÷u3Àë3WVÿuè»ĞşÿƒÄƒşWu¡d	Wÿu°   èˆşÿÿYPÿuÿƒÄjX_^ÉÃU‹ìƒìV3öWEVPEøPEüjÿPjÿuèd ‹ø;şt%ÿê   uÿuüèc VWÿuèKĞşÿƒÄjXé´   ¡d	VVÿÜ   ‹øY3À9uøY‰Ev~‹Mü@jÿÿ4¡d	ÿğ  ‹Mü‰Eì‹E@ÿt¡d	ÿØ   ‹Mü‰Eğ‹Ejÿ@ÿt¡d	ÿğ  ‰Eô¡d	MìQj°¸   ÿÜ   PWÿuÿ‹EƒÄ(@;Eø‰Er‚¡d	Wÿuÿ´  YYÿuüèÇb 3À_^ÉÃU‹ìQQEVPÿuÿuè$c 3ö;Æu¡d	jÿØ   ÿu‰Eøë=	  VuA¡d	ÿØ   ‰EøV¡d	ÿØ   ‰Eü¡d	MøQj°´  ÿÜ   PÿuÿƒÄ3ÀëPÿuèÏşÿƒÄjX^ÉÃU‹ìVW‹}…ÿvtƒÿvÿö  ugEPWÿuÿuè‹b ‹ğ…öt%¡d	j hœRÿuÿ¨  j Vÿuè®ÎşÿƒÄëD¡d	Wÿu°´  ÿuè4   PÿuÿƒÄÿuèºa 3Àë¡d	j h`Rÿuÿ¨  ƒÄjX_^]ÃU‹ìƒì(‹EV‹uW3ÿH„µ   HtS-ô  t#9}t¡d	WhÄRÿuÿ¨  ƒÄ3ÀéÔ   jEü_Pÿv$ÿuè·ùşÿƒÄ…ÀuàP¡d	ÿØ   Y‰Eø¡d	jÿÿvƒÇÿğ  jÿ‰Eôÿv¡d	ÿğ  ÿv‰Eğ¡d	ÿØ   ÿv‰Eì¡d	ÿØ   ÿv‰Eè¡d	ÿØ   ƒÄ‰Eä¡d	jÿÿvÿğ  ÿv‰Eà¡d	ÿØ   jÿ‰EÜÿ6¡d	ÿğ  ‰EØEØP¡d	ƒÇWÿÜ   ƒÄ_^ÉÃU‹ìQQSVEüW¾ö  PVÿuÿuèÜ` ‹Ø3ÿ;ßt#¡d	WhœRÿuÿ¨  WSÿuèÿÌşÿƒÄëv‹Eü‹M‰H‹Eü‹M‰H‹Eü‹M‰x ‹Eü‰H$EøPÿuüVÿuÿuèƒ` ‹ğ;÷u3Àë;ÿuüèí_ WVÿuèªÌşÿƒÄƒşWu¡d	Wÿuø°   èwúÿÿYPÿuÿƒÄjX_^[ÉÃU‹ìì(  ‹Eƒ}$ ‰Eä‹E‰Eğ‹E‰Eô‹E‰EütÇE(ôE(ÇE  PEP…ØıÿÿPEàÿu,ÿu ÿu(PÿuèÊ` …Àu)¡d	VØıÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃPÿuèmÍşÿYYÉÃU‹ìQMW‹}¸  QPj W‰Eüè²ºşÿƒÄ…ÀtjXëNEüVPÿujÿuè[` …Àuÿu¡d	W°´  è'   PWÿƒÄ3öëPWèÍşÿYYj^ÿuÿåY‹Æ^_ÉÃU‹ìƒì¡d	V‹ujÿÿ6ÿğ  jÿ‰Eôÿv¡d	ÿğ  jÿ‰Eøÿv¡d	ÿğ  ‰EüEôP¡d	jÿÜ   ƒÄ ^ÉÃU‹ì¸0  èœb …ĞïÿÿW‰Eü‹E‰Eä‹E‰Eì‹E‰EÔEPEøP…ĞïÿÿPEĞPÇEø   è_ ‹}…ÀtX=ê   u.EüPÿuøj Wè—¹şÿƒÄ…Àu6EPEøPEĞÿuüPèI_ …Àt#PWèÌşÿ…ĞïÿÿY9EüYt
ÿuüÿåYjXëVVÿuüWèO   jÿ‰Eğÿu¡d	ÿğ  ‰Eô¡d	MğQj°´  ÿÜ   PWÿƒÄ …Ğïÿÿ9Eü^t
ÿuüÿåY3À_ÉÃU‹ì¡d	SVWj j ÿÜ   ‹ø¡d	jhDS°¸   ÿè   ‹]PWSÿ¡d	‹uÿ6ˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh<Sˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄ@ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh,Sˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh$Sˆ¸   ‰Mÿè   PWS‹Eÿ¡d	ƒÄHÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jhSˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ$…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jhSˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ(…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	j	hüRˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ(…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	j
hğRˆ¸   ‰Mÿè   P‹EWSÿ‹vƒÄ(…ö‹Îu¹ô¡d	jÿQ°¸   ÿğ  PWSÿƒÄ‹Ç_^[]ÃU‹ìƒìV3öWEüVPEôPEøjÿPVVèE[ ‹ø;şt%ÿê   uÿuøè¥Z VWÿuèbÇşÿƒÄjXé“   ¡d	VVÿÜ   9uôYY‹ø‰uüv_‹Eø‹Müjÿÿ4È¡d	ÿğ  ‹Mø‰Eì‹EüjÿÿtÁ¡d	ÿğ  ‰Eğ¡d	MìQj°¸   ÿÜ   PWÿuÿƒÄ$ÿEü‹Eü;Eôr¡¡d	Wÿuÿ´  YYÿuøèÿY 3À_^ÉÃU‹ìEPjÿuÿuèuZ …Àtj PÿuèÆşÿƒÄ]Ã¡d	Vÿu°´  ÿuè   PÿuÿƒÄÿuè©Y 3À^]Ã¡d	SUVWj j ÿÜ   ‹ğ¡d	j	hÄS¸¸   ÿè   ‹\$$PVSÿ‹|$4ƒÄ‹…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	j
h¸S¨¸   ÿè   PVSÿU ‹GƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jh¨S¨¸   ÿè   PVSÿU ‹GƒÄ(…À‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	j
hœS¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhŒS¨¸   ÿè   ƒÄ@PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jh|S¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄ@jhlS¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	¨¸   jh\Sÿè   PVSÿU ‹GƒÄ8…Àu¸ô‹d	jÿP©¸   ÿ‘ğ  PVSÿU ¡d	jhLS¨¸   ÿè   PVSÿU ‹ ƒÄ(…ÿu¿ô¡d	jÿW¨¸   ÿğ  PVSÿU ƒÄ‹Æ_^][ÃU‹ìì  EüÇEü   P…üıÿÿPÿuèŒX …ÀtPÿuèFÅşÿYYÉÃ¡d	VüıÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìEPÿuÿuèVW …Àtj PÿuèxÃşÿƒÄjX]Ã¡d	Vjÿÿu°´  ÿğ  PÿuÿƒÄÿuèV 3À^]ÃU‹ìEPÿuÿuèW …Àtj Pÿuè"ÃşÿƒÄjX]Ã¡d	Vÿu°´  è   PÿuÿƒÄÿuè.V 3À^]ÃU‹ìƒì¡d	V‹uÿ6ÿØ   ÿv‰Eì¡d	ÿØ   ‰Eğ¶FP¡d	ÿØ   ‰Eô¶F	P¡d	ÿØ   jÿ‰Eøÿv¡d	ÿğ  ‰EüEìP¡d	jÿÜ   ƒÄ ^ÉÃU‹ìEPÿuÿuè>V …Àtj PÿuèTÂşÿƒÄjX]Ã¡d	Vÿu°´  ÿà   PÿuÿƒÄ3À^]ÃU‹ìQQV3öWEVPEøPEüjÿPÿuèêU ‹ø;şt"ÿê   uÿuüè,U VWÿuèéÁşÿƒÄjXëd¡d	VVÿÜ   ‹øY3À9uøY‰Ev.‹Mü€Pè>   P¡d	Wÿuÿ¸   ‹EƒÄ@;Eø‰ErÒ¡d	Wÿuÿ´  YYÿuüè¸T 3À_^ÉÃU‹ìƒì¡d	V‹uÿ6ÿØ   ÿv‰Eè¡d	ÿØ   ÿv‰Eì¡d	ÿØ   ‰Eğ¶FP¡d	ÿØ   ‰Eô¶FP¡d	ÿØ   jÿ‰Eøÿv¡d	ÿğ  ‰EüEèP¡d	jÿÜ   ƒÄ$^ÉÃU‹ìV‹u…öt4ƒşt/ƒşt*ƒş
t%şö  t¡d	j hĞSÿuÿ¨  ƒÄjXë7Ej PEPEjÿPVÿuÿuÿuèvT Vh™tÿuÿuPÿuèÉîÿÿƒÄ^]Ã¡d	SUV3íWUUÿÜ   ‹\$$‹|$‹ğ‹D$ Y+ÅY‰+„&  H„³   Htbƒè„g  -ì  …U  ¡d	j	h8Tˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	jÿÿwˆ¸   ‰L$8ÿğ  P‹D$<VUÿƒÄ(ƒ¡d	jh,Tˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	jÿÿwˆ¸   ‰L$8ÿğ  P‹D$<VUÿƒÄ(ƒ¡d	jh Tˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	jÿÿwˆ¸   ‰L$8ÿğ  P‹D$<VUÿ¡d	j	hTˆ¸   ‰L$Lÿè   P‹D$PVUÿ¡d	ÿwˆ¸   ‰L$\ÿà   ƒÄ@P‹D$ VUÿ¡d	jhTˆ¸   ‰L$0ÿè   P‹D$4VUÿ¡d	ÿwˆ¸   ‰L$@ÿà   P‹D$DVUÿ¡d	j	h Tˆ¸   ‰L$Tÿè   P‹D$XVUÿ¡d	ƒÄDÿwˆ¸   ‰L$ ÿà   P‹D$$VUÿ¡d	j
hôSˆ¸   ‰L$4ÿè   P‹D$8VUÿ¡d	ÿwˆ¸   ‰L$Dÿà   P‹D$HVUÿƒÄ4ƒ¡d	jhìSˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	jÿÿ7ˆ¸   ‰L$8ÿğ  P‹D$<VUÿƒÄ(ƒ‹Æ_^][Ã¡d	jhìS¸¸   ÿè   PVUÿ¡d	‹|$(jÿÿ7ˆ¸   ‰L$8ÿğ  P‹D$<VUÿ¡d	jh Tˆ¸   ‰L$Lÿè   P‹D$PVUÿ¡d	jÿÿwˆ¸   ‰L$`ÿğ  ƒÄDPVU‹D$(ÿ¡d	ˆ¸   ‰L$(jhTÿè   PVU‹D$<ÿ¡d	ˆ¸   ‰L$<ÿwÿà   PVU‹D$Lÿ¡d	ˆ¸   ‰L$Lj	h Tÿè   PVU‹D$`ÿƒÄD¡d	ˆ¸   ‰L$ÿwÿà   PVU‹D$,ÿƒÄÇ   éÎşÿÿU‹ìEPÿuÿuÿuÿuèwP …Àtj Pÿuè{¼şÿƒÄjX]ÃEPÿuÿuèğûÿÿP¡d	ÿuÿ´  ƒÄÿuèƒO 3À]ÃU‹ìV‹u…öt"ƒşt¡d	j hĞSÿuÿ¨  ƒÄjXë4Ej PEPEjÿPVÿuÿuèğO Vh+yÿuÿuPÿuè7êÿÿƒÄ^]Ã¡d	SUV3ÛWSSÿÜ   ‹l$$‹|$‹ğ‹D$ Y+ÃY‰] „¿  H…  ¡d	jhXLˆ¸   ‰L$$ÿè   P‹D$(VSÿ¡d	ÿwˆ¸   ‰L$4ÿà   P‹D$8VSÿ¡d	j	hTˆ¸   ‰L$Hÿè   P‹D$LVSÿ¡d	ÿwˆ¸   ‰L$Xÿà   P‹D$\VSÿ¡d	ƒÄHˆ¸   jhT‰L$$ÿè   P‹D$(VSÿ¡d	ÿwˆ¸   ‰L$4ÿà   P‹D$8VSÿ¡d	j	hPTˆ¸   ‰L$Hÿè   P‹D$LVSÿ¡d	ÿwˆ¸   ‰L$Xÿà   P‹D$\VSÿ¡d	ƒÄHˆ¸   jh T‰L$$ÿè   P‹D$(VSÿ¡d	jÿÿwˆ¸   ‰L$8ÿğ  P‹D$<VSÿ¡d	jhHTˆ¸   ‰L$Lÿè   P‹D$PVSÿ¡d	jÿÿwˆ¸   ‰L$`ÿğ  ƒÄDP‹D$ VSÿƒÄƒE ¡d	jhDTˆ¸   ‰L$$ÿè   P‹D$(VSÿ¡d	ÿ7ˆ¸   ‰L$4ÿà   P‹D$8VSÿƒÄ$ƒE ‹Æ_^][ÃU‹ìV‹uƒşt"ƒşt¡d	j hĞSÿuÿ¨  ƒÄjXë7Ej PEPEjÿPVÿuÿuÿuèNM VhÓ{ÿuÿuPÿuèçÿÿƒÄ^]Ã¡d	SUV3íWUUÿÜ   ‹\$$‹|$‹ğ‹D$ HYHY‰+„/  H…s  ¡d	jhtTˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	ÿwˆ¸   ‰L$4ÿà   P‹D$8VUÿ¡d	j	hhTˆ¸   ‰L$Hÿè   P‹D$LVUÿ¡d	ÿwˆ¸   ‰L$Xÿà   P‹D$\VUÿ¡d	ƒÄHˆ¸   jh T‰L$$ÿè   P‹D$(VUÿ¡d	jÿÿwˆ¸   ‰L$8ÿğ  P‹D$<VUÿ¡d	jh\Tˆ¸   ‰L$Lÿè   P‹D$PVUÿ¡d	jÿÿwˆ¸   ‰L$`ÿğ  ƒÄDP‹D$ VUÿƒÄƒ¡d	jhDTˆ¸   ‰L$$ÿè   P‹D$(VUÿ¡d	ÿ7ˆ¸   ‰L$4ÿà   P‹D$8VUÿƒÄ$ƒ‹Æ_^][ÃU‹ìEPÿuÿuÿuèvK …Àtj Pÿuèh·şÿƒÄjX]ÃEPÿuÿuèşÿÿP¡d	ÿuÿ´  ƒÄÿuèpJ 3À]ÃU‹ìQQ¡d	V‹uÿ6ÿà   ÿv‰Eø¡d	ÿà   ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃU‹ìVEW‹}PEP¡d	ÿuWÿ¼   ƒÄ…ÀuUƒ}u9‹u‹EVÿ0¡d	Wÿ¤   ƒÄ…Àu‹EƒÆVÿp¡d	Wÿ¤   ƒÄ…Àt¡d	j h€TWÿ¨  ƒÄjX_^]Ã¡d	SUV3ÛWSSÿÜ   ‹ğ¡d	jhĞT¸¸   ÿè   PVSÿ‹|$0¡d	ÿ7¨¸   ÿà   PVSÿU ¡d	jhÄT¨¸   ÿè   PVSÿU ·O¡d	ƒÄ@Q¨¸   ÿà   PVSÿU ¡d	jh¼T¨¸   ÿè   PVSÿU ·O¡d	Q¨¸   ÿà   PVSÿU ¡d	j
h°T¨¸   ÿè   PVSÿU ¡d	ƒÄHÿw¨¸   ÿà   PVSÿU ¡d	jh¨T¨¸   ÿè   PVSÿU ‹GƒÄ$;Ãu¸ô‹d	jÿP©¸   ÿ‘ğ  PVSÿU ¡d	jh T¨¸   ÿè   PVSÿU ‹ƒÄ(;ûu¿ô¡d	jÿW¨¸   ÿğ  PVSÿU ƒÄ‹Æ_^][ÃV‹t$W3ÿ;÷t<9~t7S‹åU3í9~v ‹F‹D8…ÀtPÿÓ‹FYƒd8 EƒÇ;nràÿvÿÓY][_^ÃU‹ìƒìSVEğWPEøP¡d	ÿuÿuÿ¼   ƒÄ…À…(  ‹Eø‹]3ÿ@sÁàVPW‰;ÿu‰{è#£şÿƒÄ…À…ü   9}ø‰}Ê   ‹MEôPEìP‹Eğÿ4ˆ¡d	ÿuÿ¼   ƒÄ…À…Æ   ƒ}ì…   EP‹Eôÿ0¡d	ÿuÿ    ƒÄ…ÀuEüP‹Eôÿp¡d	ÿŒ   ‰Eè‹D8Pÿuüj ÿuè¢şÿƒÄ…Àud‹ÿC‹Müƒ} ‰8t€M€‹‹M‰L8ÿuü‹ÿuèÿt8ÿåƒÄÿE‹EƒÇ;EøŒ6ÿÿÿ3À_^[ÉÃ¡d	j hàTÿuÿ¨  ƒÄSèaşÿÿYjXë×U‹ìƒì¡d	VW3ÿWWÿÜ   ‹uYY‰Eü9>uj9~‰}v_S‹Fÿt¡d	ÿØ   ‰Eô‹FÇÿ0ÿp¡d	ÿĞ   ‰Eø¡d	MôQj˜¸   ÿÜ   Pÿuüj ÿƒÄ ÿE‹EƒÇ;Fr£[‹Eü_^ÉÃU‹ìƒìEøWPEüPÿDç3ÿ;ÇWtPÿuè{²şÿƒÄëd¡d	WÿÜ   9}üYY‰Eôv1SV3Û¡d	°¸   ‹EøÃPèÖûÿÿPÿuôÿuÿƒÄGƒÃ;}ürÕ^[ÿuøèØH ÿuô¡d	ÿuÿ´  Y3ÀY_ÉÃU‹ìƒì<SVW3Ûƒ=¤	jXu9¨	r}ğë3ÿ‰EÜjEä^‰EàE(WPEØ‰uèPEøP‹Eÿu(€Ì‰]ä‰]ìÿu$‰]Øÿu ÿuPÿuÿuÿuÿç‹È+Ët;é	 t*ItItSPÿuè„±şÿƒÄé®   jhUëjhUëjh UëVhüT¡d	ÿè   Y‰EÄYEøPèúÿÿ‰EÈEØPèşÿÿÿu(‰EÌ¡d	ÿà   ƒÄ;û‰EĞtÿw¡d	ÿ7ÿ¨  Y‰EÔY¡d	MÄQ3É;û°´  •ÁƒÁQÿÜ   PÿuÿƒÄ9]ìtÿuìèG 3À_^[ÉÃU‹ìƒì<SVW3Ûƒ=¤	jXu9¨	r}øë3ÿ‰EÜEäj‰Eà^EøPEPEØPEğP‹Eÿu€Ì‰uè‰]äP‰]ìÿu‰]Øÿuÿuÿç=	€tN;ÃtB=	 t2=	 t"=	 tSPÿuè8°şÿƒÄé·   jhUë!jhUëjh UëVhüTëjh0U¡d	ÿè   Y‰EÄYEğPèºøÿÿ‰EÈEØPè°üÿÿÿu‰EÌ¡d	ÿà   ƒÄ;û‰EĞtÿw¡d	ÿ7ÿ¨  Y‰EÔY¡d	MÄQ3É;û°´  •ÁƒÁQÿÜ   PÿuÿƒÄ9]ìtÿuìè,F 3À_^[ÉÃU‹ìQQSV‹5œãWÿuÿÖÿu‰EøÿÖÿu‹øÿÖ‹uø‹ØEüP;ÆD "Pj j èşÿƒÄ…Àt3Àé‡   ‹EüÇ@   ‹EüH‰‹Mü·Æ‰A‹Eü‹H‹LJ‰H‹Mü·Ç‰A‹Eü‹H‹PLJ‰H‹Mü·Ã‰AD6‹5åPÿu‹Eüÿ0ÿÖD?P‹EüÿuÿpÿÖDP‹EüÿuÿpÿÖ‹EüƒÄ$_^[ÉÃƒ|$ tÿt$ÿåYÃU‹ìƒì,SV‹uW3ÿ3Ûƒşv!ƒştƒştƒştƒş†+  ƒş‡"  EÔPVÿuÿç…À‰E…4  ƒş‡6  „  +ğ„°   N„  NtvNN…M  ÿuÔ¡d	ÿà   ÿuØ‰Eì¡d	ÿà   ÿuÜ‰Eğ¡d	ÿà   ÿuà‰Eô¡d	ÿà   ÿuä‰Eø¡d	ÿà   ‰EüEìP¡d	jÿÜ   ƒÄéÈ   ÿuØ¡d	ÿuÔÿ¨  ÿuà‰Eì¡d	ÿuÜÿ¨  ‰EğEìPjëJÿuÔ¡d	ÿà   ÿuØ‰Eì¡d	ÿà   ÿuÜ‰Eğ¡d	ÿà   ÿuà‰Eô¡d	ÿà   ‰EøEìPj¡d	ÿÜ   ƒÄë>‹]Ô…ÛtN¡d	jÿSÿğ  Y‹øYéá   ƒî„«   ƒît0Nu&ÿuÔ¡d	ÿà   Y‹ø…ÿt¡d	Wÿuÿ´  YY3À_^[ÉÃ‹EÔ¾ô…Àu‹ÆjÿP¡d	ÿğ  ‰Eì‹EØY…ÀYu‹ÆjÿP¡d	ÿğ  ‰EğEìP¡d	jÿÜ   ƒÄƒ}Ô ‹øtÿuÔèC ƒ}Ø „{ÿÿÿÿuØèıB énÿÿÿÿuØ¡d	ÿuÔÿ¨  é-ÿÿÿ¡d	WhDUÿuÿ¨  ƒÄ…ÛtSèÁB ƒ} „-ÿÿÿj ÿuÿuèù«şÿƒÄé/ÿÿÿU‹ìƒì`WEØ3ÿPWÿuÿç;ÇtWPÿuèÌ«şÿƒÄéê   ƒ}Ü vEüPÿuÜWÿuè”šşÿƒÄ…ÀtjXéÅ   E ‰Eü‹EÜS‰EÀ‹Eü‰EÈ‹E‰EÌ‹EVj‰EÔ^ÿuEÀ‰EğEèP‰uÄÿuÇEĞ  €‰uì‰}èÿuÿç‹Ø;ßtWSÿuèC«şÿƒÄëIÿuÀ¡d	ÿuÈÿĞ   ÿuÌ‰Eô¡d	ÿuÔÿĞ   ‰Eø¡d	MôQV¸´  ÿÜ   PÿuÿƒÄ 3ÿE 9Eüt
ÿuüÿåY3À;ß^[•À_ÉÃU‹ìì  WE¼3ÿPWÿuÿç;ÇtWPÿuè¯ªşÿƒÄé   ƒ}È S‹]VÇEğ 	€vEøPÿuÈWSèm™şÿƒÄ…À…5  ëE„‰Eøƒ}Ä vEôPÿuÄWSèF™şÿƒÄ…À…  ë	…dÿÿÿ‰Eô‹uş€   vEüPVWSè™şÿƒÄ…À…á   ë	…äşÿÿ‰EüVÿuÿuüÿå‹EÈƒÄ‰EÌ‹Eø‰EÔ‹Eü‰Eà‹EÄ‰Eä‹Eôj‰Eì_EÌÿu‰E¬E¤ƒe¤ PÇEĞ   ÿuÇEÜ   ‰uØÇEè	   ÿu‰}¨èŠ@ …À‰Eğtj PSè¥©şÿƒÄëYÿuÌ¡d	ÿuÔÿĞ   ÿuØ‰E°¡d	ÿuàÿĞ   ÿuä‰E´¡d	ÿuìÿĞ   ‰E¸¡d	M°QW°´  ÿÜ   PSÿƒÄ(‹5å…dÿÿÿ9EôtÿuôÿÖY…äşÿÿ9EütÿuüÿÖYE„9EøtÿuøÿÖY3À^9Eğ[•À_ÉÃU‹ìì   }   Vv2¡d	j°°  è§şÿPÿuÿ¡d	j htUÿuÿ¨  ƒÄëS… ÿÿÿPÿuÿuÿøà…Àt(ÿu¡d	 ÿÿÿQ°´  ÿĞ   PÿuÿƒÄ3Àëj ÿüãPÿuèo¨şÿƒÄjX^ÉÃQQSUVWèèşÿ…À‰D$ujëb‹-$å¿@œ  WÿÕ‹ğY…öujëID$PWVÿt$(ÿT$ ‹Øû  ÀuVÿÿåWÿÕY‹ğY…Ût…öuÏ…ötÇ…ÛtVÿåSèµşÿYYPÿä3Àë‹Æ_^][YYÃè5   …Àujë j ÿt$ÿt$ÿt$ÿt$ÿĞ…ÀtPèŞ´şÿYPÿä3ÀÃjXÃƒ=Ø u.¡…ÀuhPÿä…À£th˜UPÿä£Ø¡ØÃU‹ìQQè5   …ÀujëÿuMøÿuÿuQÿuÿĞ…ÀtPèd´şÿYPÿä3ÀÉÃjXÉÃƒ= u.¡ …ÀuhPÿä…À£ th¨UPÿä£¡Ã‹D$V3ö…Àt,‹P…Òt%‹H…ÉvQRj	ÿ0è`ÿÿÿƒÄ…Àuÿüã‹ğ‹Æ^ÃjWX^ÃU‹ìì¤   VWÿdã3ÿƒ=¤	‰EÌ‰}ì‰}ô‰}üuƒ=¨	ÇEà   sÇEà   jèÿıÿÿ‹ğY;÷‰uÔuWÿüãPÿuèK¦şÿƒÄjXé³  9}	ÇE2   ë¸è  9E|‰E¡d	SWWÿÜ   ‹‰EäEì‰]ĞPhd  Wÿuèã”şÿƒÄ…À…À  Eô¾  PVWÿuèÅ”şÿƒÄ…À…¢  EüPVWÿuè¬”şÿƒÄ…À…‰  ;ß‰}Ü  ‹EÔ‹hãpƒ}ÿt¶9E…Ó  ‹E;Ç|	;Fü…Ã  ƒ=¤	uƒ~üu	€>„«  ;Ç}÷Ø9Fü„œ  ÿvüjj@ÿlã;Ç‰Eèt!jjMøWQ·NÿuÌQPÿpã…ÀuÿuèÿÓ9}„³  éY  …\ÿÿÿj8PWÿuøè,ıÿÿƒÄ…ÀuÿuøÿÓÿuèÿÓ9}„c  é(  hd  ÿuìjÿuøèûüÿÿƒÄ…ÀuÿuøÿÓÿuèÿÓ9}„:  é÷  ‹Eôf‰8‹Eü‰8‰}ğ¶;Eà…”   ‹EøÇEÄ  ‰EÀ‹Eü‰EÈE”PEÀWPh&WWÿtãÿu‰EØPÿxã=  u6jÿÿuØÿ|ã‹Eüh<VƒÀPÿ`å‹EüƒÀPÿå‹MüƒÄÑà‰ëEğPÿuØÿ€ã…Àu	ÿüã‰EğÿuØÿÓë"h  ÿuôjÿuøèüÿÿƒÄ…Àu	ÿüã‰EğÿuøÿÓÿuèÿÓ9}ğt9}„y  é
  ·FP¡d	ÿØ   ÿvü‰E˜¡d	ÿØ   ‰Eœ¶FP¡d	ÿØ   ÿv‰E ¡d	ÿØ   ÿµdÿÿÿ‰E¤¡d	ÿØ   ÿµhÿÿÿ‰E¨¡d	ÿØ   ÿu‰E¬¡d	ÿuŒÿ¨  ‰E°ƒÄ ¶;Eàu‹Eü‹ÑéƒÀQPë‹Eô·ÑéQÿp¡d	ÿğ  ‰E´Y¶YP¡d	ÿØ   ‰E¸‹Eì·ÑéQÿp¡d	ÿğ  ‰E¼¡d	M˜Qj
¸¸   ÿÜ   PÿuäÿuÿƒÄ 3ÿÿEÜƒÆ‹EÜ;EĞŒ	ıÿÿÿuä¡d	ÿuÿ´  YYÿuÔÿåY‹Ç[_^ÉÃWhVëWhèUÿu¡d	ÿ¨  ƒÄWÿüãPÿuèZ¢şÿƒÄë#¡d	WhÀUÿuÿ¨  Wÿuğÿuè5¢şÿƒÄ9}ät	ÿuäè6¯şÿY9}ìt
ÿuìÿåY9}ôt
ÿuôÿåY9}üt
ÿuüÿåYj_éUÿÿÿU‹ìEW‹}Pÿu¡d	Wÿd  ƒÄ…ÀuPhpVë,MQ‹M÷ÙÉƒáAAQP¡d	ÿl  ƒÄƒøuj hPV¡d	Wÿ¨  ƒÄjXë&¡d	Vj ÿ5¤°´  ÿuèÕãşÿPWÿƒÄ3À^_]ÃU‹ìƒìV‹uj h€VVÿuÿuè_   ƒÄƒøtjEÿ5¤Pÿvÿuèé¥şÿƒÄ…ÀtjXë1ÿuèR±şÿPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒì8ƒeø ƒeğ S‹]VW€; „C  ‹E}ƒÀ‰EŠ<:„-  <;„%  <|uÇEğ   C‹EH9Eø–  ‹wƒÇ…ö‰}ü„ê  ¡ åƒ8~¾jPÿåYYë‹å¾‹	ŠAƒà…Àt‹Ej ÿ0¡d	ÿ¬   PèT  ƒÄ…Àu‹E‹ ¾ƒùbA„Ä   ƒùI%ƒùH¶   ƒéB„­   I„’   ItGIItCé_  ƒéL„‘   ƒééå   ƒùlÙ   t~ƒùcteƒùdtƒùftƒùg+  ƒùi~aé!  MèQPÿu¡d	ÿ”   ƒÄ…À…B  Š<ft<Ft<dt<D…í   İEèİéã   İEèÙéÙ   j P¡d	ÿ¬   Š YYëGMôQPÿu¡d	ÿ    ƒÄ…À…æ   Š<it0<It,<lt(<Lt$<ht<Ht<bt<B…   ŠEôˆëzf‹Eôf‰ëq‹Eôëjƒéot`ItBƒéu_€{#{u ƒEü‹Müÿ1P¡d	ÿ¬   Y‰Y‹ß‹}üë6j P¡d	ÿ¬   Y‰YëçƒÇjÿ7VPÿuèk£şÿƒÄƒøtHë‹E‹ ‰ƒECÿEø€; …Éıÿÿ€;;„   ‹EH;Eøƒ   j hÄVÿu¡d	ÿ¨  ƒÄ‹Eø@PEÈhÀVPÿüä‹5ìäj:ÿuÿÖƒÄ…Àuj;ÿuÿÖY…ÀYu¸œMÈj Qh´VP¡d	ÿuÿ   ƒÄjXëƒ}ğ u	j h¤Vë„3À_^[ÉÃƒ=D t*ÿt$høÿ$Y…ÀYt‹@Ãÿt$hÔVÿÀäYY3ÀÃU‹ìV‹uW‹}j häVVÿuWè®üÿÿƒÄƒøtFEP¡d	ÿvWÿ¤   ƒÄ…Àu,ÿuè¯­şÿ…ÀYu$¡d	Wÿl  Yj ÿüãPWèDşÿƒÄjXë#‹d	j ÿ5¤±´  PèßşÿPWÿƒÄ3À_^]ÃU‹ìEPhWÿuÿuÿuèüÿÿƒÄƒøu]ÃV¡d	j ÿ5<°´  ÿuÿuè   PÿuÿƒÄ3À^]ÃU‹ìƒì SVW‹}3öVWÿuèßşÿƒÄ9w‰E„   9u„”   VP¡d	ÿ¬   MàQPÿu¡d	ÿ„  ‹]ƒÄ…Àt;Ştfjÿ$åÿu‹ğ¡d	ÿP|Y‰ÿ ‹EY‰F‹Ghú< VhH= ‰F‰^¡d	j ÿu¸ˆ  ÿ¬   YYPÿuÿƒÄ‰F…Ût	ÿuèˆ şÿY‹E_^[ÉÃU‹ìEWPh4WÿuÿuÿuèüúÿÿƒÄƒøt"ÿuèSšşÿ‹øY…ÿuPÿüãPÿuè¶›şÿƒÄjXë(¡d	VjÿW°´  ÿğ  PÿuÿWÿåƒÄ3À^_]ÃU‹ìQEüÇEüœPEPhdWÿuÿuÿuè|úÿÿƒÄƒøuÉÃÿuüÿuÿuèşÿƒÄÉÃU‹ìQEV‹uPj ƒeü h˜WVÿuÿuè<úÿÿƒÄƒøtjEüj PÿvÿuèÊŸşÿƒÄ…ÀtjXëÿuÿuüÿuè‡¨şÿƒÄ^ÉÃU‹ìQEV‹uPEƒeü Pj hÄWVÿuÿuèÚùÿÿƒÄƒøtjEüj PÿvÿuèhŸşÿƒÄ…ÀtjXëÿuÿuÿuüÿuèM¨şÿƒÄ^ÉÃU‹ìQQEüV‹uPEƒeø Pj ƒMüÿhøWVÿuÿuèpùÿÿƒÄƒøtjEøj PÿvÿuèşşÿƒÄ…ÀtjXëÿuüÿuÿuøÿuè¨şÿƒÄ^ÉÃU‹ìQQEüV‹uPEƒeø Pj ƒMüÿh8XVÿuÿuèùÿÿƒÄƒøtjEøj Pÿvÿuè”şÿƒÄ…ÀtjXëÿuüÿuÿuøÿuè×§şÿƒÄ^ÉÃU‹ìQQEV‹uPEƒeü PEøPj h|XVÿuÿuèœøÿÿƒÄ ƒøtjEüj Pÿvÿuè*şÿƒÄ…ÀtjXëÿuÿuÿuøÿuüÿuè¥§şÿƒÄ^ÉÃU‹ìQQV‹uEj PEøPj ƒeü h¸XVÿuÿuè1øÿÿƒÄ ƒøtjEüj Pÿvÿuè¿şÿƒÄ…ÀtjXë*EP¡d	ÿvÿŒ   Pÿuÿuÿuøÿuüÿuèy§şÿƒÄ ^ÉÃU‹ìƒìEüVPE‹uPEƒeø PEôPj ƒMüÿh YVÿuÿuè¨÷ÿÿƒÄ$ƒøtjEøj Pÿvÿuè6şÿƒÄ…ÀtjXëÿuüÿuÿuÿuôÿuøÿuè_§şÿƒÄ^ÉÃU‹ìQQEüV‹uPEj PEPj ƒeø ƒMüÿhTYVÿuÿuè2÷ÿÿƒÄ$ƒøtjEøj PÿvÿuèÀœşÿƒÄ…ÀtjXë&ÿv¡d	ÿ   ÿuüPÿuÿuÿuøÿuè^§şÿƒÄ^ÉÃU‹ìEWPE‹}Ph¬YÿuÿuWèÂöÿÿƒÄƒøt/ÿuÿuÿ`ã…Àu$¡d	Wÿl  Yj ÿüãPWèo—şÿƒÄjXë%‹d	Vj ÿ5È±´  Pè·ÙşÿPWÿƒÄ3À^_]ÃU‹ìV‹uEWPE‹}Pj hÔYVÿuWè:öÿÿƒÄƒøtNjEÿ5ÈPÿvWèÆ›şÿƒÄ…Àu2ÿuÿuÿuÿ\ã…Àu$¡d	Wÿl  Yj ÿüãPWèÈ–şÿƒÄjXë#‹d	j ÿ5È±´  PèÙşÿPWÿƒÄ3À_^]ÃU‹ìV‹uj hZVÿuÿuèõÿÿƒÄƒøt9jEÿ5ÈPÿvÿuè(›şÿƒÄ…Àuÿuè~¦şÿ…ÀYtj PÿuèA–şÿƒÄjXë3À^]ÃU‹ìV‹uW‹}j h ZVÿuWè7õÿÿƒÄƒøtjEÿ5ÈPÿvWèÃšşÿƒÄ…ÀtjXë-ÿuÿXã‹d	j ÿ5<±´  PWèùÿÿPWÿƒÄ3À_^]ÃU‹ìV‹uj h<ZVÿuÿuèÃôÿÿƒÄƒøt9jEÿ5ÈPÿvÿuèMšşÿƒÄ…Àuÿuè‹¥şÿ…ÀYtj Pÿuèf•şÿƒÄjXë3À^]ÃU‹ìV‹uj hXZVÿuÿuè^ôÿÿƒÄƒøtjEÿ5ÈPÿvÿuèè™şÿƒÄ…ÀtjXë'ÿuÿTã‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìQV‹uj ƒeü htZVÿuÿuèêóÿÿƒÄƒøt0jEüj Pÿvÿuèx™şÿƒÄ…Àuÿuüÿhã…Àuÿuè¢şÿYjXë3À^ÉÃU‹ìQSV‹uW‹]3ÿWhŒZV‰}üÿuSè†óÿÿƒÄƒøt:jEüWPÿvSè™şÿƒÄ…Àu#9}üu#¡d	Sÿl  YWÿüãPSè(”şÿƒÄjXë#¡d	Wÿ5¤°´  ÿuüèqÖşÿPSÿƒÄ3À_^[ÉÃU‹ìQEüÇEüœPEPh¤ZÿuÿuÿuèñòÿÿƒÄƒøuÉÃEPÿuÿuüÿuèœ‚şÿƒÄ…Àu(¡d	Vj ÿ5<°´  ÿuèşÕşÿPÿuÿƒÄ3À^ÉÃU‹ìQV‹uj ƒeü hĞZVÿuÿuè…òÿÿƒÄƒøtjEüj Pÿvÿuè˜şÿƒÄ…ÀtjXëƒ}ü t
ÿuüÿåY3À^ÉÃU‹ìV‹uEW‹}Pj hèZVÿuWè)òÿÿƒÄƒøt7jEÿ5¤PÿvWèµ—şÿƒÄ…ÀuEPÿuÿuÿôà…ÀuWèN şÿYjXë5¡d	j ÿ5¤°¸   ÿuèÕşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^]ÃU‹ìQV‹uEWPE‹}Pj h [VÿuWè‡ñÿÿƒÄƒøt:jEÿ5¤PÿvWè—şÿƒÄ…ÀuEüPÿuÿuÿuÿğà…ÀuWè©ŸşÿYjXë5¡d	j ÿ5¤°¸   ÿuüèqÔşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìV‹uj hd[VÿuÿuèíğÿÿƒÄƒøtEPÿvÿuè¢şÿƒÄ…Àtƒ} t
ÿuÿåYjXëÿuÿuèŠ‡şÿYY^]ÃV‹t$j j hˆ[Vÿt$ ÿt$ èğÿÿƒÄƒøu^Ã¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   PWÿt$ è	£şÿƒÄ_^ÃU‹ìV‹uWj j hÀ[Vÿuÿuè7ğÿÿƒÄƒøt&ÿv¡d	ÿ   ‹øEPÿvÿuè@¡şÿƒÄ…Àtƒ} t
ÿuÿåYjXëÿuWÿuè   ƒÄ_^]ÃU‹ìƒì$SVW3À}Ü3ö«««Eì‹=ìàPEôPEğVPVÇEè   ÿu‰uü‰uô‰uøÿu‰uğÿ×…Àu7ÿüã‹Ø;Şt+ƒûzt&¡d	Vhğ[ÿuÿ¨  VSÿuèMşÿƒÄéÙ   ‹]EüP‹EôÀPVSèşÿƒÄ…À…º   EøP‹EğÀPVSèû~şÿƒÄ…À…   EìPEôPEğÿuüPÿuøÿuÿuÿ×…Àu(¡d	Vhğ[Sÿ¨  ƒÄVÿüãPSèÉşÿƒÄëX¡d	jÿÿuøÿğ  jÿ‰EÜÿuü¡d	ÿğ  ÿuì‰Eà¡d	ÿØ   ‰Eä¡d	MÜQj¸´  ÿÜ   PSÿƒÄ$‰uè9uü‹=åtÿuüÿ×Y9uøtÿuøÿ×Y‹Eè_^[ÉÃU‹ìEV‹uPj h\VÿuÿuèIîÿÿƒÄƒøtjEÿ5¤PÿvÿuèÓ“şÿƒÄ…ÀtjXëÿuÿuÿuèD£şÿƒÄ^]ÃU‹ìV‹uW‹}j j hD\VÿuWèìíÿÿƒÄƒøtHjEÿ5¤PÿvWèx“şÿƒÄ…Àu,EPÿvWèëşÿƒÄ…Àuÿuÿuè8¨şÿY…ÀYuWè œşÿYƒ} t
ÿuÿåYjXëƒ} t
ÿuÿåY3À_^]ÃU‹ìV‹uW‹}j j hx\VÿuWèSíÿÿƒÄƒøtHjEÿ5¤PÿvWèß’şÿƒÄ…Àu,EPÿvWèRşÿƒÄ…ÀuÿuÿuèÁ§şÿY…ÀYuWèg›şÿYƒ} t
ÿuÿåYjXëƒ} t
ÿuÿåY3À_^]ÃU‹ìƒìVW3ÿEø‹uWPWEôWPWWWh¤\Vÿuÿuè¬ìÿÿƒÄ0ƒøuéÆ   E‰}P¡d	ÿvÿĞ  9}YY‰Eüu‰}üÿv¡d	ÿ   ÿv‰Eì¡d	ÿ   ‰EğEP¡d	ÿv‰}ÿĞ  ƒÄ9}‰Eu‰}ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿv ÿĞ  9}YYu3ÀPÿuøSÿuÿuôÿuğÿuìÿuüÿuèš©şÿƒÄ$[_^ÉÃU‹ìV‹uW3ÿWWh ]Vÿuÿuè¸ëÿÿƒÄƒøtIESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSè_  ;Ç[tWPÿuèKŒşÿƒÄjXë3À_^]ÃU‹ìEV‹uPj h,]Vÿuÿuè>ëÿÿƒÄƒøuë/ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuPÿuèJ§şÿƒÄ^]ÃU‹ìV‹uj h\]VÿuÿuèèêÿÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuè.§şÿYY^]ÃU‹ìV‹uj h€]Vÿuÿuè–êÿÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuè§şÿYY^]ÃU‹ìV‹uj j h¨]VÿuÿuèBêÿÿƒÄƒøuë?ƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   PSÿuèà¦şÿƒÄ[^]ÃU‹ìEV‹uPj j hÜ]VÿuÿuèÖéÿÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuè¦¦şÿƒÄ[^]ÃU‹ìV‹uj j h^VÿuÿuèkéÿÿƒÄƒøuë?ƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   PSÿuèu¦şÿƒÄ[^]ÃU‹ìV‹uj j hX^VÿuÿuèéÿÿƒÄƒøuë?ƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   PSÿuèD¦şÿƒÄ[^]ÃU‹ìEV‹uPj j hŒ^Vÿuÿuè—èÿÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuèâ±şÿƒÄ[^]ÃU‹ìEV‹uPj j hÀ^Vÿuÿuè(èÿÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuè8³şÿƒÄ[^]ÃU‹ìEV‹uPj j hø^Vÿuÿuè¹çÿÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuèä²şÿƒÄ[^]ÃU‹ìV‹uW3ÿWWWh4_VÿuÿuèLçÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuè§°şÿƒÄ;Ç[tWPÿuèÈ‡şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWht_Vÿuÿuè»æÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuè4°şÿƒÄ;Ç[tWPÿuè7‡şÿƒÄjXë3À_^]ÃU‹ìV‹uWE3ÿPWWh¼_Vÿuÿuè'æÿÿƒÄƒøtNESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuPSèÓ¯şÿƒÄ;Ç[tWPÿuèµ†şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhü_Vÿuÿuè¨åÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuèc¯şÿƒÄ;Ç[tWPÿuè$†şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhD`VÿuÿuèåÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuèó®şÿƒÄ;Ç[tWPÿuè“…şÿƒÄjXë3À_^]ÃU‹ìV‹uWE3ÿPWWhˆ`VÿuÿuèƒäÿÿƒÄƒøtNESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuPSè’®şÿƒÄ;Ç[tWPÿuè…şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhÈ`VÿuÿuèäÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuè"®şÿƒÄ;Ç[tWPÿuè€„şÿƒÄjXë3À_^]ÃU‹ìV‹uWE3ÿPWWhaVÿuÿuèpãÿÿƒÄƒøtNESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuPSèÁ­şÿƒÄ;Ç[tWPÿuèşƒşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWh`aVÿuÿuèñâÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuèQ­şÿƒÄ;Ç[tWPÿuèmƒşÿƒÄjXë3À_^]ÃU‹ìV‹uWE3ÿPWWh¨aVÿuÿuè]âÿÿƒÄƒøtNESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuPSèğ¬şÿƒÄ;Ç[tWPÿuèë‚şÿƒÄjXë3À_^]ÃU‹ìV‹uWE3ÿPWWhøaVÿuÿuèÛáÿÿƒÄƒøtNESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuPSè¬şÿƒÄ;Ç[tWPÿuèi‚şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhHbVÿuÿuè\áÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuè¬şÿƒÄ;Ç[tWPÿuèØşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhŒbVÿuÿuèËàÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuè¯«şÿƒÄ;Ç[tWPÿuèGşÿƒÄjXë3À_^]ÃU‹ìì  V‹uW‹}j j hàbVÿuWè4àÿÿƒÄƒøtKÿv¡d	ÿ   ‰EEøPÿvWè^   ƒÄ…Àu&…øıÿÿh   PEøPÿuèÂšşÿƒÄ…ÀuWèEşÿYjXë(¡d	fƒeö øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ì¡d	SVWÿuÿX  ‹ğVèD YƒøYuC€~-u=‹=ĞäEjPVÿ×‹]ƒÄ‰CF9EuEjPF	Pÿ×‰FƒÄ9Eu3Àë13ÿ9}t'¡d	Wh(cÿuÿ¨  ¡d	WVÿuÿ   ƒÄjX_^[]ÃU‹ìì   V‹uj j h@cVÿuÿuèòŞÿÿƒÄƒøtC¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ    şÿÿh   QPSè£™şÿƒÄ…À[uÿuèşÿYjXë*¡d	fƒeş  şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìQQV‹uj j h”cVÿuÿuèWŞÿÿƒÄƒøtLƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   YMøQPSÿèà…À[uÿuègŒşÿYjXë¡d	°´  EøPèÇ–şÿPÿuÿƒÄ3À^ÉÃU‹ìV‹uj hÌcVÿuÿuèÂİÿÿƒÄƒøtEPÿvÿuèÛşÿƒÄ…Àtƒ} t
ÿuÿåYjXë7ÿuÿà‹d	P±´  ÿ‘Ø   PÿuÿƒÄƒ} t
ÿuÿåY3À^]ÃU‹ìQV‹uEW‹}Pj ƒeü j hècVÿuWè.İÿÿƒÄƒøtPjEÿ5¤PÿvWèº‚şÿƒÄ…Àu4EüPÿvWè{   ƒÄ…Àu EPÿuÿuüÿuè~‘şÿƒÄ…ÀuWè:‹şÿYj^ë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3öÿuüè   Y‹Æ_^ÉÃƒ|$ tÿt$ÿåYÃU‹ìQEüVPEP¡d	ÿuÿuÿ¼   ƒÄ…ÀuU‹uVÿuÿuèP   ƒÄ…Àu?‹‹M‰‹E‹ÈH…É‰Et1‹@LŠQ‹Müÿ4ÿuèS   ƒÄƒøuÓÿ6èwÿÿÿƒ& YjX^ÉÃ3ÀëùV‹t$W‹|$vW…   Pj ÿt$è¤kşÿƒÄ…ÀtjXë‹‰03À_^ÃU‹ìQVEW‹}PEüP¡d	ÿuWÿ¼   ƒÄ…Àu`ƒ}üu3‹uFP‹Eÿp¡d	Wÿ¤   ƒÄ…Àu‹EVÿ0Wè¿ûÿÿƒÄ…Àt*…ÿt#¡d	j ÿu°   ÿX  YPh$dWÿƒÄjX_^ÉÃU‹ìQV‹u3ÀWM‹}PQPhDdV‰EüÿuWèÛÿÿƒÄƒøt0jEÿ5¤PÿvWè €şÿƒÄ…ÀuEüPÿvWèaşÿÿƒÄ…Àtÿuüè?şÿÿYjXëÿuüÿuÿuWèÆ•şÿƒÄ_^ÉÃU‹ìV‹uW3ÿWWWh„dVÿuÿuèšÚÿÿƒÄƒøtqE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ‹ØEP¡d	ÿv‰}ÿĞ  ƒÄ9}u3ÀPSÿuèæ¥şÿƒÄ;Ç[tWPÿuè{şÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWh¸dVÿuÿuèøÙÿÿƒÄƒøtqE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ‹ØEP¡d	ÿv‰}ÿĞ  ƒÄ9}u3ÀPSÿuèg¥şÿƒÄ;Ç[tWPÿuèczşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWhôdVÿuÿuèWÙÿÿƒÄƒøtIESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSè ;Ç[tWPÿuèêyşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWh eVÿuÿuèŞØÿÿƒÄƒøtIESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSè‘ ;Ç[tWPÿuèqyşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhPeVÿuÿuèdØÿÿƒÄƒøt_E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   YYPSÿuè ;Ç[tWPÿuèáxşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhŒeVÿuÿuèÔ×ÿÿƒÄƒøt_E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   YYPSÿuè} ;Ç[tWPÿuèQxşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhÈeVÿuÿuèD×ÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuèç¢şÿƒÄ;Ç[tWPÿuèÀwşÿƒÄjXë3À_^]ÃU‹ìV‹uW3ÿWWWhfVÿuÿuè³ÖÿÿƒÄƒøt`E‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   PSÿuèt¢şÿƒÄ;Ç[tWPÿuè/wşÿƒÄjXë3À_^]ÃhXfÿt$ÿt$ÿt$è*ÖÿÿƒÄƒøuÃÿt$èJ¢şÿYÃU‹ìQV‹uj ƒeü h„fVÿuÿuè÷ÕÿÿƒÄƒøtEüPÿvÿuèV   ƒÄ…Àtƒ}ü t
ÿuüÿåYjXë7ÿuüÿäà‹d	P±´  ÿ‘Ø   PÿuÿƒÄƒ}ü t
ÿuüÿåY3À^ÉÃU‹ìƒì‹ESVWÿu3ÿ‰8¡d	‰}øÿX  PhpèÈ ƒÄ…À„ı  Eì‹uPEğP¡d	ÿuVÿ¼   ƒÄ…À…ª  j[9]ğt";÷„š  ¡d	WhÀfVÿ¨  ƒÄé€  EèPEüP‹Eìÿp¡d	Vÿ¼   ƒÄ…À…H  ‹Eü‰]ô‹$å;ÇÇE   tbÁàPÿÓ;ÇY‰Eøtc3É9}ü~M‰8AƒÀ;Mü|õ9}ü~=‹uø‹EèVÿ4¸ÿuèB  ƒÄ…À…Ã   ‹·HM€8vÇEô   GƒÆ;}ü|È3ÿÿuÿÓY;Ç‹M‰u9}„   WhëVÿuôÿuPÿÜà9}ü~*‹uø‹·HQP‹Ejÿÿuôÿ0ÿàà…Àt8GƒÆ;}ü|Û3ÿ‹Eÿ0ÿäà…Àu|9}t5Wh fÿu¡d	ÿ¨  ƒÄëƒ} tj ÿüãPÿuè§tşÿƒÄ3ÿ‹uø;÷t#9}ü~ÿ6ÿåGƒÆ;}üY|î3ÿÿuøÿåY‹u‹;Çt
PÿåY‰>jXë+9}øt$‹5å3Û9}ü~‹}øÿ7ÿÖCƒÇ;]üY|òÿuøÿÖY3À_^[ÉÃU‹ìƒì‹ESV‹]ƒ  EWPEøP¡d	ÿuSÿ¼   ƒÄ…À…  ƒ}øŒ  EüP‹Eÿ0¡d	Sÿ    ƒÄ…À…Ş   EğP‹Eÿp¡d	Sÿ    ƒÄ…À…½   jÿØàƒ}ü ‹øŒº   ƒ}ü°   ƒ}ø…¬   ƒÇWÿ$å‹ğY…ö„Ñ   ŠEüˆŠEğˆFFf‰~P‹Eÿp¡d	Sÿ    ƒÄ…Àuk‹Eÿp¡d	ÿX  PèG„şÿ‹øY…ÿYtFWP·FƒèPÿà…ÀWu%ÿåY…Ûtj ÿüãPSè÷rşÿƒÄjX_^[ÉÃÿåYëgƒ}øt…Ûtåj hgë8EôP‹Eÿp¡d	ÿŒ   }ô‹ØWÿ$å‹ğƒÄ…öu‹]…Ût«j h¡d	Sÿ¨  ë“ÿuôSVÿåƒÄ‹E‰03Àë‚U‹ìQV‹uj ƒeü hgVÿuÿuèsÑÿÿƒÄƒøtEüPÿvÿuè  ƒÄ…Àtƒ}ü t	ÿuüè?   YjXë6ÿuüÿÔà‹d	P±´  ÿ‘Ø   PÿuÿƒÄƒ}ü t	ÿuüè   Y3À^ÉÃU‹ìƒìSW‹}3Û;û„¥   WÿÔà…À„–   EøVPEPWÿDá‹5å…Àt9]tÿuÿÖYEøPEPWÿHá…Àt9]tÿuÿÖYEøPEüPEôPWÿLá…Àt9]ôt9]ütÿuüÿÖYEøPEüPEôPWÿPá…Àt9]ôt9]ütÿuüÿÖYWÿÖY^_[ÉÃU‹ìƒìSV‹uE‹]WPEìP3ÿÿu‰>¡d	‰}øS‰}üÿ¼   ƒÄ…À…!  9}ì„  ƒ}ìt";ß„
  ¡d	WhtgSÿ¨  ƒÄéğ  jÿ$å;ÇY‰u;ß„©  WhëJjPÿTá…À„Z  EèP‹Eÿ0¡d	Sÿ    ƒÄ…À…p  ‹Eè·ø;øt#…Û„^  j hDg¡d	Sÿ¨  ƒÄéC  ¹ ?  f#ÁPQÿ6ÿÄà…À„ó   EğP‹Eÿp¡d	ÿ¬   ƒ}ğ ‹ÈàYYt'Pèşÿ…ÀY‰Eü„»   ‹ÇƒàPÿuüÿ6ÿÓ…À„¦   EğP‹Eÿp¡d	ÿ¬   ƒ}ğ YYtPèÑ€şÿ…ÀY‰Eøt{‹ÇƒàPÿuøÿ6ÿÓ…ÀtjEP‹Eÿpÿuè%ùÿÿƒÄ…Àuj‹ÇƒàP3À9Eÿu•ÀPÿ6ÿÌà…Àt3EôP‹EÿpÿuèîøÿÿƒÄ…Àu3ƒç 9EôWÿuô•ÀPÿ6ÿĞà…Àun‹]…Ûtj ÿüãPSè"oşÿƒÄƒ}ü t
ÿuüÿåYƒ}ø t
ÿuøÿåY3ÿ9}t
ÿuÿåY9}ôt
ÿuôÿåY‹;Çt
PÿåY‰>jXë3À_^[ÉÃU‹ìV‹uEWPE‹}Pj h¸gVÿuWè¾ÍÿÿƒÄƒøtUÿv¡d	ÿ   ÿuÿuPèŸşÿ‹ğƒÄ…öu ¡d	Wÿl  YVÿüãPWèYnşÿƒÄëEPVWèø™şÿƒÄ…ÀtjXëÿu¡d	Wÿ´  YYVÿ ä3À_^]ÃU‹ìƒìSV3ÛWS‹uSSESPEô‹}PShøgV‰]üÿu‰]øWèÍÿÿƒÄ,ƒø„‹   ÿv¡d	ÿ   ‰EğEPÿvWè~şÿƒÄ…ÀufEPÿvWèı}şÿƒÄ…ÀuREüPÿvWè/÷ÿÿƒÄ…Àu>EøPÿvWè÷ÿÿƒÄ…Àu*ÿuøÿuüÿuÿuÿuÿuôÿuğÿÀà;ÃtBSPWèXmşÿƒÄ9]‹5åtÿuÿÖY9]tÿuÿÖY9]ütÿuüÿÖY9]øtÿuøÿÖYjXë49]‹5åtÿuÿÖY9]tÿuÿÖY9]ütÿuüÿÖY9]øtÿuøÿÖY3À_^[ÉÃU‹ìQV‹uEWPE‹}Pj hHhVÿuWèßËÿÿƒÄƒøtejEÿ5¤PÿvWèkqşÿƒÄ…ÀuIÿuÿuÿuè^şÿ‹ğƒÄ…öu ¡d	Wÿl  YVÿüãPWèjlşÿƒÄëEüPVWè	˜şÿƒÄ…ÀtjXëÿuü¡d	Wÿ´  YYVÿ ä3À_^ÉÃU‹ìƒìSV3ÛWS‹uSSESPEô‹}PSh€hV‰]üÿu‰]øWèËÿÿƒÄ,ƒø„–   jEğÿ5¤PÿvWè¤pşÿƒÄ…ÀuzEPÿvWè|şÿƒÄ…ÀufEPÿvWè|şÿƒÄ…ÀuREüPÿvWè5õÿÿƒÄ…Àu>EøPÿvWè!õÿÿƒÄ…Àu*ÿuøÿuüÿuÿuÿuÿuôÿuğÿ¼à;ÃtBSPWè^kşÿƒÄ9]‹5åtÿuÿÖY9]tÿuÿÖY9]ütÿuüÿÖY9]øtÿuøÿÖYjXë49]‹5åtÿuÿÖY9]tÿuÿÖY9]ütÿuüÿÖY9]øtÿuøÿÖY3À_^[ÉÃU‹ìƒìVE‹uWPEü3ÿPWWWhÌhVÿuÿuèáÉÿÿƒÄ$ƒøte¡d	Sÿvÿ   ‰EøEP¡d	ÿv‰}ÿĞ  ƒÄ9}‹Øu3Ûÿv¡d	ÿ   YMôQÿuÿuüPSÿuøÿ¸à…À[uÿuèØwşÿYjXë8¡d	Wÿ5¤°¸   ÿuôè¡¬şÿƒÄP¡d	ÿuÿ   YPÿuÿƒÄ3À_^ÉÃU‹ìV‹uj h$iVÿuÿuèÉÿÿƒÄƒøt4jEÿ5¤Pÿvÿuè£nşÿƒÄ…Àuÿuÿ´à…ÀuÿuèAwşÿYjXë3À^]ÃhLiÿt$ÿt$ÿt$è½ÈÿÿƒÄƒøtÿ°à…Àuÿt$èwşÿYjXÃ3ÀÃU‹ìEPhdiÿuÿuÿuè€ÈÿÿƒÄƒøtÿuÿ¬à…ÀuÿuèÆvşÿYjX]Ã3À]ÃU‹ìV‹uW‹}j j h„iVÿuWè;ÈÿÿƒÄƒøtOjEÿ5¤PÿvWèÇmşÿƒÄ…Àu3jEÿ5¤PÿvWè«mşÿƒÄ…Àuÿuÿuÿ¨à…ÀuWèHvşÿYjXë3À_^]ÃU‹ìƒìSVEW‹uPE3ÛPE‹}SPSh¬iVÿu‰]üWè¨ÇÿÿƒÄ$ƒøtTjEøÿ5¤PÿvWè4mşÿƒÄ…Àu8EüPÿvWè¦   ƒÄ…Àu$EôPÿuÿuÿuüÿuÿuøÿ¤à…ÀuWè°uşÿY9]üt	ÿuüèM   YjXëB¡d	Sÿ5¤°¸   ÿuôèkªşÿƒÄP¡d	Wÿ   YPWÿƒÄ9]üt	ÿuüè   Y3À_^[ÉÃV‹t$…öt‹F…ÀtPèÔõÿÿYVÿåY^ÃU‹ìSE‹]V‹uPEƒ& Pÿu¡d	Sÿ¼   ƒÄ…À…¶   9E„²   ƒ}t"…Û„Ÿ   P¡d	hjSÿ¨  ƒÄé…   jÿ$å…ÀY‰u…ÛtaP¡d	hSÿ¨  ƒÄëJÇ    EP‹Eÿp¡d	Sÿ    ƒÄƒøt&‹3À9E•À‰A‹ƒÀP‹Eÿ0SèºõÿÿƒÄƒøu‹…ÀtPÿåƒ& YjXë3À^[]ÃU‹ìƒìEPhXjÿuÿuÿuèÃÅÿÿƒÄƒøt ÿuEğPè¿—şÿY…ÀYtj PÿuèfşÿƒÄjXÉÃ¡d	V°´  EğPèÒ[şÿPÿuÿƒÄ3À^ÉÃU‹ìƒìhxjÿuÿuÿuèZÅÿÿƒÄƒøtEğPÿ°æ…Àtj PÿuèfşÿƒÄjXÉÃ¡d	V°´  EğPèm[şÿPÿuÿƒÄ3À^ÉÃU‹ìQQhjÿuÿuÿuèöÄÿÿƒÄƒøtEøPÿ à…Àuÿuè;sşÿYjXÉÃ¡d	V°´  EøPèš}şÿPÿuÿƒÄ3À^ÉÃU‹ìEPEPh°jÿuÿuÿuè‘ÄÿÿƒÄƒøtÿuÿuÿtç…ÀuÿuèÔrşÿYjX]Ã3À]ÃhØjÿt$ÿt$ÿt$èQÄÿÿƒÄƒøtÿxç…Àuÿt$è™rşÿYjXÃ3ÀÃU‹ìì  EPhğjÿuÿuÿuèÄÿÿƒÄƒøt$…øıÿÿh  Pÿuèì•şÿƒÄ…ÀuÿuèFrşÿYjXÉÃ¡d	fƒeş VøıÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìì(  SVjEØj Pè_ü ‹uEğ‹]Pj h$kVÿuSè|ÃÿÿƒÄ$ƒøt~EüP¡d	ÿvÿĞ  YY‹Müù   s_L	QP…ØıÿÿPÿå‹EüÿuğÀf‰Eôf‰Eö…Øıÿÿ‰EøEØPEôPèG•şÿƒÄ…Àu$¡d	Sÿl  Yj ÿüãPSèÚcşÿƒÄjXë#‹d	j ÿ5¨±´  Pè#¦şÿPSÿƒÄ3À^[ÉÃU‹ìV‹uj h\kVÿuÿuè°ÂÿÿƒÄƒøtjEÿ5¨Pÿvÿuè:hşÿƒÄ…ÀtjXë&ÿuèkò ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uW‹}j j h|kVÿuWè>ÂÿÿƒÄƒøt0jEÿ5¨PÿvWèÊgşÿƒÄ…ÀuEPÿvWè=sşÿƒÄ…Àtƒ} t
ÿuÿåYjXëÿuÿuWèI”şÿƒÄ_^]ÃU‹ìì  V‹uj j hÀkVÿuÿuè¼ÁÿÿƒÄƒøt=jEÿ5¨PÿvÿuèFgşÿƒÄ…ÀuEP¡d	ÿvÿĞ  YY‹Mù   rjXë;L	QP…øıÿÿPÿå‹EÀf‰Eøf‰Eú…øıÿÿ‰EüEøPÿuÿuè]”şÿƒÄ^ÉÃU‹ìQSV‹u3ÛW‹}SSShlV‰]üÿuWèÁÿÿƒÄƒøtHjEÿ5¨PÿvWèœfşÿƒÄ…Àu,EPÿvWèrşÿƒÄ…ÀuEPEüPÿvWè5   ƒÄ…Àt9]t
ÿuÿåYjXëÿuÿuüÿuÿuWèŒ”şÿƒÄ_^[ÉÃU‹ìQQVEøWPEüP¡d	ÿuÿuÿ¼   ƒÄƒøt@‹Eü3ÿ‹ğÁæ…Àv‹Eøÿ4¸¡d	ÿø  GY;}ütFräEPVj ÿuèøOşÿƒÄ…ÀtjXëv‹Eü‹M3ÿ…À4ÁvXEP‹Eøÿ4¸¡d	ÿĞ  ‹ML	QPVÿå‹EƒÄ‰tø‹E‹MÀf‰ù‹Ef‹øøGf‰H‹EtF‹Eü;ør¨‹M‹U‰‹M‰3À_^ÉÃU‹ìQQSV‹u3ÛWES‹}PSShllV‰]üÿuWè‚¿ÿÿƒÄ ƒøtHjEøÿ5¨PÿvWèeşÿƒÄ…Àu,EPÿvWèpşÿƒÄ…ÀuEPEüPÿvWè§şÿÿƒÄ…Àt9]t
ÿuÿåYjXëÿuÿuüÿuÿuÿuøWèM“şÿƒÄ_^[ÉÃhÜlÿt$ÿt$ÿt$èë¾ÿÿƒÄƒøuÃÿt$èr“şÿYÃU‹ìQQV‹uj h mVÿuÿuè»¾ÿÿƒÄƒøtEøPÿvÿuèôŞÿÿƒÄ…ÀtjXëEøPÿuè³“şÿYY^ÉÃU‹ìEV‹uPj h(mVÿuÿuèi¾ÿÿƒÄƒøtjEÿ5¨PÿvÿuèócşÿƒÄ…ÀtjXëÿuÿuÿuè±–şÿƒÄ^]ÃU‹ìQEV‹uPj ƒeü hdmVÿuÿuè¾ÿÿƒÄƒøtjEüÿ5PPÿvÿuè‘cşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü h°mVÿuÿuè¬½ÿÿƒÄƒøtjEüÿ5PPÿvÿuè6cşÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hèmVÿuÿuè9½ÿÿƒÄƒøtjEüÿ5PPÿvÿuèÃbşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h,nVÿuÿuèİ¼ÿÿƒÄƒøtjEüÿ5PPÿvÿuègbşÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h`nVÿuÿuèi¼ÿÿƒÄƒøtjEüÿ5PPÿvÿuèóaşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h¤nVÿuÿuè¼ÿÿƒÄƒøtjEüÿ5PPÿvÿuè—aşÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hØnVÿuÿuè™»ÿÿƒÄƒøtjEüÿ5PPÿvÿuè#aşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü hoVÿuÿuè=»ÿÿƒÄƒøtjEüÿ5PPÿvÿuèÇ`şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hLoVÿuÿuèÉºÿÿƒÄƒøtjEüÿ5PPÿvÿuèS`şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü hŒoVÿuÿuèmºÿÿƒÄƒøtjEüÿ5PPÿvÿuè÷_şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü h¼oVÿuÿuèû¹ÿÿƒÄƒøt<jEüÿ5PPÿvÿuè…_şÿƒÄ…ÀujEÿ5¼Pÿvÿuèg_şÿƒÄ…ÀtjXë‹EüH3À‹Uf‹f‰@@=   |ì3À^ÉÃU‹ìQV‹uW‹}ƒeü j hüoVÿuWèp¹ÿÿƒÄƒøtjEüÿ5PPÿvWèü^şÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5¼±´  PWèC½ÿÿPWÿƒÄ3À_^ÉÃU‹ìQEV‹uPj ƒeü h,pVÿuÿuèö¸ÿÿƒÄƒøtjEüÿ5PPÿvÿuè€^şÿƒÄ…ÀtjXë‹Eü…Àtf‹Mf‰ˆ  3À^ÉÃU‹ìQV‹uj ƒeü htpVÿuÿuè•¸ÿÿƒÄƒøtjEüÿ5PPÿvÿuè^şÿƒÄ…ÀtjXë*‹Eüf‹ˆ  ¡d	·ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h¬pVÿuÿuè¸ÿÿƒÄƒøtjEüÿ5PPÿvÿuè¤]şÿƒÄ…ÀtjXë‹Eü…Àtf‹Mf‰ˆ  3À^ÉÃU‹ìQV‹uj ƒeü hôpVÿuÿuè¹·ÿÿƒÄƒøtjEüÿ5PPÿvÿuèC]şÿƒÄ…ÀtjXë*‹Eüf‹ˆ  ¡d	·ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h,qVÿuÿuè>·ÿÿƒÄƒøtjEüÿ5PPÿvÿuèÈ\şÿƒÄ…ÀtjXë‹Eü…Àtf‹Mf‰ˆ  3À^ÉÃU‹ìQV‹uj ƒeü hhqVÿuÿuèİ¶ÿÿƒÄƒøtjEüÿ5PPÿvÿuèg\şÿƒÄ…ÀtjXë*‹Eüf‹ˆ  ¡d	·ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h˜qVÿuÿuèb¶ÿÿƒÄƒøtjEüÿ5PPÿvÿuèì[şÿƒÄ…ÀtjXë‹Eü…Àt	ŠMˆˆ  3À^ÉÃU‹ìQV‹uj ƒeü hØqVÿuÿuè¶ÿÿƒÄƒøtjEüÿ5PPÿvÿuè[şÿƒÄ…ÀtjXë)‹EüŠˆ  ¡d	¶ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hrVÿuÿuè‰µÿÿƒÄƒøtjEüÿ5PPÿvÿuè[şÿƒÄ…ÀtjXë‹Eü…Àt	ŠMˆˆ  3À^ÉÃU‹ìQV‹uj ƒeü h@rVÿuÿuè*µÿÿƒÄƒøtjEüÿ5PPÿvÿuè´ZşÿƒÄ…ÀtjXë)‹EüŠˆ  ¡d	¶ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìhprÿuÿuÿuè½´ÿÿƒÄƒøu]ÃVh  jÿÌä‹d	j ÿ5P±´  Pÿuè¥¸ÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü hrVÿuÿuè[´ÿÿƒÄƒøtjEüÿ5PPÿvÿuèåYşÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQV‹uj ƒeü h¸rVÿuÿuèö³ÿÿƒÄƒøt4jEüÿ5PPÿvÿuè€YşÿƒÄ…Àuÿuüè şÿ…ÀYuÿuèbşÿYjXë3À^ÉÃU‹ìì   härÿuÿuÿuè”³ÿÿƒÄƒøt … şÿÿh   PèşÿY…ÀYuÿuèĞaşÿYjXÉÃ¡d	fƒeş V şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìì   EPhsÿuÿuÿuè³ÿÿƒÄƒøt$… şÿÿh   Pÿuè¢ŒşÿƒÄ…ÀuÿuèQaşÿYjXÉÃ¡d	fƒeş V şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìQQVEWP‹uEüPEø3ÿPWWhHsVÿuÿuè²ÿÿƒÄ$ƒøt^ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿvÿĞ  9}YYu3ÀÿuÿuüÿuøPSÿ˜à…À[uÿuè`şÿYjXë3À_^ÉÃU‹ìV‹uj h´sVÿuÿuè²ÿÿƒÄƒøt4ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿ”à…Àuÿuè,`şÿYjXë3À^]ÃU‹ìS‹]VEWPh   j SèkAşÿƒÄ…ÀuR‹}‹uPhàsWÿuSè‡±ÿÿƒÄƒøt(ÿw¡d	ÿ   Ç$ €  VPÿPã…ÀuSè»_şÿY…ötVÿåYjXë1fƒ¦şÿ   ¡d	jÿV¸´  ÿğ  PSÿƒÄ…ötVÿåY3À_^[]ÃU‹ìƒìSVW3ÿEô‹uWPEğ‰}üPEèWPhtVÿuÿuèà°ÿÿƒÄ$ƒøthjEÿ5ôPÿvÿuèjVşÿƒÄ…ÀuJ‹E‹ ‰EìEøPEP¡d	ÿvÿuÿ¼   ƒÄƒøt!‹EMü‹ØQ…   PWÿuè>@şÿƒÄ…Àt9}üt
ÿuüÿåYjXëF3ö;ßv‹EøWÿ4°¡d	ÿĞ  YY‹Mü‰±F;órá‹Eü‰<°ÿuüSÿuôÿuğÿuìÿuèÿuè2‹şÿƒÄ_^[ÉÃU‹ìƒìSV‹uW3ÿEôWWPhttV‰}üÿuÿuèé¯ÿÿƒÄƒøtSÿv¡d	ÿ   ‰EøEPEP¡d	ÿvÿuÿ¼   ƒÄƒøt!‹EMü‹ØQ…   PWÿuè\?şÿƒÄ…Àt9}üt
ÿuüÿåYjXë@3ö;ßv‹EWÿ4°¡d	ÿĞ  YY‹Mü‰±F;órá‹Eü‰<°ÿuüSÿuøÿuôÿuèöˆşÿƒÄ_^[ÉÃU‹ìEV‹uPj h´tVÿuÿuè¯ÿÿƒÄƒøuë^¡d	Wÿvÿ   Yÿuj Pÿøãj‰Eÿ$å‹øEjPWÿå¡d	jÿ5ô°´  WÿuèØ²ÿÿPÿuÿƒÄ(3À_^]ÃU‹ìV‹uj hàtVÿuÿuè’®ÿÿƒÄƒøt6jEÿ5ôPÿvÿuèTşÿƒÄ…Àu‹Eÿ0ÿä…Àuÿuè¸\şÿYjXë3À^]Ãh uÿt$ÿt$ÿt$è4®ÿÿƒÄƒøuÃÿt$èt‰şÿYÃU‹ì3ÀV‹uMPQPPhuVÿuÿuèÿ­ÿÿƒÄ ƒøuë_¡d	SWÿvÿ   ÿv‹ø¡d	ÿ   ÿv‹Ø¡d	ÿ   ƒÄPÿuSWÿLã‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À_[^]ÃU‹ìEV‹uPj j hduVÿuÿuès­ÿÿƒÄƒøuëK¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   YYÿuPWÿHã‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À_^]ÃU‹ìQQSVEüWP3Ûh   SÿuèÆ<şÿƒÄ…Àu/‹uSSSS‹}ühœuVÿuÿuèİ¬ÿÿƒÄ ƒøu;ûtWÿåYjXé¥   ÿv¡d	ÿ   ÿv‰Eø¡d	ÿ   ÿv‰E¡d	ÿ   ÿv‰E¡d	ÿ   ƒÄPh €  WÿuÿuÿuøÿDã‹d	P±´  ÿ‘Ø   Pÿuÿf‰Ÿşÿ  ¡d	jÿW°´  ÿğ  PÿuÿƒÄ;ûtWÿåY3À_^[ÉÃU‹ìS‹]VEWP3öh   VSèÃ;şÿƒÄ…Àu,VVV‹u‹}hüuVÿuSèİ«ÿÿƒÄƒøu…ÿtWÿåYjXé   ÿv¡d	ÿ   ÿv‰E¡d	ÿ   ÿv‰E¡d	ÿ   ƒÄh €  WPÿuÿuÿ@ã‹d	P±´  ÿ‘Ø   PSÿfƒ§şÿ   ¡d	jÿW°´  ÿğ  PSÿƒÄ…ÿtWÿåY3À_^[]ÃU‹ìQ3ÀV‹uPPPPhLvVÿuÿuè«ÿÿƒÄ ƒø„Š   ¡d	SWÿvÿ   ÿv‰Eü¡d	ÿ   ‹=Üä»,$SP‰Eÿ×ƒÄ…Àu!Eÿv¡d	ÿ   SP‰Eÿ×ƒÄ…À_[u!Eÿv¡d	ÿ   YPÿuÿuÿuüÿ<ã…ÀuÿuèİXşÿYjXë3À^ÉÃU‹ì3ÀS‹]PPPhœvSÿuÿuèRªÿÿƒÄƒø„„   ¡d	VWÿsÿ   ‹5Üä¿,$WP‰EÿÖƒÄ…Àu!Eÿs¡d	ÿ   WP‰EÿÖƒÄ…Àu!Eÿs¡d	ÿ   ‹ØWSÿÖƒÄ…À_^u3ÛSÿuÿuÿ8ã…Àuÿuè&XşÿYjXë3À[]ÃU‹ìV‹uj j hØvVÿuÿuèœ©ÿÿƒÄƒøuë@¡d	Sÿvÿ   ƒe ‹ØEP¡d	ÿvÿĞ  ƒÄƒ} u3ÀPSÿuè‡şÿƒÄ[^]ÃU‹ìV‹uj hwVÿuÿuè5©ÿÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuèÙ†şÿYY^]ÃhDwÿt$ÿt$ÿt$èç¨ÿÿƒÄƒøuÃÿt$è…şÿYÃU‹ìQQEV‹uPEj PEøPƒeü h`wVÿuÿuè§¨ÿÿƒÄ ƒøt9jEüj Pÿvÿuè5NşÿƒÄ…Àuÿuÿuüÿuÿuøÿ|ç…ÀuÿuèÊVşÿYjXë3À^ÉÃh¤wÿt$ÿt$ÿt$èF¨ÿÿƒÄƒøuÃÿt$è†şÿYÃhÈwÿt$ÿt$ÿt$è¨ÿÿƒÄƒøuÃÿt$èØˆşÿYÃU‹ìQV‹uW3ÿWEWPWhğwVÿuÿuèå§ÿÿƒÄ ƒøtjEüÿ5¤PÿvÿuèoMşÿƒÄ…ÀtjXëD¡d	Sÿvÿ   ‹ØEP¡d	ÿv‰}ÿĞ  ƒÄ9}u3ÀPSÿuÿuüÿuèLŠşÿƒÄ[_^ÉÃU‹ìV‹uW‹}j j h4xVÿuWèT§ÿÿƒÄƒøtOjEÿ5¤PÿvWèàLşÿƒÄ…Àu3jEÿ5¤PÿvWèÄLşÿƒÄ…ÀuÿuÿuÿLé…ÀuWèaUşÿYjXë3À_^]ÃU‹ìW‹}h`xÿuÿuWèÚ¦ÿÿƒÄƒøtEPÿPé…ÀuWè!UşÿYjXë/¡d	VÿuÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À^_]ÃU‹ìQQhxxÿuÿuÿuèn¦ÿÿƒÄƒøuÉÃEøVPÿ4ã¡d	°´  EøPè#:şÿPÿuÿƒÄ3À^ÉÃh˜xÿt$ÿt$ÿt$è!¦ÿÿƒÄƒøuÃVÿ0ã‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìƒìV‹uW‹}j h°xVÿuWèÑ¥ÿÿƒÄƒøt-EøPÿvWè±9şÿƒÄ…ÀuEèPEøPÿ,ã…ÀuWè TşÿYjXë¡d	°´  EèPè"7şÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}j hÜxVÿuWèW¥ÿÿƒÄƒøt-EèPÿvWè†7şÿƒÄ…ÀuEøPEèPÿ(ã…ÀuWè†SşÿYjXë¡d	°´  EøPèç8şÿPWÿƒÄ3À_^ÉÃU‹ìEPhyÿuÿuÿuèâ¤ÿÿƒÄƒøtÿuèÈˆşÿ„ÀYuÿuè(SşÿYjX]Ã3À]ÃU‹ìƒìhDyÿuÿuÿuè¢¤ÿÿƒÄƒøtEPèáˆşÿ„ÀYuÿuèçRşÿYjXÉÃÿuEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìV‹uj hlyVÿuÿuè7¤ÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuè³ˆşÿ„ÀYuÿuèaRşÿYjXë3À^]ÃU‹ìEWPEPE‹}Ph˜yÿuÿuWèÏ£ÿÿƒÄƒøt2ÿuÿuÿuÿlã…Àu$¡d	Wÿl  Yj ÿüãPWèyDşÿƒÄjXë%‹d	Vj ÿ5¤±´  PèÁ†şÿPWÿƒÄ3À^_]ÃW‹|$hÜyÿt$ÿt$WèP£ÿÿƒÄƒøt)ÿdã…Àu$¡d	Wÿl  Yj ÿüãPWèDşÿƒÄjX_Ã‹d	Vj ÿ5¤±´  PèK†şÿPWÿƒÄ3À^_ÃU‹ìEV‹uPj høyVÿuÿuèÕ¢ÿÿƒÄƒøt7jEÿ5¤Pÿvÿuè_HşÿƒÄ…Àuÿuÿuÿ$ã…ÀuÿuèúPşÿYjXë3À^]ÃU‹ìì  V‹uW‹}j j h(zVÿuWèh¢ÿÿƒÄƒøtXjEÿ5¤PÿvWèôGşÿƒÄ…Àu<EP¡d	ÿvWÿ¤   ƒÄ…Àu"…øıÿÿh  PÿuÿuèÖ …ÀuWèlPşÿYjXë(¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìì  V‹uW‹}j j hlzVÿuWè³¡ÿÿƒÄƒøtXjEÿ5¤PÿvWè?GşÿƒÄ…Àu<EP¡d	ÿvWÿ¤   ƒÄ…Àu"…øıÿÿh  Pÿuÿuè`Õ …ÀuWè·OşÿYjXë(¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìì  V‹uW‹}j h°zVÿuWè ¡ÿÿƒÄƒøt9EP¡d	ÿvWÿ¤   ƒÄ…Àu…øıÿÿh  PÿuèÒÔ …ÀuWè#OşÿYjXë(¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìì  V‹uW‹}j hìzVÿuWèl ÿÿƒÄƒøt9EP¡d	ÿvWÿ¤   ƒÄ…Àu…øıÿÿh  PÿuèDÔ …ÀuWèNşÿYjXë(¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìƒì V‹uW‹}j j hL{VÿuWèÙŸÿÿƒÄƒøtRjEÿ5¤PÿvWèeEşÿƒÄ…Àu6EP¡d	ÿvWÿ¤   ƒÄ…ÀuEôjPÿuÿuèÓ …ÀuWèãMşÿYjXéš   ‹5üäSÿuô»¸#EàSPÿÖ¡d	h@{Wÿ  EàP¡d	Wÿ  ÿuøEàhÀVPÿÖ¡d	h4{Wÿ  EàP¡d	Wÿ  ÿuüEàSPÿÖ¡d	ƒÄDh({Wÿ  EàP¡d	Wÿ  ƒÄ3À[_^ÉÃh€{ÿt$ÿt$ÿt$èÃÿÿƒÄƒøuÃÿt$è¿‘şÿYÃU‹ìV‹uj h˜{Vÿuÿuè•ÿÿƒÄƒøtjEÿ5¤PÿvÿuèDşÿƒÄ…ÀtjXëÿuÿuè~‘şÿYY^]Ãh¼{ÿt$ÿt$ÿt$èDÿÿƒÄƒøuÃÿt$èd‘şÿYÃhØ{ÿt$ÿt$ÿt$èÿÿƒÄƒøuÃVÿ ã‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃW‹|$hô{ÿt$ÿt$WèÑÿÿƒÄƒøt)ÿã…Àu$¡d	Wÿl  Yj ÿüãPWè„>şÿƒÄjX_Ã‹d	Vj ÿ5¤±´  PèÌ€şÿPWÿƒÄ3À^_ÃU‹ìEWPEPE‹}Ph|ÿuÿuWèPÿÿƒÄƒøt2ÿuÿuÿuÿã…Àu$¡d	Wÿl  Yj ÿüãPWèú=şÿƒÄjXë%‹d	Vj ÿ5¤±´  PèB€şÿPWÿƒÄ3À^_]ÃU‹ìEV‹uPj hP|VÿuÿuèËœÿÿƒÄƒøtjEÿ5¤PÿvÿuèUBşÿƒÄ…ÀtjXëÿuÿuÿuèÕşÿƒÄ^]ÃU‹ìƒì|SVW3ÿWWEìW‹uPEè‹]PWWWWh„|V‰}øÿu‰}ô‰}üSèTœÿÿƒÄ4ƒø„  E‰}P¡d	ÿvÿĞ  9}YY‰Eğu‰}ğE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}EøPÿvSè&ÕÿÿƒÄ…À…¾   EôPÿvSèÕÿÿƒÄ…À…¦   ÿv¡d	ÿ   Ç$,$P‰EüÿÜäY…ÀYu‰}üëEüPÿvSè°3şÿƒÄƒøtgE‰}P¡d	ÿv ÿĞ  9}YY‹Øu3ÛE„Pÿv$ÿuèşÿƒÄ…Àu1EØPE„PSÿuüÿuìÿuèÿuôÿuøÿuÿuğÿã…Àu<ÿuè’IşÿY9}øt	ÿuøè/ÔÿÿY9}ôt	ÿuôè!ÔÿÿY9}üt
ÿuüÿåYjXé“   Wÿ5¤ÿuØè8~şÿW‰EÈÿ5¤ÿuÜè&~şÿÿuà‰EÌ¡d	ÿà   ÿuä‰EĞ¡d	ÿà   ‰EÔ¡d	MÈQj°´  ÿÜ   PÿuÿƒÄ09}øt	ÿuøè–ÓÿÿY9}ôt	ÿuôèˆÓÿÿY9}üt
ÿuüÿåY3À_^[ÉÃU‹ìì€   SVW3ÿWWEìWP‹uEè‹]PWWWWWh<}Vÿu‰}ø‰}ô‰}üSè'šÿÿƒÄ8ƒø„=  jEäÿ5¤PÿvSè¯?şÿƒÄ…À…  E‰}P¡d	ÿvÿĞ  9}YY‰Eğu‰}ğE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}EøPÿvSèÙÒÿÿƒÄ…À…Á   EôPÿvSèÁÒÿÿƒÄ…À…©   ÿv ¡d	ÿ   Ç$,$P‰EüÿÜäY…ÀYu‰}üëEüPÿv Sèc1şÿƒÄƒøtjE‰}P¡d	ÿv$ÿĞ  9}YY‹Øu3ÛE€Pÿv(ÿuèÈŒşÿƒÄ…Àu4EÔPE€PSÿuüÿuìÿuèÿuôÿuøÿuÿuğÿuäÿà…Àu<ÿuèBGşÿY9}øt	ÿuøèßÑÿÿY9}ôt	ÿuôèÑÑÿÿY9}üt
ÿuüÿåYjXé“   Wÿ5¤ÿuÔèè{şÿW‰EÄÿ5¤ÿuØèÖ{şÿÿuÜ‰EÈ¡d	ÿà   ÿuà‰EÌ¡d	ÿà   ‰EĞ¡d	MÄQj°´  ÿÜ   PÿuÿƒÄ09}øt	ÿuøèFÑÿÿY9}ôt	ÿuôè8ÑÿÿY9}üt
ÿuüÿåY3À_^[ÉÃU‹ìV‹uW‹}j h ~VÿuWè÷—ÿÿƒÄƒøt1jEÿ5¤PÿvWèƒ=şÿƒÄ…ÀuÿuÿãƒøÿuWè"FşÿYjXë‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^]ÃU‹ìV‹uW‹}j h ~VÿuWè}—ÿÿƒÄƒøt1jEÿ5¤PÿvWè	=şÿƒÄ…ÀuÿuÿãƒøÿuWè¨EşÿYjXë‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^]ÃU‹ìEV‹uPj h@~Vÿuÿuè—ÿÿƒÄƒøt7jEÿ5¤Pÿvÿuè‹<şÿƒÄ…Àuÿuÿuÿã…Àuÿuè&EşÿYjXë3À^]ÃU‹ìV‹uW‹}j ht~VÿuWèœ–ÿÿƒÄƒøt0jEÿ5¤PÿvWè(<şÿƒÄ…Àuÿuÿã…ÀuWèÈDşÿYjXë‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^]ÃU‹ìEV‹uPj h˜~Vÿuÿuè!–ÿÿƒÄƒøt7jEÿ5¤Pÿvÿuè«;şÿƒÄ…Àuÿuÿuÿ ã…ÀuÿuèFDşÿYjXë3À^]ÃU‹ìV‹uW‹}j hÈ~VÿuWè¼•ÿÿƒÄƒøt3jEÿ5¤PÿvWèH;şÿƒÄ…Àuÿuÿüâ=ÿÿÿuWèåCşÿYjXë‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^]ÃU‹ìV‹uj hì~VÿuÿuèB•ÿÿƒÄƒøtjEÿ5¤PÿvÿuèÌ:şÿƒÄ…ÀtjXëÿuÿuèŒşÿYY^]ÃU‹ìV‹uj h0Vÿuÿuèí”ÿÿƒÄƒøtjEÿ5¤Pÿvÿuèw:şÿƒÄ…ÀtjXëÿuÿuè)şÿYY^]ÃU‹ìQQSV‹uMW3ÀQ‹}PPPhpV‰EüÿuWè‰”ÿÿƒÄ ƒøtojEÿ5¤PÿvWè:şÿƒÄ…ÀuSEP¡d	ÿvWÿ¤   ƒÄ…Àu9jP‹]EüPÿvWèá9şÿƒÄ…ÀuEøPÿuÿuüSÿuÿøâ…ÀuWèvBşÿYjXë-ÿuø¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^[ÉÃU‹ìV‹uW‹}j h´VÿuWè¿“ÿÿƒÄƒøt4jEÿ5¤PÿvWèK9şÿƒÄ…ÀuEPÿuÿôâ…ÀuWèçAşÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìhÜÿuÿuÿuè7“ÿÿƒÄƒøu]Ãÿğâ…Àuÿu¡d	ÿl  Yë ‹d	VjÿP±´  ÿ‘ğ  PÿuÿƒÄ^3À]ÃV‹t$j hôVÿt$ÿt$èÔ’ÿÿƒÄƒøu^Ãÿv¡d	ÿ   Pÿt$èò‹şÿƒÄ^ÃU‹ìEPEPh€ÿuÿuÿuè’ÿÿƒÄƒøu]ÃÿuÿuÿuèwwşÿƒÄ]ÃU‹ìƒìV‹uW‹}j hD€WÿuVèS’ÿÿƒÄƒøt-ÿw¡d	ÿ   YMèQMğQMøQPÿìâ…ÀuVè‚@şÿYjXéˆ   ÿuü¡d	ÿuø¸¸   ÿ¨  YYP¡d	Vÿ   YPVÿÿuô¡d	ÿuğ¸¸   ÿ¨  ƒÄP¡d	Vÿ   YPVÿÿuì¡d	ÿuè¸¸   ÿ¨  ƒÄP¡d	Vÿ   YPVÿƒÄ3À_^ÉÃV‹t$j hd€Vÿt$ÿt$èp‘ÿÿƒÄƒøu^Ãÿv¡d	ÿ   YPÿèâ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^Ãh„€ÿt$ÿt$ÿt$è‘ÿÿƒÄƒøuÃVÿäâ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìì   V‹uW‹}j h €WÿuVèÆÿÿƒÄƒøtBÿw¡d	ÿ   Y• üÿÿ¹   QRURURURQ şÿÿQPÿàâ…ÀuVèà>şÿYjXéí   ¡d	fƒeş  şÿÿjÿQ¸¸   ÿğ  YYP¡d	Vÿ   YPVÿÿu¡d	ÿØ   ‹d	ƒÄPV¹¸   ÿ‘   YPVÿÿu¡d	ÿØ   ‹d	ƒÄPV¹¸   ÿ‘   YPVÿÿu¡d	ÿØ   ‹d	ƒÄPV¹¸   ÿ‘   YPVÿ¡d	fƒ¥şıÿÿ  üÿÿjÿQ¸¸   ÿğ  ƒÄP¡d	Vÿ   YPVÿƒÄ3À_^ÉÃU‹ìV‹uj j hø€VÿuÿuègÿÿƒÄƒøtH¡d	Sÿvÿ   ƒe ‹ØEP¡d	ÿvÿĞ  ƒÄƒ} u3ÀPSÿÜâ…À[uÿuè{=şÿYjXë3À^]ÃU‹ìV‹uj h$VÿuÿuèóÿÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuè‰şÿYY^]ÃU‹ìV‹uj Ej PhLVÿuÿuè›ÿÿƒÄƒøt:¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   YYPWÿuÿØâ…À_uÿuè½<şÿYjXë3À^]ÃU‹ìì   W‹}hŒÿuÿuWè1ÿÿƒÄƒøt6… şÿÿh   PÿÔâƒøÿu$¡d	Wÿl  Yj ÿüãPWè×.şÿƒÄjXëY‹d	Vj ÿ5œ±´  PèqşÿPWÿ¡d	fƒeş  şÿÿjÿQ°¸   ÿğ  ƒÄP¡d	Wÿ   YPWÿƒÄ3À^_ÉÃU‹ìì   V‹uW‹}j h¸VÿuWèpÿÿƒÄƒøt?jEÿ5œPÿvWèü2şÿƒÄ…Àu#… şÿÿh   Pÿuè‡şÿƒÄƒøÿuWè;şÿYjXëP‹d	P±´  ÿ‘Ø   PWÿ¡d	fƒeş  şÿÿjÿQ°¸   ÿğ  ƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìV‹uj hìVÿuÿuè¶ŒÿÿƒÄƒøt4jEÿ5œPÿvÿuè@2şÿƒÄ…ÀuÿuÿĞâ…ÀuÿuèŞ:şÿYjXë3À^]ÃU‹ìì  V‹uW‹}j h‚VÿuWèNŒÿÿƒÄƒøtGÿv¡d	ÿ   øıÿÿÇ$  QPÿÌâƒøÿu$¡d	Wÿl  Yj ÿüãPWèã,şÿƒÄjXëW‹d	j ÿ5œ±´  Pè,oşÿPWÿ¡d	fƒeş øıÿÿjÿQ°¸   ÿğ  ƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìì  V‹uW‹}j hP‚VÿuWè}‹ÿÿƒÄƒøt?jEÿ5œPÿvWè	1şÿƒÄ…Àu#…øıÿÿh  PÿuèY…şÿƒÄƒøÿuWèš9şÿYjXëP‹d	P±´  ÿ‘Ø   PWÿ¡d	fƒeş øıÿÿjÿQ°¸   ÿğ  ƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìV‹uj hŒ‚VÿuÿuèÃŠÿÿƒÄƒøt4jEÿ5œPÿvÿuèM0şÿƒÄ…ÀuÿuÿÈâ…Àuÿuèë8şÿYjXë3À^]ÃV‹t$j j h¸‚Vÿt$ ÿt$ èaŠÿÿƒÄƒøt8¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   YYPWÿÄâ…À_uÿt$è…8şÿYjX^Ã3À^ÃV‹t$j hè‚Vÿt$ÿt$èş‰ÿÿƒÄƒøt$ÿv¡d	ÿ   YPÿÀâ…Àuÿt$è68şÿYjX^Ã3À^ÃU‹ìì   V‹uj hƒVÿuÿuè©‰ÿÿƒÄƒøt0ÿv¡d	ÿ    şÿÿÇ$   QPÿ¼â…ÀuÿuèÕ7şÿYjXë*¡d	fƒeş  şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìì  V‹uj hXƒVÿuÿuè‰ÿÿƒÄƒøt0ÿv¡d	ÿ   øıÿÿÇ$  QPÿ¸â…ÀuÿuèK7şÿYjXë*¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìƒìSV3ÛWESPE‹uPEøSPEô‹}PShƒV‰]üÿuWèˆÿÿƒÄ,ƒøtÿv¡d	ÿ   ‰EğEüPÿvWèˆÁÿÿƒÄ…ÀuZjEÿ5¤PÿvWèæ-şÿƒÄ…Àu>ÿuÿuÿuÿuüÿuøÿuôÿuğÿ´âƒøÿu1¡d	Wÿl  YSÿüãPWèÜ(şÿƒÄ9]üt	ÿuüèùÀÿÿYjXë0‹d	Sÿ5œ±´  PèkşÿPWÿƒÄ9]üt	ÿuüèÆÀÿÿY3À_^[ÉÃU‹ìƒìS3ÛVES‹uPEøPEôPSh „Vÿu‰]üÿuè‡ÿÿƒÄ$ƒøt5ÿv¡d	ÿ   ‰EğEPEüP¡d	ÿv‰]ÿuÿ¼   ƒÄƒøujXëX‹EüW…   Pÿ$å3ö9]üY‹ø~‹ESÿ4°¡d	ÿ¬   ‰·F;uüYY|ãW‰·ÿuüÿuÿuøÿuôÿuğÿuèl“ ƒÄ_^[ÉÃU‹ìEPhl„ÿuÿuÿuèÉ†ÿÿƒÄƒøu]Ãÿuÿuè– YY]ÃS‹\$V‹t$j h”„Vÿt$ Sè”†ÿÿƒÄƒøt9ÿv¡d	ÿ   Pè³şÿY…ÀYu$¡d	Sÿl  Yj ÿüãPSè7'şÿƒÄjXë#‹d	j ÿ5¼±´  Pè€işÿPSÿƒÄ3À^[ÃU‹ìV‹uj h¼„Vÿuÿuè†ÿÿƒÄƒøtjEÿ5¼Pÿvÿuè˜+şÿƒÄ…ÀtjXëÿuèmşÿY3À^]ÃU‹ìì   EPhä„ÿuÿuÿuèµ…ÿÿƒÄƒøt!… şÿÿh   Pÿuèo² …Àuÿuèğ3şÿYjXÉÃ¡d	fƒeş V şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìV‹uj h…Vÿuÿuè?…ÿÿƒÄƒøtjEÿ5¼PÿvÿuèÉ*şÿƒÄ…ÀtjXëÿuÿuè®€şÿYY^]ÃU‹ì3ÀV‹uPPPhH…Vÿuÿuèç„ÿÿƒÄƒøtjEÿ5¼Pÿvÿuèq*şÿƒÄ…ÀtjXë0¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   PWÿuÿuèxƒşÿƒÄ_^]ÃU‹ìV‹uj h„…Vÿuÿuèo„ÿÿƒÄƒøtjEÿ5¼Pÿvÿuèù)şÿƒÄ…ÀtjXëÿuÿuè”ƒşÿYY^]ÃU‹ìV‹uj h´…Vÿuÿuè„ÿÿƒÄƒøtjEÿ5¤Pÿvÿuè¤)şÿƒÄ…ÀtjXëÿuÿuèèƒşÿYY^]ÃU‹ìEV‹uPj j hÌ…Vÿuÿuè¿ƒÿÿƒÄƒøt:¡d	Wÿvÿ   ÿv‹ø¡d	ÿ   YYÿuPWÿ¬â…À_uÿuèá1şÿYjXë3À^]ÃU‹ìƒìV‹uW‹}j h†WÿuVèTƒÿÿƒÄƒøt<jEÿ5¤PÿwVèà(şÿƒÄ…Àu EèPEğPEøPÿuÿ¨â…ÀuVèt1şÿYjXë~¡d	¸¸   EøPèÕşÿYP¡d	Vÿ   YPVÿ¡d	¸¸   EğPè®şÿƒÄP¡d	Vÿ   YPVÿ¡d	¸¸   EèPè…şÿƒÄP¡d	Vÿ   YPVÿƒÄ3À_^ÉÃU‹ìƒìSV‹u3ÛWS‹}SSSh$†VÿuWèe‚ÿÿƒÄ ƒø„ò   jEÿ5¤PÿvWèí'şÿƒÄ…À…Ò   Eø‰EEøPÿvWèşÿƒÄ…Àt'ÿv¡d	ÿø  …ÀY…¡   ¡d	Wÿl  Y‰]Eğ‰EEğPÿvWèÚşÿƒÄ…Àt#ÿv¡d	ÿø  …ÀYud¡d	Wÿl  Y‰]Eè]èPÿvWè şÿƒÄ…Àt"ÿv¡d	ÿø  …ÀYu*¡d	Wÿl  Y3ÛSÿuÿuÿuÿ¤â…ÀuWèË/şÿYjXë3À_^[ÉÃU‹ìQEV‹uPj ƒeü hX†Vÿuÿuè8ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèÂ&şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü h|†Vÿuÿuèİ€ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèg&şÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h˜†Vÿuÿuèj€ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèô%şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h¸†Vÿuÿuè€ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuè˜%şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hÔ†VÿuÿuèšÿÿƒÄƒøtjEüÿ5ÔPÿvÿuè$%şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü hø†Vÿuÿuè>ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèÈ$şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h‡VÿuÿuèÊ~ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèT$şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h@‡Vÿuÿuèn~ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuèø#şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìh`‡ÿuÿuÿuè~ÿÿƒÄƒøu]ÃVjjÿÌä‹d	j ÿ5Ô±´  PÿuèòÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü ht‡Vÿuÿuè¨}ÿÿƒÄƒøtjEüÿ5ÔPÿvÿuè2#şÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQEV‹uPj ƒeü h‡Vÿuÿuè?}ÿÿƒÄƒøtjEüÿ5PÿvÿuèÉ"şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü h¼‡Vÿuÿuèä|ÿÿƒÄƒøtjEüÿ5Pÿvÿuèn"şÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìƒìV‹uW3ÿWWhà‡Vÿu‰}üÿuèq|ÿÿƒÄƒøt4jEüÿ5Pÿvÿuèû!şÿƒÄ…ÀuEìPÿvÿuè|şÿƒÄ…ÀtjXë‹Eü;Çt
xuì¥¥¥¥3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hˆVÿuWèø{ÿÿƒÄƒøtjEüÿ5PÿvWè„!şÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5Ô±´  PWèËÿÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW3ÿWWh8ˆVÿu‰}üÿuè~{ÿÿƒÄƒøt4jEüÿ5Pÿvÿuè!şÿƒÄ…ÀuEìPÿvÿuè{şÿƒÄ…ÀtjXë‹Eü;Çt
xuì¥¥¥¥3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hhˆVÿuWè{ÿÿƒÄƒøtjEüÿ5PÿvWè‘ şÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5Ô±´  PWèØ~ÿÿPWÿƒÄ3À_^ÉÃU‹ìQEV‹uPj ƒeü hˆVÿuÿuè‹zÿÿƒÄƒøtjEüÿ5Pÿvÿuè şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H$3À^ÉÃU‹ìQV‹uj ƒeü hÀˆVÿuÿuè/zÿÿƒÄƒøtjEüÿ5Pÿvÿuè¹şÿƒÄ…ÀtjXë#‹Eü‹H$¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hèˆVÿuÿuè»yÿÿƒÄƒøtjEüÿ5PÿvÿuèEşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H(3À^ÉÃU‹ìQV‹uj ƒeü h‰Vÿuÿuè_yÿÿƒÄƒøtjEüÿ5PÿvÿuèéşÿƒÄ…ÀtjXë#‹Eü‹H(¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hD‰VÿuÿuèëxÿÿƒÄƒøtjEüÿ5PÿvÿuèuşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H,3À^ÉÃU‹ìQV‹uj ƒeü h€‰VÿuÿuèxÿÿƒÄƒøtjEüÿ5PÿvÿuèşÿƒÄ…ÀtjXë#‹Eü‹H,¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h¬‰VÿuÿuèxÿÿƒÄƒøtjEüÿ5Pÿvÿuè¥şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H03À^ÉÃU‹ìQV‹uj ƒeü hì‰Vÿuÿuè¿wÿÿƒÄƒøtjEüÿ5PÿvÿuèIşÿƒÄ…ÀtjXë#‹Eü‹H0¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hŠVÿuÿuèKwÿÿƒÄƒøtjEüÿ5PÿvÿuèÕşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H43À^ÉÃU‹ìQV‹uj ƒeü h\ŠVÿuÿuèïvÿÿƒÄƒøtjEüÿ5PÿvÿuèyşÿƒÄ…ÀtjXë#‹Eü‹H4¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü hŒŠVÿuÿuè}vÿÿƒÄƒøt<jEüÿ5PÿvÿuèşÿƒÄ…ÀujEÿ5¸PÿvÿuèéşÿƒÄ…ÀtjXë‹Eü…Àt
‹Mf‹	f‰H83À^ÉÃU‹ìQV‹uW‹}ƒeü j hÈŠVÿuWèıuÿÿƒÄƒøtjEüÿ5PÿvWè‰şÿƒÄ…ÀtjXëF‹EüSjf‹@8‰Eÿ$å‹ØEjPSÿå¡d	jÿ5¸°´  SWèµyÿÿPWÿƒÄ(3À[_^ÉÃU‹ìQEV‹uPj ƒeü hôŠVÿuÿuèguÿÿƒÄƒøtjEüÿ5PÿvÿuèñşÿƒÄ…ÀtjXë‹Eü…Àtf‹Mf‰H:3À^ÉÃU‹ìQV‹uj ƒeü h4‹Vÿuÿuè	uÿÿƒÄƒøtjEüÿ5Pÿvÿuè“şÿƒÄ…ÀtjXë'‹Eüf‹H:¡d	·ÉQ°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìhd‹ÿuÿuÿuètÿÿƒÄƒøu]ÃVj<jÿÌä‹d	j ÿ5±´  Pÿuè‰xÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü h|‹Vÿuÿuè?tÿÿƒÄƒøtjEüÿ5PÿvÿuèÉşÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQEV‹uPj ƒeü hœ‹VÿuÿuèÖsÿÿƒÄƒøtjEüÿ5¤Pÿvÿuè`şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü hĞ‹Vÿuÿuè{sÿÿƒÄƒøtjEüÿ5¤PÿvÿuèşÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hü‹VÿuÿuèsÿÿƒÄƒøtjEüÿ5¤Pÿvÿuè’şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h,ŒVÿuÿuè¬rÿÿƒÄƒøtjEüÿ5¤Pÿvÿuè6şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hTŒVÿuÿuè8rÿÿƒÄƒøtjEüÿ5¤PÿvÿuèÂşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü hˆŒVÿuÿuèÜqÿÿƒÄƒøtjEüÿ5¤PÿvÿuèfşÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQQV‹uj j ƒeü ƒeø h´ŒVÿuÿuèeqÿÿƒÄƒøt<jEüÿ5¤PÿvÿuèïşÿƒÄ…ÀujEøÿ5´PÿvÿuèÑşÿƒÄ…ÀtjXë‹Eü…Àt‹Mø‹‰P‹A‹Mü‰A3À^ÉÃU‹ìQV‹uW‹}ƒeü j hôŒVÿuWèŞpÿÿƒÄƒøtjEüÿ5¤PÿvWèjşÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5´±´  PWè±tÿÿPWÿƒÄ3À_^ÉÃU‹ìQQV‹uj j ƒeü ƒeø h$VÿuÿuèapÿÿƒÄƒøt<jEüÿ5¤PÿvÿuèëşÿƒÄ…ÀujEøÿ5´PÿvÿuèÍşÿƒÄ…ÀtjXë‹Eü…Àt‹Mø‹‰P‹A‹Mü‰A3À^ÉÃU‹ìQV‹uW‹}ƒeü j hdVÿuWèÚoÿÿƒÄƒøtjEüÿ5¤PÿvWèfşÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5´±´  PWè­sÿÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW3ÿWWh”Vÿu‰}üÿuè`oÿÿƒÄƒøt4jEüÿ5¤PÿvÿuèêşÿƒÄ…ÀuEìPÿvÿuèoşÿƒÄ…ÀtjXë‹Eü;Çt
xuì¥¥¥¥3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hÜVÿuWèçnÿÿƒÄƒøtjEüÿ5¤PÿvWèsşÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀÿ5Ô±´  PWèºrÿÿPWÿƒÄ3À_^ÉÃU‹ìhÿuÿuÿuèznÿÿƒÄƒøu]ÃVj,jÿÌä‹d	j ÿ5¤±´  PÿuèerÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü h,VÿuÿuènÿÿƒÄƒøtjEüÿ5¤Pÿvÿuè¥şÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQEV‹uPj ƒeü hTVÿuÿuè²mÿÿƒÄƒøtjEüÿ5´Pÿvÿuè<şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü htVÿuÿuèWmÿÿƒÄƒøtjEüÿ5´PÿvÿuèáşÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hVÿuÿuèälÿÿƒÄƒøtjEüÿ5´PÿvÿuènşÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h°VÿuÿuèˆlÿÿƒÄƒøtjEüÿ5´PÿvÿuèşÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìhÌÿuÿuÿuè!lÿÿƒÄƒøu]ÃVjjÿÌä‹d	j ÿ5´±´  PÿuèpÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü hàVÿuÿuèÂkÿÿƒÄƒøtjEüÿ5´PÿvÿuèLşÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃhüÿt$ÿt$ÿt$èfkÿÿƒÄƒøuÃÿt$èŒqşÿYÃU‹ìV‹uj hVÿuÿuè8kÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXëÿuÿuè£qşÿYY^]ÃU‹ìƒìV‹uj h8VÿuÿuèâjÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë2ÿuÿ€çPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìEV‹uPj hXVÿuÿuècjÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë5ÿuÿuÿ„çPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìEV‹uPj h€VÿuÿuèáiÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë5ÿuÿuÿˆçPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìh ÿuÿuÿuègiÿÿƒÄƒøuÉÃÿŒçPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìƒìh¼ÿuÿuÿuèiÿÿƒÄƒøuÉÃÿçPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìƒìhÔÿuÿuÿuè¿hÿÿƒÄƒøuÉÃÿ”çPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìV‹uj hğVÿuÿuèjhÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿ˜ç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìƒìV‹uW‹}j hWÿuVèøgÿÿƒÄƒøtGEP¡d	ÿwVÿ¤   ƒÄ…Àu-ÿuÿœç…Àu%ÿüã‹ø¡d	Vÿl  j WVèşÿƒÄjXë'PEìh¸#PÿüäEìjP¡d	Vÿ¨  ƒÄ3À_^ÉÃU‹ìƒìh4ÿuÿuÿuè`gÿÿƒÄƒøuÉÃÿ çPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìƒìV‹uW3ÿWWhLVÿuÿuègÿÿƒÄƒøuëqESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿvÿĞ  9}YYu3ÀPSÿ¤çPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À[_^ÉÃU‹ìƒì V‹uW3ÿWWWWh|VÿuÿuèdfÿÿƒÄ ƒøt>EüP¡d	ÿvÿuÿ¤   ƒÄ…Àu"‹Eü‰EôEøP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë|ES‹]øPÿv¡d	‰}ÿĞ  9}YY‰Eu‰}E‰}P¡d	ÿvÿĞ  9}YYu3ÀPÿuSÿuôÿ¨çPEàh¸#PÿüäEàjP¡d	ÿuÿ¨  ƒÄ3À[_^ÉÃU‹ìì   V‹uW‹}j hÈVÿuWèweÿÿƒÄƒøt:EP¡d	ÿvWÿ¤   ƒÄ…Àu … şÿÿh   Pÿuÿ¬ç…ÀuWè™şÿYjXë(¡d	fƒeş  şÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìì   V‹uW‹}j h ‘VÿuWèâdÿÿƒÄƒøt:EP¡d	ÿvWÿ¤   ƒÄ…Àu … şÿÿh   Pÿuÿ°ç…ÀuWèşÿYjXë(¡d	fƒeş  şÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìEV‹uPj h0‘VÿuÿuèQdÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë*ÿuÿuÿàè‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìQV‹uEWPE‹}Pj hT‘VÿuWèÖcÿÿƒÄƒøt:EP¡d	ÿvWÿ¤   ƒÄ…Àu EüPÿuÿuÿuèèjşÿƒÄ…ÀuWèøşÿYjXë-ÿuü¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìSVEWPEPEüP‹uEø‹]PEôPj j h€‘VÿuSè(cÿÿƒÄ,ƒøt[EP¡d	ÿvSÿ¤   ƒÄ…ÀuA‹}EğP¡d	ÿvSÿ¤   ƒÄ…Àu$ÿuÿuÿuüÿuøÿuôÿuğWÿ´ç…ÀuSè)şÿYjXë3À_^[ÉÃU‹ìV‹uW‹}j hÄ‘VÿuWèbÿÿƒÄƒøtEP¡d	ÿvWÿ¤   ƒÄ…ÀtjXëSEPÿuÿ¸ç‹d	P±´  ÿ‘Ø   PWÿÿu¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìQEV‹uPj ƒeü hì‘VÿuÿuèüaÿÿƒÄƒøtjEüÿ5 Pÿvÿuè†şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü h’Vÿuÿuè¡aÿÿƒÄƒøtjEüÿ5 Pÿvÿuè+şÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hD’Vÿuÿuè.aÿÿƒÄƒøtjEüÿ5 Pÿvÿuè¸şÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü ht’VÿuÿuèÒ`ÿÿƒÄƒøtjEüÿ5 Pÿvÿuè\şÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü hœ’Vÿuÿuè``ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèêşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü hÔ’Vÿuÿuèæ_ÿÿƒÄƒøtjEüÿ5 PÿvÿuèpşÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü h “Vÿuÿuèi_ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèóşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü h8“Vÿuÿuèï^ÿÿƒÄƒøtjEüÿ5 PÿvÿuèyşÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü hd“Vÿuÿuèr^ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèüşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü h “Vÿuÿuèø]ÿÿƒÄƒøtjEüÿ5 Pÿvÿuè‚şÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü hÌ“Vÿuÿuè{]ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü h”Vÿuÿuè]ÿÿƒÄƒøtjEüÿ5 Pÿvÿuè‹şÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü h<”Vÿuÿuè„\ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü hx”Vÿuÿuè
\ÿÿƒÄƒøtjEüÿ5 Pÿvÿuè”şÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìQV‹uj j ƒeü h¨”Vÿuÿuè[ÿÿƒÄƒøt:jEüÿ5 PÿvÿuèşÿƒÄ…ÀuEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìƒìV‹uj ƒeü hà”Vÿuÿuè[ÿÿƒÄƒøtjEüÿ5 Pÿvÿuè şÿƒÄ…ÀtjXë.‹EüÿpEèh¸#PÿüäEèjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìV‹uW3ÿWWh•Vÿu‰}üÿuè”ZÿÿƒÄƒøt4jEüÿ5 Pÿvÿuè şÿƒÄ…ÀuEìPÿvÿuè³ZşÿƒÄ…ÀtjXë‹Eü;Çt
x uì¥¥¥¥3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h@•VÿuWèZÿÿƒÄƒøtjEüÿ5 PÿvWè§ÿıÿƒÄ…ÀtjXë*‹Eü‹d	j ƒÀ ÿ5Ô±´  PWèî]ÿÿPWÿƒÄ3À_^ÉÃU‹ìhh•ÿuÿuÿuè®YÿÿƒÄƒøu]ÃVj0jÿÌä‹d	j ÿ5 ±´  Pÿuè™]ÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü h„•VÿuÿuèOYÿÿƒÄƒøtjEüÿ5 PÿvÿuèÙşıÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQV‹uEj Pƒeü h¨•VÿuÿuèæXÿÿƒÄƒøt@jEüÿ5 PÿvÿuèpşıÿƒÄ…Àu"‹EüÇ 0   ÿuüÿuÿ¼ç…ÀuÿuèşÿYjXë3À^ÉÃU‹ìì  V‹uW‹}j hÜ•VÿuWèrXÿÿƒÄƒøt<EP¡d	ÿvWÿ¤   ƒÄ…Àu"…øıÿÿh  PÿuèT_şÿƒÄ…ÀuWè’şÿYjXë(¡d	fƒeş øıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìV‹uj j h–VÿuÿuèáWÿÿƒÄƒøtEEP¡d	ÿvÿuÿ¤   ƒÄ…Àu)¡d	Wÿv‹}ÿ   YPWÿÀç…À_uÿuèøşÿYjXë3À^]ÃU‹ìEV‹uPj h4–VÿuÿuèlWÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë*ÿuÿuÿÄç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEV‹uPj hT–VÿuÿuèøVÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë*ÿuÿuÿÈç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEV‹uPj h|–Vÿuÿuè„VÿÿƒÄƒøt5EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuÿuÿuÿÌç…Àuÿuè«şÿYjXë3À^]ÃU‹ìEV‹uPj h¤–VÿuÿuèVÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë*ÿuÿuÿĞç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj hÈ–Vÿuÿuè¯UÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuÿuÿÔç…ÀuÿuèÙşÿYjXë3À^]ÃU‹ìV‹uj hà–VÿuÿuèQUÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuÿuÿØç…Àuÿuè{şÿYjXë3À^]ÃU‹ìV‹uj hü–VÿuÿuèóTÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuÿuÿÜç…ÀuÿuèşÿYjXë3À^]ÃU‹ìV‹uj h—Vÿuÿuè•TÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿàç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj h0—Vÿuÿuè(TÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿ`è‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj hH—Vÿuÿuè»SÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿdè‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj hh—VÿuÿuèNSÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿhè‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj h€—VÿuÿuèáRÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿlè‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj h —VÿuÿuètRÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿpè‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìSV‹u‹]Wj j hÀ—VÿuSèRÿÿƒÄƒøt7EP¡d	ÿvSÿ¤   ƒÄ…Àu‹}EP¡d	ÿvSÿ¤   ƒÄ…ÀtjXë&ÿuWÿtè‹d	P±´  ÿ‘Ø   PSÿƒÄ3À_^[]ÃU‹ìƒìVEWPE‹uPEPEüPEø‹}Pj hè—VÿuWè`QÿÿƒÄ(ƒøtAEôP¡d	ÿvWÿ¤   ƒÄ…Àu'EğPÿuÿuÿuÿuüÿuøÿuôÿxè…ÀuWè{ÿıÿYjXë-ÿuğ¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQQEV‹uPEPEüPj h4˜Vÿuÿuè¹PÿÿƒÄ ƒøt;EøP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuÿuÿuüÿuøÿ|è…ÀuÿuèÚşıÿYjXë3À^ÉÃU‹ìQQEV‹uPEPEüPj hl˜VÿuÿuèDPÿÿƒÄ ƒøt;EøP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuÿuÿuüÿuøÿ€è…ÀuÿuèeşıÿYjXë3À^ÉÃU‹ìƒìV‹uj hœ˜VÿuÿuèÚOÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë2ÿuÿ„èPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìV‹uW‹}j h´˜VÿuWè]OÿÿƒÄƒøt2EP¡d	ÿvWÿ¤   ƒÄ…ÀuEğPÿuÿˆè…ÀuWè‡ııÿYjXë¡d	°´  EğPèPşÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}j hĞ˜VÿuWèŞNÿÿƒÄƒøt2EP¡d	ÿvWÿ¤   ƒÄ…ÀuEğPÿuÿŒè…ÀuWèııÿYjXë¡d	°´  EğPèOşÿPWÿƒÄ3À_^ÉÃU‹ìQSV‹u3À‹]WPPhì˜Vÿu‰EüSè[NÿÿƒÄƒøtWEP¡d	ÿvSÿ¤   ƒÄ…Àu=j‹}ÿ5EüPÿvSèÊóıÿƒÄ…Àu‹EüÇ <   ÿuüWÿè…ÀuSè`üıÿYjXë3À_^[ÉÃU‹ìQSV‹u3À‹]WPPh™Vÿu‰EüSèÍMÿÿƒÄƒøtWEP¡d	ÿvSÿ¤   ƒÄ…Àu=j‹}ÿ5¤EüPÿvSè<óıÿƒÄ…Àu‹EüÇ ,   ÿuüWÿ”è…ÀuSèÒûıÿYjXë3À_^[ÉÃU‹ìQSV‹u3À‹]WPPh<™Vÿu‰EüSè?MÿÿƒÄƒøtWEP¡d	ÿvSÿ¤   ƒÄ…Àu=j‹}ÿ5¤EüPÿvSè®òıÿƒÄ…Àu‹EüÇ ,   ÿuüWÿ˜è…ÀuSèDûıÿYjXë3À_^[ÉÃU‹ìƒìV‹uj hh™Vÿuÿuè·LÿÿƒÄƒøtEøPÿvÿuèXNşÿƒÄ…ÀtjXë5ÿuüÿuøÿœèPEäh¸#PÿüäEäjP¡d	ÿuÿ¨  ƒÄ3À^ÉÃU‹ìƒìSV‹uEW‹]Pj j hˆ™VÿuSè6LÿÿƒÄƒøtlEP¡d	ÿvSÿ¤   ƒÄ…ÀuR‹}EP¡d	ÿvSÿÄ   ƒÄƒøt43À9EtEğPÿvSè6LşÿƒÄ…ÀuEğÿuPWÿ è…ÀuSè&úıÿYjXë3À_^[ÉÃU‹ìƒìEVPEPEü‹uPEøPEôPj h¸™Vÿuÿuè…KÿÿƒÄ(ƒøtAEğP¡d	ÿvÿuÿ¤   ƒÄ…Àu%ÿuÿuÿuüÿuøÿuôÿuğÿ¤è…Àuÿuè ùıÿYjXë3À^ÉÃU‹ìV‹uj hô™VÿuÿuèKÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuÿ¨è…ÀuÿuèBùıÿYjXë3À^]ÃU‹ìEV‹uPj hšVÿuÿuè¶JÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë*ÿuÿuÿ¬è‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEPEPh4šÿuÿuÿuèBJÿÿƒÄƒøtÿuÿuÿ â…Àuÿuè…øıÿYjX]Ã3À]ÃU‹ìEPhXšÿuÿuÿuèşIÿÿƒÄƒøu]ÃVÿuÿ°è‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]Ãhtšÿt$ÿt$ÿt$è³IÿÿƒÄƒøuÃVÿ´è‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìEPhšÿuÿuÿuèhIÿÿƒÄƒøtÿuÿ¸è…Àuÿuè®÷ıÿYjX]Ã3À]ÃU‹ìV‹uj h¸šVÿuÿuè'IÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuÿ¼è…ÀuÿuèQ÷ıÿYjXë3À^]ÃU‹ìV‹uj hĞšVÿuÿuèÉHÿÿƒÄƒøt2EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuÿuÿÀè…ÀuÿuèóöıÿYjXë3À^]ÃU‹ìQQhèšÿuÿuÿuèmHÿÿƒÄƒøtEøPÿé…Àuÿuè²öıÿYjXÉÃ¡d	V°´  EøPè«IşÿPÿuÿƒÄ3À^ÉÃU‹ìEPEPhüšÿuÿuÿuèHÿÿƒÄƒøtÿuÿuÿpç…ÀuÿuèKöıÿYjX]Ã3À]ÃU‹ìQEPEPEüPh›ÿuÿuÿuè»GÿÿƒÄƒøuÉÃVÿuÿuÿuüÿlç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^ÉÃU‹ìV‹uj hT›VÿuÿuèfGÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë'ÿuÿhç‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEPhx›ÿuÿuÿuèùFÿÿƒÄƒøu]Ãÿuÿuè_NşÿYY]ÃU‹ìEPh˜›ÿuÿuÿuèÆFÿÿƒÄƒøu]ÃÿuÿuèeQşÿYY]ÃU‹ìQSEV‹uPj j h¸›Vÿuÿuè‹FÿÿƒÄƒøt>ƒe EP¡d	ÿvÿĞ  ƒ} YY‹Øu3ÛEüP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXë+ÿuÿuüSÿpé‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^[ÉÃU‹ìQQhä›ÿuÿuÿuèùEÿÿƒÄƒøtEøPÿdç…Àuÿuè>ôıÿYjXÉÃ¡d	V°´  EøPè7GşÿPÿuÿƒÄ3À^ÉÃU‹ìEPEPhü›ÿuÿuÿuè”EÿÿƒÄƒøtÿuÿuÿ`ç…Àuÿuè×óıÿYjX]Ã3À]ÃU‹ìQEPEPEüPhœÿuÿuÿuèGEÿÿƒÄƒøuÉÃÿuÿuÿuüÿuèÍ- ƒÄÉÃU‹ìEPhLœÿuÿuÿuèEÿÿƒÄƒøu]Ãÿuÿuè	/ YY]ÃU‹ìEPhlœÿuÿuÿuèÚDÿÿƒÄƒøu]ÃÿuÿuèdJşÿYY]ÃU‹ìƒì<SV3ÛWSSSEôSPEğ‹uPEìPEèPEäP‹}SEØSPhˆœVÿu‰]üWè€DÿÿƒÄ@ƒø„‘   ÿv¡d	ÿ   ÿv‰EÜ¡d	ÿ   ‰EàEP¡d	ÿv$Wÿ¤   ƒÄ…ÀuU‹Ejÿ5è‰EøEPÿv(WèÆéıÿƒÄ…Àu3jEÿ5”Pÿv,WèªéıÿƒÄ…ÀujEüSPÿv0Wè“éıÿƒÄ…ÀtjXëQÿuüÿuÿuÿuøÿuôÿuğÿuìÿuèÿuäÿuàÿuÜÿuØÿØèPEÄh¸#PÿüäEÄjP¡d	Wÿ¨  ƒÄ3À_^[ÉÃU‹ìQQEV‹uPEPEüPj hVÿuÿuè`CÿÿƒÄ ƒøt;EøP¡d	ÿvÿuÿ¤   ƒÄ…Àuÿuÿuÿuüÿuøÿ\ç…ÀuÿuèñıÿYjXë3À^ÉÃW‹|$hPÿt$ÿt$WèûBÿÿƒÄƒøt)ÿ@é…Àu$¡d	Wÿl  Yj ÿüãPWè®ãıÿƒÄjX_Ã‹d	Vj ÿ5Ì±´  Pèö%şÿPWÿƒÄ3À^_ÃU‹ìV‹uj hpVÿuÿuè„BÿÿƒÄƒøt4jEÿ5ÌPÿvÿuèèıÿƒÄ…Àuÿuÿé…Àuÿuè¬ğıÿYjXë3À^]ÃU‹ìSEV‹uPE‹]Pj hœVÿuSèBÿÿƒÄƒøt?ÿv¡d	ÿ   YÿuÿuPÿDé…Àu$¡d	Sÿl  Yj ÿüãPSè·âıÿƒÄjXë#‹d	j ÿ5Ì±´  Pè %şÿPSÿƒÄ3À^[]ÃU‹ìQSVW‹u3ÿEWPE‹]PWhàVÿu‰}üSè|AÿÿƒÄ ƒøtYÿv¡d	ÿ   ‰EEüPÿvSè…zÿÿƒÄ…Àu4ÿuüÿuÿuÿuÿé;Çu1¡d	Sÿl  YWÿüãPSèÿáıÿƒÄ9}üt	ÿuüèzÿÿYjXë0‹d	Wÿ5Ì±´  Pè;$şÿPSÿƒÄ9}üt	ÿuüèéyÿÿY3À_^[ÉÃU‹ìV‹uj h(Vÿuÿuè¹@ÿÿƒÄƒøt4jEÿ5ÌPÿvÿuèCæıÿƒÄ…Àuÿuÿé…ÀuÿuèáîıÿYjXë3À^]ÃhLÿt$ÿt$ÿt$è]@ÿÿƒÄƒøuÃÿt$èNşÿYÃU‹ìV‹uj hhVÿuÿuè/@ÿÿƒÄƒøtjEÿ5¸Pÿvÿuè¹åıÿƒÄ…ÀtjXëÿuÿuè‚NşÿYY^]ÃU‹ìV‹uj hŒVÿuÿuèÚ?ÿÿƒÄƒøtjEÿ5ÌPÿvÿuèdåıÿƒÄ…ÀtjXëÿuÿuèÃMşÿYY^]ÃU‹ìSEV‹uPEPE‹]Pj h¬VÿuSèw?ÿÿƒÄ ƒøtBÿv¡d	ÿ   YÿuÿuÿuPÿ é…Àu$¡d	Sÿl  Yj ÿüãPSèàıÿƒÄjXë#‹d	j ÿ5¸±´  PèZ"şÿPSÿƒÄ3À^[]ÃU‹ìƒìSVW3ÿE‹uWPE‹]PWWWhôVÿu‰}üSèÒ>ÿÿƒÄ(ƒø„”   ÿv¡d	ÿ   ÿv‰Eğ¡d	ÿ   j‰Eôÿ5ØEPÿvSè8äıÿƒÄ…ÀuV‹E‹ ‰EøEüPÿvSè¢wÿÿƒÄ…Àu:ÿuüÿuÿuÿuøÿuôÿuğÿüè;Çu1¡d	Sÿl  YWÿüãPSèßıÿƒÄ9}üt	ÿuüè3wÿÿYjXë0‹d	Wÿ5¸±´  PèR!şÿPSÿƒÄ9}üt	ÿuüè wÿÿY3À_^[ÉÃU‹ìEWPEPE‹}PhPŸÿuÿuWèÆ=ÿÿƒÄƒøt2ÿuÿuÿuÿøè…Àu$¡d	Wÿl  Yj ÿüãPWèpŞıÿƒÄjXë%‹d	Vj ÿ5¸±´  Pè¸ şÿPWÿƒÄ3À^_]ÃU‹ìV‹uj hŸVÿuÿuèE=ÿÿƒÄƒøt4jEÿ5¸PÿvÿuèÏâıÿƒÄ…Àuÿuÿè…ÀuÿuèmëıÿYjXë3À^]ÃU‹ìV‹uj h°ŸVÿuÿuèå<ÿÿƒÄƒøt4jEÿ5¸PÿvÿuèoâıÿƒÄ…Àuÿuÿ<é…ÀuÿuèëıÿYjXë3À^]ÃU‹ìEW‹}PhĞŸÿuÿuWèƒ<ÿÿƒÄƒøt,ÿuÿ8é…Àu$¡d	Wÿl  Yj ÿüãPWè3İıÿƒÄjXë%‹d	Vj ÿ5¸±´  Pè{şÿPWÿƒÄ3À^_]ÃU‹ìV‹uj høŸVÿuÿuè<ÿÿƒÄƒøt4jEÿ5¸Pÿvÿuè’áıÿƒÄ…Àuÿuÿ4é…Àuÿuè0êıÿYjXë3À^]Ãh ÿt$ÿt$ÿt$è¬;ÿÿƒÄƒøuÃVÿ0é‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìQQh8 ÇEø   ÿuÿuÿuè\;ÿÿƒÄƒøtEøPÿ,é…Àuÿuè¡éıÿYjXÉÃ¡d	Vÿuü°´  ÿà   PÿuÿƒÄ3À^ÉÃU‹ìEPhT ÿuÿuÿuèû:ÿÿƒÄƒøu]ÃVÿuÿ(é‹d	¿ÀP±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEPht ÿuÿuÿuè©:ÿÿƒÄƒøu]ÃVÿuÿ$é‹d	¿ÀP±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEPEPh ÿuÿuÿuèS:ÿÿƒÄƒøu]ÃVÿuÿuÿ é‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uW3ÿWh¸ Vÿuÿuèÿ9ÿÿƒÄƒøt9ƒ}~EP¡d	ÿvÿuÿ¤   ƒÄ…Àu‹}Wÿé…Àuÿuè"èıÿYjXë3À_^]Ãhä ÿt$ÿt$ÿt$è9ÿÿƒÄƒøtÿé…Àuÿt$èåçıÿYjXÃ3ÀÃhü ÿt$ÿt$ÿt$èd9ÿÿƒÄƒøtÿÈè…Àuÿt$è¬çıÿYjXÃ3ÀÃU‹ìV‹uW‹}Ej Ph¡VÿuWè!9ÿÿƒÄƒøtKjEÿ5ÈPÿvWè­ŞıÿƒÄ…Àu/ÿuÿuÿÄè…Àu$¡d	Wÿl  Yj ÿüãPWè²ÙıÿƒÄjXë#‹d	j ÿ5È±´  PèûşÿPWÿƒÄ3À_^]ÃU‹ìEW‹}Ph<¡ÿuÿuWè†8ÿÿƒÄƒøt,ÿuÿ<è…Àu$¡d	Wÿl  Yj ÿüãPWè6ÙıÿƒÄjXë%‹d	Vj ÿ5È±´  Pè~şÿPWÿƒÄ3À^_]ÃU‹ìƒìh`¡ÿuÿuÿuè8ÿÿƒÄƒøuÉÃÿ8èPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃh€¡ÿt$ÿt$ÿt$è»7ÿÿƒÄƒøuÃÿt$è¦FşÿYÃU‹ìì   EPh¤¡ÿuÿuÿuè‡7ÿÿƒÄƒøt"… şÿÿh   Pÿuÿ4è…ÀuÿuèÁåıÿYjXÉÃ¡d	fƒeş V şÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìƒìhà¡ÿuÿuÿuè7ÿÿƒÄƒøuÉÃÿ0èPEìh¸#PÿüäEìjP¡d	ÿuÿ¨  ƒÄ3ÀÉÃU‹ìEPhü¡ÿuÿuÿuè¼6ÿÿƒÄƒøu]ÃVÿuÿ,è‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìV‹uj h(¢Vÿuÿuèm6ÿÿƒÄƒøt#ÿv¡d	ÿ   YPÿ(è…Àuÿuè¦äıÿYjXë‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìEPhT¢ÿuÿuÿuè6ÿÿƒÄƒøu]Ãÿuÿuè¾ YY]ÃU‹ìV‹uj h|¢VÿuÿuèÏ5ÿÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXëÿuÿuè YY^]Ãh ¢ÿt$ÿt$ÿt$è€5ÿÿƒÄƒøuÃVÿœâ·È¡d	Q°´  ÿØ   Pÿt$ÿƒÄ3À^ÃhÀ¢ÿt$ÿt$ÿt$è75ÿÿƒÄƒøuÃVÿ˜â·È¡d	Q°´  ÿØ   Pÿt$ÿƒÄ3À^Ãhà¢ÿt$ÿt$ÿt$èî4ÿÿƒÄƒøuÃVÿ”â‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^Ãhü¢ÿt$ÿt$ÿt$è§4ÿÿƒÄƒøuÃVÿâ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìh£ÿuÿuÿuè`4ÿÿƒÄƒøtÿá·È…Éuÿuè¦âıÿYjX]Ã¡d	VQ°´  ÿØ   PÿuÿƒÄ3À^]ÃU‹ìh@£ÿuÿuÿuè4ÿÿƒÄƒøtÿ”á·È…ÉuÿuèLâıÿYjX]Ã¡d	VQ°´  ÿØ   PÿuÿƒÄ3À^]ÃU‹ìƒìEVP3ÀPMPQMü‹uQMøQPEôPEğPEìPhd£Vÿuÿuè†3ÿÿƒÄ8ƒøuëU¡d	SWÿvÿ   ÿv ‹ø¡d	ÿ   ÿv$‹Ø¡d	ÿ   ÿuPSÿuÿuüÿuøWÿuôÿuğÿuìÿuè¨BşÿƒÄ8_[^ÉÃU‹ìƒì3ÀVMPQMQPMøPQMôQMğQPEì‹uPEèPEäPhì£Vÿuÿuèã2ÿÿƒÄ@ƒøuël¡d	SWÿvÿ   ÿv ‹ø¡d	ÿ   ÿv$‹Ø¡d	ÿ   ÿv0‰Eü¡d	ÿ   PÿuÿuÿuüSÿuøÿuôÿuğWÿuìÿuèÿuäÿuèáBşÿƒÄD_[^ÉÃh˜¤ÿt$ÿt$ÿt$èT2ÿÿƒÄƒøuÃVÿ˜á‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìì   EWPE‹}Ph°¤ÿuÿuWèı1ÿÿƒÄƒøt#… şÿÿh   Pÿuÿuÿœá…ÀuWè6àıÿYjXëA‹d	VP±´  ÿ‘Ø   PWÿ¡d	fƒeş  şÿÿjÿQ°´  ÿğ  PWÿƒÄ3À^_ÉÃhô¤ÿt$ÿt$ÿt$ès1ÿÿƒÄƒøuÃVÿ á‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^Ãh¥ÿt$ÿt$ÿt$è,1ÿÿƒÄƒøuÃVÿ¤á‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìƒìV‹uj h¥VÿuÿuèŞ0ÿÿƒÄƒøt,ÿv¡d	ÿ   YMğQPÿ@ê…Àtj PÿuèÑıÿƒÄjXë¡d	°´  EğPèšÆıÿPÿuÿƒÄ3À^ÉÃU‹ìƒìV‹uj h4¥Vÿuÿuèf0ÿÿƒÄƒøt,ÿv¡d	ÿ   YMğQPÿDê…Àtj PÿuèÑıÿƒÄjXë¡d	°´  EğPè"ÆıÿPÿuÿƒÄ3À^ÉÃU‹ìƒìSV‹uW‹]3ÿWhX¥VÿuSèê/ÿÿƒÄƒøt;EğP¡d	ÿvÿ   YPÿXê;ÇuEPEğPÿHê;ÇtWPSè‹ĞıÿƒÄjXëJ9}t¡d	jÿÿuÿğ  Y‹ğYÿuÿ0êë¡d	Whœÿè   Y‹ğY¡d	VSÿ´  Y3ÀY_^[ÉÃU‹ìƒìV‹uj hx¥Vÿuÿuè6/ÿÿƒÄƒøt,ÿv¡d	ÿ   YMğQPÿXê…Àtj PÿuèæÏıÿƒÄjXë¡d	°´  EğPèòÄıÿPÿuÿƒÄ3À^ÉÃU‹ìƒì$SV‹uEW3ÛPESPSSh˜¥Vÿu‰]üÿuè®.ÿÿƒÄ$ƒøt`EÜP¡d	ÿvÿ   ‹=XêYPÿ×;Ãu3jEüSPÿvÿuèÔıÿƒÄ…Àu'EìP¡d	ÿvÿ   YPÿ×;ÃtSPÿuè*ÏıÿƒÄjXëÿuEìPEÜÿuÿuüPÿuè{KşÿƒÄ_^[ÉÃU‹ìƒìSV‹uW‹]3ÿWhä¥VÿuSèÿ-ÿÿƒÄƒøt<EğP¡d	ÿvÿ   YPÿXê;ÇuEPEğWPÿDæ;ÇtWPSèŸÎıÿƒÄjXë4¡d	Wÿ5´°¸   ÿuèèşÿƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[ÉÃU‹ìƒìSV‹uWE3ÿ‹]PWWh¦Vÿu‰}üSèT-ÿÿƒÄƒøt@jEüWPÿvSèåÒıÿƒÄ…Àu)EìP¡d	ÿvÿ   YPÿXê;ÇtWPSèğÍıÿƒÄjXëÿuEìPÿuüSèÌJşÿƒÄ_^[ÉÃU‹ìV‹uW‹}j h8¦VÿuWèÓ,ÿÿƒÄƒøt+ÿv¡d	ÿ   MQPè2gşÿƒÄ…Àtj PWè„ÍıÿƒÄjXë5¡d	j ÿ5ì°¸   ÿuèÌşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^]ÃU‹ìƒìSV‹uEôW3Û‹}PSSh`¦Vÿu‰]ø‰]üWè6,ÿÿƒÄƒø„   jEøÿ5ìPÿvWè¾ÑıÿƒÄ…Àt6jEøÿ5$PÿvWè¢ÑıÿƒÄ…ÀtjEøÿ5ìPÿvWè†ÑıÿƒÄëK¡d	Wÿl  EPEP¡d	ÿvWÿ¼   ƒÄƒøt ‹EMü‰EQ…   PSWè[»ıÿƒÄ…ÀtjXëB3ö9]v ‹ESÿ4°¡d	ÿĞ  YY‹Mü‰±F;urà‹Eü‰°ÿuôÿuüÿuÿuøWè¡IşÿƒÄ_^[ÉÃU‹ìQSV‹uW‹]3ÿWhœ¦V‰}üÿuSè+ÿÿƒÄƒøt:jEüWPÿvSè°ĞıÿƒÄ…Àu#9}üu#¡d	Sÿl  YWÿüãPSèÁËıÿƒÄjXë#¡d	Wÿ5´°´  ÿuüè
şÿPSÿƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü hÄ¦Vÿuÿuè‘*ÿÿƒÄƒøtjEüÿ5ÜPÿvÿuèĞıÿƒÄ…ÀtjXëÿuüÿuèšIşÿYY^ÉÃU‹ìQEV‹uPj ƒeü hğ¦Vÿuÿuè3*ÿÿƒÄƒøtjEüÿ5ÜPÿvÿuè½ÏıÿƒÄ…ÀtjXëÿuÿuüÿuètOşÿƒÄ^ÉÃU‹ìQEV‹uPj ƒeü h§VÿuÿuèÑ)ÿÿƒÄƒøtjEüÿ5ÜPÿvÿuè[ÏıÿƒÄ…ÀtjXëÿuÿuüÿuè”RşÿƒÄ^ÉÃU‹ìQQSV‹uW3ÿWWhH§Vÿu‰}ø‰}üÿuèl)ÿÿƒÄƒøt`jEøÿ5ÜPÿvÿuèöÎıÿƒÄ…ÀuBEPEP¡d	ÿvÿuÿ¼   ƒÄƒøt!‹EMü‹ØQ…   PWÿuèÒ¸ıÿƒÄ…ÀtjXë=3ö;ßv‹EWÿ4°¡d	ÿĞ  YY‹Mü‰±F;órá‹Eü‰<°ÿuüSÿuøÿuè‘VşÿƒÄ_^[ÉÃU‹ìQEV‹uPj ƒeü hx§Vÿuÿuèš(ÿÿƒÄƒøtjEüÿ5ÜPÿvÿuè$ÎıÿƒÄ…ÀtjXëÿuÿuüÿuèWşÿƒÄ^ÉÃU‹ìQMV‹uQM3ÀQPPh §V‰Eüÿuÿuè3(ÿÿƒÄ ƒøtjEüÿ50Pÿvÿuè½ÍıÿƒÄ…ÀtjXë#ÿv¡d	ÿ   ÿuÿuPÿuüÿuè@`şÿƒÄ^ÉÃU‹ìV‹uEW‹}Pj hĞ§VÿuWèÂ'ÿÿƒÄƒøt-ÿv¡d	ÿ   YMQÿuPÿ@æ…Àtj PWèqÈıÿƒÄjXë5¡d	j ÿ5ü°¸   ÿuè¹
şÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^]ÃU‹ìƒìVEW‹uPEPE‹}Pj hø§VÿuWè$'ÿÿƒÄ ƒøt;EìPÿvWèœ½ıÿƒÄ…Àu'EüPEìÿuÿuÿuPÿ<æ…Àtj PWèÅÇıÿƒÄjXë5¡d	j ÿ5ü°¸   ÿuüè
şÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW3ÿWWWh4¨V‰}üÿuÿuè&ÿÿƒÄƒøt\jEüÿ5üPÿvÿuèÌıÿƒÄ…Àu>¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   YYPSÿuüÿ8æ;Ç[tWPÿuèÇıÿƒÄjXë3À_^ÉÃU‹ìƒìEVPE‹uPEüPEøPj hl¨Vÿuÿuèå%ÿÿƒÄ$ƒøt>EèPÿvÿuè[¼ıÿƒÄ…Àu(ÿuEèÿuÿuüÿuøPÿ4æ…Àtj PÿuèƒÆıÿƒÄjXë3À^ÉÃU‹ìƒìVEW‹uPEPE‹}Pƒeü j h´¨VÿuWèf%ÿÿƒÄ ƒøt;EìPÿvWèŞ»ıÿƒÄ…Àu'EüPEìÿuÿuÿuPÿ,æ…Àtj PWèÆıÿƒÄjXë%¡d	ÿuü°´  èùµıÿPWÿƒÄÿuüÿXæ3À_^ÉÃU‹ìQV‹uj ƒeü hø¨VÿuÿuèÖ$ÿÿƒÄƒøtjEüÿ5üPÿvÿuè`ÊıÿƒÄ…ÀtjXëÿuüÿuèTşÿYY^ÉÃU‹ìQV‹uW‹}ƒeü j h ©VÿuWèz$ÿÿƒÄƒøt9jEüÿ5ÜPÿvWèÊıÿƒÄ…ÀuEPÿuüÿ(æ…Àtj PWèÅıÿƒÄjXë5¡d	j ÿ5t°¸   ÿuèeşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìƒì(SV3ÛWES‹}PEPEüPShP©WÿuÿuèÎ#ÿÿƒÄ$ƒøtfEØP¡d	ÿwÿ   ‹5XêYPÿÖ;Ãu9EèP¡d	ÿwÿ   YPÿÖ;ÃuEøPEèPEØÿuÿuÿuüPÿ$æ;ÃtSPÿuèDÄıÿƒÄjXë8¡d	Sÿ5t°¸   ÿuøèşÿƒÄP¡d	ÿuÿ   YPÿuÿƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü hœ©Vÿuÿuèÿ"ÿÿƒÄƒøtjEüÿ5tPÿvÿuè‰ÈıÿƒÄ…ÀtjXëÿuüÿuè \şÿYY^ÉÃU‹ìQEV‹uPj ƒeü hÄ©Vÿuÿuè¡"ÿÿƒÄƒøtjEüÿ5|Pÿvÿuè+ÈıÿƒÄ…ÀtjXëÿuÿuüÿuèı\şÿƒÄ^ÉÃU‹ìW‹}hì©ÿuÿuWèJ"ÿÿƒÄƒøtEPj ÿLê…Àtj PWè
ÃıÿƒÄjXë7¡d	Vj ÿ5l°¸   ÿuèQşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À^_]ÃU‹ìV‹uW‹}j hªVÿuWèË!ÿÿƒÄƒøt*ÿv¡d	ÿ   YMQPÿPê…Àtj PWè}ÂıÿƒÄjXë5¡d	j ÿ5˜°¸   ÿuèÅşÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^]ÃU‹ìQV‹uj ƒeü h$ªVÿuÿuè<!ÿÿƒÄƒøt5jEüj PÿvÿuèÊÆıÿƒÄ…ÀuÿuüÿTê…Àtj PÿuèãÁıÿƒÄjXë3À^ÉÃU‹ìƒìEøPh@ªÿuÿuÿuèØ ÿÿƒÄƒøtİEøEèPQQİ$ÿ æ…ÀuÿuèÏıÿYjXÉÃ¡d	V°´  EèPè6²ıÿPÿuÿƒÄ3À^ÉÃU‹ìƒìV‹uW‹}j hhªVÿuWèj ÿÿƒÄƒøt-EèPÿvWè™²ıÿƒÄ…ÀuEøPEèPÿæ…ÀuWè™ÎıÿYjXë3İEø¡d	QQİ$ÿÔ   YY‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìì  SV‹uEWPEü‹]j Pj h”ªVÿuSèÌÿÿƒÄ ƒøtbEP¡d	ÿvSÿ¤   ƒÄ…ÀuHj‹}ÿ5¤EPÿvSè;ÅıÿƒÄ…Àu)…ğıÿÿPÿuÿuÿuüWè\şÿƒÄ…Àtj PSèFÀıÿƒÄjXë#¡d	ğıÿÿjÿQ°´  ÿğ  PSÿƒÄ3À_^[ÉÃU‹ìì  V‹uEWPE‹}Pj hÈªVÿuWèÿÿƒÄƒøt=EP¡d	ÿvWÿ¤   ƒÄ…Àu#…ôıÿÿPÿuÿuÿuè
[şÿƒÄ…ÀuWè*ÍıÿYjXë#¡d	ôıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìV‹uEW‹}Pj h«VÿuWèzÿÿƒÄƒøt:EP¡d	ÿvWÿ¤   ƒÄ…Àu EPÿuÿuÿìæ…Àtj PWè¿ıÿƒÄjXë+ƒ} t#¡d	ÿu°´  è7³ıÿPWÿƒÄÿuÿ0ê3À_^]ÃU‹ìì  V‹uW‹}ƒeü j h<«VÿuWèŞÿÿƒÄƒøt/EüPÿvWè³ıÿƒÄ…Àu…ğıÿÿPÿuüÿğæ…ÀuWèÌıÿYjXë#¡d	ğıÿÿjÿQ°´  ÿğ  PWÿƒÄ3À_^ÉÃU‹ìQQV‹uW3ÿWEøWPWh`«VÿuÿuèWÿÿƒÄ ƒøtnEP¡d	ÿvÿuÿ¤   ƒÄ…ÀuR¡d	Sÿv‹]ÿ   ‰EüEP¡d	ÿv‰}ÿĞ  ƒÄ9}u3ÀPÿuüÿuøSèôYşÿƒÄ…À[uÿuèEËıÿYjXë3À_^ÉÃU‹ìV‹uj j hœ«VÿuÿuèºÿÿƒÄƒøt`EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuD¡d	Wÿv‹}ÿ   PWè şÿƒÄ…À_u(ÿu¡d	ÿl  Yj ÿüãPÿuè6½ıÿƒÄjXë%‹d	j ÿ5@±´  PèÿıÿPÿuÿƒÄ3À^]ÃU‹ìV‹uj hÀ«VÿuÿuèÿÿƒÄƒøtjEÿ5@Pÿvÿuè•ÁıÿƒÄ…ÀtjXëÿuè¯şÿY3À^]Ãhà«ÿt$ÿt$ÿt$è¼ÿÿƒÄƒøuÃVèÑşÿ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^Ãhø«ÿt$ÿt$ÿt$èvÿÿƒÄƒøuÃVè×şÿ‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^Ãh¬ÿt$ÿt$ÿt$è0ÿÿƒÄƒøuÃÿt$èÚşÿYÃU‹ìQQEV‹uPEPEüPj h(¬VÿuÿuèôÿÿƒÄ ƒøtjEøÿ5@Pÿvÿuè~ÀıÿƒÄ…ÀtjXëÿuÿuÿuüÿuøÿuègşÿƒÄ^ÉÃU‹ìƒìdVEWP‹uEPE‹}Pj j hd¬VÿuWè‚ÿÿƒÄ$ƒøtcjEøÿ5@PÿvWèÀıÿƒÄ…ÀuGjEüÿ5¤PÿvWèò¿ıÿƒÄ…Àu+EœPÿuÿuÿuÿuüÿuøè¢şÿƒÄ…Àtj PWèûºıÿƒÄjXë¡d	°´  EœPè;şÿPWÿƒÄ3À_^ÉÃU‹ìEPh¤¬ÿuÿuÿuè×ÿÿƒÄƒøu]Ãÿuÿuè¡WşÿYY]ÃhÈ¬ÿt$ÿt$ÿt$è¨ÿÿƒÄƒøuÃÿt$èbUşÿYÃU‹ìƒì V3öWEìVPEèVP‹}EäVPVVVVVhè¬Wÿu‰uôÿuè_ÿÿƒÄ<ƒø„*  ÿw¡d	ÿ   ‰EàEP¡d	ÿw‰uÿĞ  ƒÄ9u‰Eğu‰uğEôPÿwÿuèf®ıÿƒÄ…À…Ü   E‰uP¡d	ÿwÿĞ  9uYY‰Eøu‰uøE‰uP¡d	ÿwÿĞ  9uYY‰Eüu‰uüE‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uESP¡d	ÿw$‰uÿĞ  9uYY‹Øu3ÛE‰uP¡d	ÿw,ÿĞ  9uYYu3ÀPÿuìSÿuèÿuÿuäÿuüÿuøÿuôÿuğÿuàèÕ’şÿƒÄ,;Æ[tVPÿuè¹ıÿƒÄjXë3À_^ÉÃU‹ìQV‹uEWPEüj Pj h€­VÿuÿuèøÿÿƒÄ ƒøt,ÿv¡d	ÿ   ‹øEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXëÿuÿuÿuüWÿuè±“şÿƒÄ_^ÉÃU‹ìEV‹uPj j hÈ­Vÿuÿuè†ÿÿƒÄƒøt?¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   ÿuPSèû–şÿƒÄ…À[tj Pÿuè#¸ıÿƒÄjXë3À^]ÃV‹t$j h ®Vÿt$ÿt$èÿÿƒÄƒøu^Ãÿv¡d	ÿ   Pÿt$è —şÿƒÄ^ÃU‹ìQSV‹uEj Pj j h(®VÿuÿuèĞÿÿƒÄ ƒøtaÿv¡d	ÿ   ÿv‹Ø¡d	ÿ   ‰EüEP¡d	ÿvÿuÿ¤   ƒÄ…Àu$ÿuÿuÿuüSè`—şÿƒÄ…Àtj PÿuèK·ıÿƒÄjXë3À^[ÉÃU‹ìQEV‹uP3ÀMüPPQPhh®Vÿuÿuè6ÿÿƒÄ$ƒøt_EP¡d	ÿvÿuÿ¤   ƒÄ…ÀuC¡d	SW‹}ÿvÿ   ÿv‹Ø¡d	ÿ   YYÿuPSÿuüWÿôæ_[…Àuÿuè3ÄıÿYjXë3À^ÉÃU‹ìƒìSVW‹u3ÿEøWPWEôWPWh¨®VÿuÿuèšÿÿƒÄ(ƒø„Ï   EüP¡d	ÿvÿuÿ¤   ƒÄ…À…¯   ‹Eüÿv‰Eğ¡d	ÿ   ‹=Üä»,$SP‰Eÿ×ƒÄ…Àu!EëEPÿvÿuè@­ıÿƒÄƒøtdÿv¡d	ÿ   SP‰Eÿ×ƒÄ…Àu1!Eÿv¡d	ÿ   Pÿuøÿuÿuÿuôÿuğÿuè¼™şÿƒÄ _^[ÉÃEPÿvÿuèÜ¬ıÿƒÄƒøu»3ÿ9}‹5åtÿuÿÖY9}tÿuÿÖYjXëÁU‹ìQEV‹uPj ƒeü hô®Vÿuÿuè{ÿÿƒÄƒøtjEüÿ5XPÿvÿuèºıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰3À^ÉÃU‹ìQV‹uj ƒeü h4¯Vÿuÿuè ÿÿƒÄƒøtjEüÿ5XPÿvÿuèª¹ıÿƒÄ…ÀtjXë"‹Eü‹¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hd¯Vÿuÿuè­ÿÿƒÄƒøtjEüÿ5XPÿvÿuè7¹ıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h¤¯VÿuÿuèQÿÿƒÄƒøtjEüÿ5XPÿvÿuèÛ¸ıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hÔ¯VÿuÿuèİÿÿƒÄƒøtjEüÿ5XPÿvÿuèg¸ıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h°VÿuÿuèÿÿƒÄƒøtjEüÿ5XPÿvÿuè¸ıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hP°VÿuÿuèÿÿƒÄƒøtjEüÿ5XPÿvÿuè—·ıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h”°Vÿuÿuè±ÿÿƒÄƒøtjEüÿ5XPÿvÿuè;·ıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hÈ°Vÿuÿuè=ÿÿƒÄƒøtjEüÿ5XPÿvÿuèÇ¶ıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h ±VÿuÿuèáÿÿƒÄƒøtjEüÿ5XPÿvÿuèk¶ıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü h\±VÿuÿuèmÿÿƒÄƒøtjEüÿ5XPÿvÿuè÷µıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h˜±VÿuÿuèÿÿƒÄƒøtjEüÿ5XPÿvÿuè›µıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj ƒeü hÈ±VÿuÿuèÿÿƒÄƒøtjEüÿ5XPÿvÿuè'µıÿƒÄ…ÀtjXë‹Eü…Àt‹M‰H3À^ÉÃU‹ìQV‹uj ƒeü h ²VÿuÿuèAÿÿƒÄƒøtjEüÿ5XPÿvÿuèË´ıÿƒÄ…ÀtjXë#‹Eü‹H¡d	Q°´  ÿØ   PÿuÿƒÄ3À^ÉÃU‹ìh,²ÿuÿuÿuèÚÿÿƒÄƒøu]ÃVjjÿÌä‹d	j ÿ5X±´  PÿuèÅÿÿPÿuÿƒÄ 3À^]ÃU‹ìQV‹uj ƒeü hH²Vÿuÿuè{ÿÿƒÄƒøtjEüÿ5XPÿvÿuè´ıÿƒÄ…ÀtjXëÿuüÿåY3À^ÉÃÿt$ÿåYÃU‹ìQQSV‹uWEø3ÿPWWhl²V‰}üÿu3ÛÇEø?  ÿuèÿÿƒÄƒø„   ƒ}~"E‰}P¡d	ÿvÿĞ  9}YY‰Eüu‰}üƒ}~ E‰}P¡d	ÿvÿĞ  9}YY‹Øu3ÛÿuøSÿuüÿŒà;Çu'ÿu¡d	ÿl  YWÿüãPÿuè\®ıÿƒÄjXë$‹d	Wÿ5¬±´  Pè¦ğıÿPÿuÿƒÄ3À_^[ÉÃU‹ìSV‹uW‹}j h¸²VÿuWè-ÿÿƒÄƒøtCjEÿ5¬PÿvWè¹²ıÿƒÄ…Àu'ÿuÿˆà‹Ø…Ûuÿüã=  tSPWèÆ­ıÿƒÄjXë"¡d	j ÿ5è°´  SèğıÿPWÿƒÄ3À_^[]ÃU‹ìV‹uj hà²VÿuÿuèœÿÿƒÄƒøt4jEÿ5èPÿvÿuè&²ıÿƒÄ…Àuÿuÿ„à…ÀuÿuèÄºıÿYjXë3À^]ÃU‹ìSV‹uW‹]3ÿWh0³VÿuSè8ÿÿƒÄƒøt<jEÿ5¬PÿvSèÄ±ıÿƒÄ…Àu ÿuè#  ‹ğY;÷WuÿüãPSèØ¬ıÿƒÄjXéş   ¡d	WÿÜ   ‹ø¡d	j	h$³ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿ6ˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh³ˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ@…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jh³ˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	WSÿ´  ƒÄ@VÿåY3À_^[]ÃU‹ìQEüV‹5€àPj j ÿuÿÖ…Àuÿüãƒøzt3Àë/Wÿuüÿ$å‹øY…ÿtEüPÿuüWÿuÿÖ…Àu
WÿåY3ÿ‹Ç_^ÉÃU‹ìQV‹uEüW‹}Pj j h\³VÿuÇEüÿ Wèb
ÿÿƒÄƒøt[jEÿ5¬PÿvWèî¯ıÿƒÄ…Àu?ÿv¡d	ÿ   YÿuüPÿuÿ|à…Àu$¡d	Wÿl  Yj ÿüãPWèãªıÿƒÄjXë#‹d	j ÿ5¬±´  Pè,íıÿPWÿƒÄ3À_^ÉÃU‹ìƒì(SVW3ÿWWWWWEğWPEì‹uPEèPEäP‹]WWWh¨³V‰}üÿuSè—	ÿÿƒÄDƒø„T  jEØÿ5¬PÿvSè¯ıÿƒÄ…À…4  ÿv¡d	ÿ   ÿv‰EÜ¡d	ÿ   ÿv ‰Eà¡d	ÿ   ÿv$‰Eô¡d	ÿ   j‰Eøÿ5dEüPÿv(Sè»®ıÿƒÄ$…À…Ğ   ÿv,¡d	ÿ   Ç$,$P‰EÿÜäY…ÀYu‰}ëEPÿv,Sèã ıÿƒÄƒø„   E‰}P¡d	ÿv0ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿv4ÿĞ  9}YYu3ÀPSÿuÿuüÿuøÿuôÿuğÿuìÿuèÿuäÿuàÿuÜÿuØÿxà;Çu6ÿu¡d	ÿl  YWÿüãPÿuè©ıÿƒÄ9}t
ÿuÿåYjXë3‹d	Wÿ5¬±´  PèVëıÿPÿuÿƒÄ9}t
ÿuÿåY3À_^[ÉÃU‹ìV‹uj h„´VÿuÿuèÑÿÿƒÄƒøt4jEÿ5¬Pÿvÿuè[­ıÿƒÄ…Àuÿuÿtà…ÀuÿuèùµıÿYjXë3À^]ÃU‹ìQQSV‹uW3ÿWWh¤´Vÿu‰}üÿuèhÿÿƒÄƒø„©   jEøÿ5¬Pÿvÿuèî¬ıÿƒÄ…À…‡   EPEP¡d	ÿvÿuÿ¼   ƒÄƒøtf‹EMü‹ØQ…   PWÿuèÆ–ıÿƒÄ…ÀuE3ö;ßv‹EWÿ4°¡d	ÿĞ  YY‹Mü‰±F;órá‹Eü‰<°ÿuüSÿuøÿpà…ÀuÿuèµıÿY9}üt
ÿuüÿåYjXë9}üt
ÿuüÿåY3À_^[ÉÃU‹ìQV‹u3ÀWM‹}PQPhĞ´V‰EüÿuWècÿÿƒÄƒøtRjEÿ5¬PÿvWèï«ıÿƒÄ…Àu6jEüÿ5\PÿvWèÓ«ıÿƒÄ…Àuÿuüÿuÿuÿlà…ÀuWèm´ıÿYjXë3À_^ÉÃU‹ìQV‹u3ÀW‹}PPhµV‰EüÿuWèÜÿÿƒÄƒøtOjEÿ5¬PÿvWèh«ıÿƒÄ…Àu3jEüÿ5\PÿvWèL«ıÿƒÄ…Àuÿuüÿuÿhà…ÀuWèé³ıÿYjXë3À_^ÉÃU‹ìSV‹uW‹]3ÿWhÈµVÿuSè\ÿÿƒÄƒø„æ  jEÿ5¬PÿvSèäªıÿƒÄ…À…Æ  ÿuèï  ‹ğY;÷WuÿüãPSèô¥ıÿƒÄé¡  ¡d	WÿÜ   ‹ø¡d	jhğJˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿ6ˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh¼µˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄ@ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh¬µˆ¸   ‰Mÿè   P‹EWSÿ¡d	ÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jh¤µˆ¸   ‰Mÿè   P‹EWSÿ¡d	ƒÄHÿvˆ¸   ‰Mÿà   P‹EWSÿ¡d	jhµˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ$…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jh|µˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ(…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jhhµˆ¸   ‰Mÿè   P‹EWSÿ‹FƒÄ(…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jhXµˆ¸   ‰Mÿè   P‹EWSÿ‹F ƒÄ(…À‹Èu¹ô¡d	jÿQ¸   ‰Uÿğ  P‹EWSÿ¡d	jÿhHµˆ¸   ‰Mÿè   P‹EWSÿÿvSè››ıÿƒÄ0…ÀuWè]°ıÿYjXë'P¡d	WSÿ¸   ¡d	WSÿ´  VÿåƒÄ3À_^[]ÃU‹ìQEüV‹5dàPj j ÿuÿÖ…Àuÿüãƒøzt3Àë/Wÿuüÿ$å‹øY…ÿtEüPÿuüWÿuÿÖ…Àu
WÿåY3ÿ‹Ç_^ÉÃU‹ìSV‹u‹]Wj j hğµVÿuSè½ÿÿƒÄƒøtMjEÿ5¬PÿvSèI§ıÿƒÄ…Àu1ÿv¡d	ÿ   Pÿuèù‰şÿ‹øƒÄ…ÿuPÿüãPSèL¢ıÿƒÄjXë$¡d	jÿW°´  ÿğ  PSÿWÿåƒÄ3À_^[]ÃU‹ìSV‹u‹]Wj j h¶VÿuSèÿÿƒÄƒøtMjEÿ5¬PÿvSè§¦ıÿƒÄ…Àu1ÿv¡d	ÿ   PÿuèĞ‰şÿ‹øƒÄ…ÿuPÿüãPSèª¡ıÿƒÄjXë$¡d	jÿW°´  ÿğ  PSÿWÿåƒÄ3À_^[]ÃU‹ìƒì SVW3ÿWWWWWWEìW‹uPEè‰}øPEäPWhL¶Vÿuÿuèb ÿÿƒÄ<ƒø„X  jEàÿ5¬Pÿvÿuèè¥ıÿƒÄ…À…6  ÿv¡d	ÿ   ‹=Üä»,$SP‰Eğÿ×ƒÄ…Àu!Eğÿv¡d	ÿ   SP‰Eôÿ×ƒÄ…Àu!EôjEøÿ5dPÿvÿuè}¥ıÿƒÄ…À…É   ÿv ¡d	ÿ   SP‰Eÿ×ƒÄ…Àu!EëEPÿv ÿuè¬—ıÿƒÄƒø„   ÿv$¡d	ÿ   SP‰Eüÿ×ƒÄ…Àu!Eüÿv(¡d	ÿ   SP‰Eÿ×ƒÄ…Àu!Eÿv,¡d	ÿ   ‹ğSVÿ×ƒÄ…Àu3öVÿuÿuüÿuÿuøÿuôÿuğÿuìÿuèÿuäÿuàÿ`à…Àuÿuèd­ıÿY3ÿ9}t
ÿuÿåYjXëƒ} t
ÿuÿåY3À_^[ÉÃU‹ìQEV‹uPEPj h·Vÿuÿuè°şşÿƒÄƒøtjEüÿ5¬Pÿvÿuè:¤ıÿƒÄ…ÀtjXëÿuÿuÿuüÿuè   ƒÄ^ÉÃU‹ìƒìEôW3ÿPh }  Wÿu‰}ğèıÿƒÄ…ÀtjXéÇ   ¡d	SVWWÿÜ   Y‰EøYEğ‰}üPEüPEèPh }  ÿuôÿuÿuÿuÿ\à;Ç‰Eìuÿüã‹ğşê   u;3Û9}üv-¡d	°¸   ‹EôÇPè\   PÿuøÿuÿƒÄCƒÇ$;]ürÕ3ÿ9}ìuëˆÿuøèŸ«ıÿWVÿuè„ıÿƒÄj_ëÿuø¡d	ÿuÿ´  YYÿuôÿåY^‹Ç[_ÉÃ¡d	SUV3ÛW‹|$SSÿÜ   ‹ğ¡d	jhP·¨¸   ÿè   PVSÿU ‹ƒÄ;Ã‹Èu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhXµ¨¸   ÿè   PVSÿU ‹OƒÄ(;Ëu¹ô¡d	jÿQ¨¸   ÿğ  PVSÿU ¡d	jhğJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhàJ¨¸   ÿè   ƒÄ@PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	jhÌJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄ@jh¼J¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	¨¸   jh Jÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	ƒÄHjhJ¨¸   ÿè   PVSÿU ¡d	ÿw¨¸   ÿà   PVSÿU ¡d	j
h„J¨¸   ÿè   PVSÿU ¡d	ÿw ¨¸   ÿà   PVSÿU ƒÄH‹Æ_^][ÃU‹ìQQVEj ‹uPEPEüPj h`·Vÿuÿuè
ûşÿƒÄ$ƒøtjEøÿ5¬Pÿvÿuè” ıÿƒÄ…ÀtjXë>ÿv¡d	ÿ   ‹ğÇ$,$VÿÜäY…ÀYu3öVÿuÿuÿuüÿuøÿuè   ƒÄ^ÉÃU‹ìƒìW3ÿ9}t$¡d	Wh¼·ÿuÿ¨  WjWÿuèR›ıÿƒÄëEø‰}ôPh }  WÿuèŠıÿƒÄ…ÀtjXéË   ¡d	SVWWÿÜ   Y‰EüYÿuEô‰}PEPEìPh }  ÿuøÿuÿuWÿuÿXà;Ç‰Eğuÿüã‹ğşê   u;3Û9}v-¡d	°¸   ‹EøÇPè\   PÿuüÿuÿƒÄCƒÇ,;]rÕ3ÿ9}ğuë„ÿuüè¢§ıÿWVÿuè‡šıÿƒÄj_ëÿuü¡d	ÿuÿ´  YYÿuøÿåY^‹Ç[_ÉÃ¡d	SUV3íWUUÿÜ   ‹ğ¡d	jhP·¸¸   ÿè   PVUÿ‹|$0ƒÄ‹;Å‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVUÿ¡d	jhXµ˜¸   ÿè   PVUÿ‹GƒÄ(;Å‹Èu¹ô¡d	jÿQ˜¸   ÿğ  PVUÿƒÇVWè)şÿƒÄ‹Æ_^][ÃU‹ìEV‹uPj hÜ·Vÿuÿuè¢øşÿƒÄƒøtjEÿ5¬Pÿvÿuè,ıÿƒÄ…ÀtjXëÿuÿuÿuè   ƒÄ^]ÃU‹ìƒìVMüW¸   Q3ÿPWÿu‰Eøè
ˆıÿƒÄ…ÀucEô‹5TàPEøPÿuøÿuüÿuÿuÿÖ…ÀuHÿüã=ê   u;ÿuüÿåEüPÿuøWÿuè½‡ıÿƒÄ…ÀuEôPEøPÿuøÿuüÿuÿuë·jXëe¡d	SWWÿÜ   Y3Û9}ôY‰Ev+¡d	°¸   ‹EüÇPè-úÿÿPÿuÿuÿƒÄCƒÇ$;]ôrÕÿu¡d	ÿuÿ´  ÿuüÿåƒÄ3À[_^ÉÃU‹ìV‹uj h¸VÿuÿuèQ÷şÿƒÄƒøt4jEÿ5¬PÿvÿuèÛœıÿƒÄ…ÀuÿuÿPà…Àuÿuèy¥ıÿYjXë3À^]ÃU‹ìEV‹uPj h<¸VÿuÿuèíöşÿƒÄƒøtjEÿ5¬PÿvÿuèwœıÿƒÄ…ÀtjXëÿuÿuÿuè¡|şÿƒÄ^]ÃU‹ìQQSEV‹uPEø3ÛPShh¸V‰]üÿuÿuè…öşÿƒÄƒøt$E‰]PEüP¡d	ÿvÿuÿ¼   ƒÄƒøujXëR‹EüW…   Pÿ$å3ö9]üY‹ø~‹ESÿ4°¡d	ÿ¬   ‰·F;uüYY|ã‰·ÿuÿuøWÿuüÿuè¼É  ƒÄ_^[ÉÃU‹ìƒìEPEPEüPEøPEôPEğPh¨¸ÿuÿuÿuèÍõşÿƒÄ(ƒøt'ÿuÿuÿuüÿuøÿuôÿuğè÷Ë  ƒÄ…Àuÿuè¤ıÿYjXÉÃ3ÀÉÃU‹ìEPh¹ÿuÿuÿuè{õşÿƒÄƒøu]ÃÿuÿuèÌ  YY]ÃU‹ìV‹uW3ÿWWh0¹VÿuÿuèEõşÿƒÄƒøt_ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSÿLà;Ç[u'ÿu¡d	ÿl  YWÿüãPÿuèÂ•ıÿƒÄjXë$‹d	Wÿ5¤±´  PèØıÿPÿuÿƒÄ3À_^]ÃU‹ìƒì SV3ÛWSSEìS‹}PEè‹uPEäPShd¹Wÿu‰]üVè~ôşÿƒÄ,ƒø„è   jEàÿ5¤PÿwVèšıÿƒÄ…À…È   EPÿwVèu¥ıÿƒÄ…À…°   EôPEøP¡d	ÿwVÿ¼   ƒÄƒø„   ‹EøMü‰EQ…   PSVèÅƒıÿƒÄ…Àum3ö9]v ‹EôSÿ4°¡d	ÿĞ  YY‹Mü‰±F;urà‹Eü‰°EğP¡d	ÿwÿŒ   Pÿuğÿuüÿuÿuÿuìÿuèÿuäÿuàè¡|şÿƒÄ,…Àu*ÿuèî¡ıÿY9]‹5åtÿuÿÖY9]ütÿuüÿÖYjXë9]‹5åtÿuÿÖY9]ütÿuüÿÖY3À_^[ÉÃU‹ìV‹uj hÈ¹Vÿuÿuè,óşÿƒÄƒøt4jEÿ5¤Pÿvÿuè¶˜ıÿƒÄ…ÀuÿuÿHà…ÀuÿuèT¡ıÿYjXë3À^]ÃU‹ìV‹uW3ÿWWhô¹VÿuÿuèÉòşÿƒÄƒøt_ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSÿDà;Ç[u'ÿu¡d	ÿl  YWÿüãPÿuèF“ıÿƒÄjXë$‹d	Wÿ5¤±´  PèÕıÿPÿuÿƒÄ3À_^]ÃU‹ìV‹uW3ÿWWh(ºVÿuÿuèòşÿƒÄƒøt_ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YPSÿ@à;Ç[u'ÿu¡d	ÿl  YWÿüãPÿuè•’ıÿƒÄjXë$‹d	Wÿ5¤±´  PèßÔıÿPÿuÿƒÄ3À_^]ÃU‹ìQEV‹uPEPj h`ºVÿuÿuèañşÿƒÄƒøtjEüÿ5¤Pÿvÿuèë–ıÿƒÄ…ÀtjXëÿuÿuÿuüÿuè€zşÿƒÄ^ÉÃU‹ìV‹uj hŒºVÿuÿuèñşÿƒÄƒøt4jEÿ5¤Pÿvÿuè–ıÿƒÄ…Àuÿuÿ<à…Àuÿuè-ŸıÿYjXë3À^]ÃU‹ìV‹uj j h°ºVÿuÿuè£ğşÿƒÄƒøtDjEÿ5¤Pÿvÿuè-–ıÿƒÄ…Àu&ÿv¡d	ÿ   YPÿuÿ8à…Àuÿuè»ıÿYjXë3À^]ÃU‹ìV‹uj j häºVÿuÿuè1ğşÿƒÄƒøtTjEÿ5¤Pÿvÿuè»•ıÿƒÄ…Àu6!EEP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuÿ4à…Àuÿuè9ıÿYjXë3À^]ÃU‹ìV‹uW‹}j h»VÿuWè¯ïşÿƒÄƒøt4jEÿ5¤PÿvWè;•ıÿƒÄ…ÀuEPÿuÿ0à…ÀuWè×ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìV‹uW‹}j hH»VÿuWè!ïşÿƒÄƒøt4jEÿ5¤PÿvWè­”ıÿƒÄ…ÀuEPÿuÿ,à…ÀuWèIıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìV‹uW‹}j ht»VÿuWè“îşÿƒÄƒøt5jEÿ5¤PÿvWè”ıÿƒÄ…ÀuEPÿuèwşÿY…ÀYuWèºœıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]Ãhœ»ÿt$ÿt$ÿt$è
îşÿƒÄƒøtÿ¨á…Àuÿt$èRœıÿYjXÃ3ÀÃU‹ìQSVE‹uW3ÿPEWP‹]EPh´»V‰}üÿuSè¹íşÿƒÄ ƒøtIEüPÿvSèÓ&ÿÿƒÄ…Àu5Wÿuÿuüÿuÿuÿ¬á;Çu1¡d	Sÿl  YWÿüãPSèLıÿƒÄ9}üt	ÿuüèi&ÿÿYjXë0‹d	Wÿ5¤±´  PèˆĞıÿPSÿƒÄ9}üt	ÿuüè6&ÿÿY3À_^[ÉÃU‹ìQQV‹uWEj PE‹}Pƒeü j h¼VÿuWèôìşÿƒÄ ƒøtMjEüj PÿvWè„’ıÿƒÄ…Àu5EPÿvWè^   ƒÄ…Àu!EøPÿuÿuÿuÿuüÿ°á…ÀuWè›ıÿYjXë-ÿuø¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQQEV‹uPEP¡d	ÿuVÿ¼   ƒÄ…À…‚   ƒ}ubEüP‹Eÿ0¡d	Vÿ    ƒÄ…ÀuFEøP‹Eÿp¡d	Vÿ    ƒÄ…Àu)‹Uü…Ò|"¸ÿ  ;Ğ‹Mø…É|;È‹Ef‰f‰H3Àë…öt¡d	j hl¼Vÿ¨  ƒÄjX^ÉÃU‹ìQSV‹uW3ÿEW‹]PWWhÌ¼V‰}üÿuSèëşÿƒÄ ƒøt[jEüWPÿvSè‘ıÿƒÄ…ÀuDÿv¡d	ÿ   f‹8EPÿvSèèşÿÿƒÄ…ÀuEPÿuÿuWÿuüÿ´á…ÀuSè™ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü h ½VÿuÿuèÕêşÿƒÄƒøt0jEüj PÿvÿuècıÿƒÄ…Àuÿuüÿ¸á…Àuÿuè™ıÿYjXë3À^ÉÃhP½ÿt$ÿt$ÿt$è}êşÿƒÄƒøtÿ¼á…Àuÿt$èÅ˜ıÿYjXÃ3ÀÃU‹ìEPEPhd½ÿuÿuÿuè<êşÿƒÄƒøtÿuÿuÿÀá…Àuÿuè˜ıÿYjX]Ã3À]Ãh¤½ÿt$ÿt$ÿt$èüéşÿƒÄƒøuÃVÿÄá‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìQV‹uW‹}ƒeü j h¼½VÿuWèªéşÿƒÄƒøt0jEüj PÿvWè:ıÿƒÄ…ÀuEPÿuüÿÈá…ÀuWèÖ—ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃhä½ÿt$ÿt$ÿt$è&éşÿƒÄƒøuÃVÿÌá‹d	P±´  ÿ‘Ø   Pÿt$ÿƒÄ3À^ÃU‹ìƒìV‹uW‹}ƒeü j h ¾VÿuWèÒèşÿƒÄƒøt0jEüj PÿvWèbıÿƒÄ…ÀuEäPÿuüÿĞá…ÀuWèş–ıÿYjXë¡d	°´  EäPWè   PWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}VWèU   ‰EìFPWèH   ‰Eğ·FP¡d	ÿØ   ‰EôF
PWèm   ƒÆ‰EøVWè   ‰EüEìP¡d	jÿÜ   ƒÄ,_^ÉÃU‹ìQQV‹u¿P¡d	ÿØ   ‰Eø¿FP¡d	ÿØ   ‰EüEøP¡d	jÿÜ   ƒÄ^ÉÃU‹ìƒìV‹u¿P¡d	ÿØ   ‰Eğ¿FP¡d	ÿØ   ‰Eô¿FP¡d	ÿØ   ‰Eø¿FP¡d	ÿØ   ‰EüEğP¡d	jÿÜ   ƒÄ^ÉÃU‹ìì  h4¾ÿuÿuÿuè<çşÿƒÄƒøt…øıÿÿh  PÿÔá…Àuÿuèy•ıÿYjXÉÃ¡d	fƒeş VøıÿÿjÿQ°´  ÿğ  PÿuÿƒÄ3À^ÉÃU‹ìƒìV‹uh`¾ÿuÿuVèÇæşÿƒÄƒøt,ÿØá…Àu'Wÿüã‹ø¡d	Vÿl  j WVèx‡ıÿƒÄ_jXë'PEìh¸#PÿüäEìjP¡d	Vÿ¨  ƒÄ3À^ÉÃU‹ìQSV‹uW‹]3ÿWh|¾V‰}üÿuSèBæşÿƒÄƒøt?jEüWPÿvSèÓ‹ıÿƒÄ…Àu(ÿuüÿÜáf;Ç‰Euf9}uWÿüãPSèß†ıÿƒÄjXë¡d	°´  EPSèØıÿÿPSÿƒÄ3À_^[ÉÃU‹ìQV‹uW‹}ƒeü j h°¾VÿuWè²åşÿƒÄƒøt0jEüj PÿvWèB‹ıÿƒÄ…ÀuEPÿuüÿàá…ÀuWèŞ“ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìW‹}hè¾ÿuÿuWè,åşÿƒÄƒøtEPÿäá…ÀuWès“ıÿYjXë/¡d	VÿuÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À^_]ÃU‹ìEW‹}Ph¿ÿuÿuWè¼äşÿƒÄƒøt,ÿuèÄpşÿ…ÀYu$¡d	Wÿl  Yj ÿüãPWèl…ıÿƒÄjXë%‹d	Vj ÿ5¤±´  Pè´ÇıÿPWÿƒÄ3À^_]ÃU‹ìEPh4¿ÿuÿuÿuèAäşÿƒÄƒøtÿuÿèá…Àuÿuè‡’ıÿYjX]Ã3À]ÃU‹ìQS‹]V‹uj ƒeü j hX¿VÿuSè÷ãşÿƒÄƒøtCjEüj PÿvSè‡‰ıÿƒÄ…Àu+EPÿvSèa÷ÿÿƒÄ…Àuÿuÿuüÿìá…ÀuSè’ıÿYjXë3À^[ÉÃU‹ìQEV‹uPj ƒeü hœ¿Vÿuÿuè~ãşÿƒÄƒøt3jEüj Pÿvÿuè‰ıÿƒÄ…Àuÿuÿuüÿğá…Àuÿuè§‘ıÿYjXë3À^ÉÃU‹ìEPhÌ¿ÿuÿuÿuèãşÿƒÄƒøtÿuÿôá…Àuÿuèe‘ıÿYjX]Ã3À]ÃU‹ìQS‹]V‹uj ƒeü j hô¿VÿuSèÕâşÿƒÄƒøtCjEüj PÿvSèeˆıÿƒÄ…Àu+EPÿvSè?öÿÿƒÄ…Àuÿuÿuüÿøá…ÀuSèîıÿYjXë3À^[ÉÃU‹ìQEV‹uPj ƒeü h0ÀVÿuÿuè\âşÿƒÄƒøt3jEüj Pÿvÿuèê‡ıÿƒÄ…Àuÿuÿuüÿüá…Àuÿuè…ıÿYjXë3À^ÉÃV‹t$j hpÀVÿt$ÿt$èıáşÿƒÄƒøt$ÿv¡d	ÿ   YPÿ â…Àuÿt$è5ıÿYjX^Ã3À^ÃU‹ìƒìSV‹uE‹]j Pƒeü j h˜ÀVÿuSèŸáşÿƒÄƒøtGjEüj PÿvSè/‡ıÿƒÄ…Àu/EôPÿvSè-   ƒÄ…ÀuEôPÿuÿuüÿâ…ÀuSè´ıÿYjXë3À^[ÉÃU‹ìƒìEV‹uPEP¡d	ÿuVÿ¼   ƒÄƒøtƒ}t¡d	j häÀVÿ¨  ƒÄjX^ÉÃEüP‹Eÿ0¡d	Vÿ    ƒÄ…ÀuŞEøP‹Eÿp¡d	Vÿ    ƒÄ…ÀuÁEôP‹Eÿp¡d	Vÿ    ƒÄ…Àu¤EğP‹Eÿp¡d	Vÿ    ƒÄ…Àu‡‹Ef‹Müf‰f‹Møf‰Hf‹Môf‰Hf‹Mğf‰H3ÀéaÿÿÿU‹ìQV‹uEj Pƒeü h$ÁVÿuÿuè;àşÿƒÄƒøt3jEüj PÿvÿuèÉ…ıÿƒÄ…Àuÿuüÿuÿâ…ÀuÿuèdıÿYjXë3À^ÉÃU‹ìQSEV‹u‹]Pj ƒeü j hPÁVÿuSèÏßşÿƒÄƒøtDjEüj PÿvSè_…ıÿƒÄ…Àu,ÿv¡d	ÿ   MQÿuPÿuüèkşÿƒÄ…ÀuSèçıÿYjXë-ÿu¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À^[ÉÃU‹ìQSV‹uW3ÿ‹]WWWh˜ÁV‰}üÿuSè)ßşÿƒÄƒøt^jEüWPÿvSèº„ıÿƒÄ…ÀuGEP¡d	ÿvÿĞ  ‹øEPÿvSè€òÿÿƒÄ…ÀuEPÿuÿuWÿuüÿâ…ÀuSè'ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü hèÁVÿuÿuèmŞşÿƒÄƒøt0jEüj PÿvÿuèûƒıÿƒÄ…Àuÿuüÿâ…Àuÿuè™ŒıÿYjXë3À^ÉÃU‹ìQEV‹uPj ƒeü hÂVÿuÿuèŞşÿƒÄƒøtjEüj Pÿvÿuè–ƒıÿƒÄ…ÀtjXëÿuÿuüÿuè	jşÿƒÄ^ÉÃU‹ìEPEPh<Âÿuÿuÿuè¯İşÿƒÄƒøu]Ãÿuÿuÿuè!ç  ƒÄ]ÃhtÂÿt$ÿt$ÿt$è|İşÿƒÄƒøuÃÿt$èÚç  YÃU‹ìW‹}hœÂÿuÿuWèPİşÿƒÄƒøtEPèmrşÿ…ÀYtj PWè~ıÿƒÄjXë/¡d	VÿuÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À^_]ÃV‹t$j h¸ÂVÿt$ÿt$èİÜşÿƒÄƒøt)ÿv¡d	ÿ   PèrşÿY…ÀYtj Pÿt$è}ıÿƒÄjX^Ã3À^ÃU‹ìQVEW‹}PEü3öPVVhäÂWÿuÿuè}ÜşÿƒÄ ƒøtzESP¡d	ÿw‰uÿĞ  9uYY‹Øu3ÛE‰uP¡d	ÿwÿĞ  9uYYu3ÀÿuÿuüPSèLişÿƒÄ‹ø;ş[uVÿüãPÿuèğ|ıÿƒÄëWÿuè$uıÿY;ÆYujXëP¡d	ÿuÿ´  WÿåƒÄ3À_^ÉÃU‹ìQQVEü‹uWPEø3ÿPWWWh4ÃVÿuÿuè¯ÛşÿƒÄ$ƒøuëhE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuüÿuøPSÿuÿuèêhşÿƒÄ[_^ÉÃU‹ìƒìVEøW‹uP3ÿEôWPWWWWh”ÃVÿuÿuèÛşÿƒÄ,ƒøué¢   E‰}P¡d	ÿvÿĞ  9}YY‰Eüu‰}üÿv¡d	ÿ   ‰EğEP¡d	ÿv‰}ÿĞ  ƒÄ9}‰Eu‰}ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿuøPÿuôSÿuÿuğÿuüÿuè´işÿƒÄ$[_^ÉÃU‹ìEV‹uPj hÄVÿuÿuè=ÚşÿƒÄƒøuëÿv¡d	ÿ   ÿuPÿuèSjşÿƒÄ^]ÃU‹ìVhPÄÿuÿuÿuèüÙşÿƒÄƒøtè nşÿ‹ğVÿuèsıÿY…ÀYujXëP¡d	ÿuÿ´  Y…öYtVÿåY3À^]ÃU‹ìEPhlÄÿuÿuÿuèÙşÿƒÄƒøtÿuèùnşÿ…ÀYtj Pÿuè^zıÿƒÄjX]Ã3À]ÃU‹ìSV‹uWE‹]3ÿPWh¤ÄVÿuSèOÙşÿƒÄƒøt=E‰}P¡d	ÿvÿĞ  9}YYu3ÀMQÿuPè§nşÿƒÄ;ÇtWPSèîyıÿƒÄjXë4¡d	Wÿ5¤°¸   ÿuè7¼ıÿƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[]ÃU‹ìV‹uj hÔÄVÿuÿuè²ØşÿƒÄƒøt9jEÿ5¤Pÿvÿuè<~ıÿƒÄ…Àuÿuè6nşÿ…ÀYtj PÿuèUyıÿƒÄjXë3À^]ÃU‹ìV‹uEW‹}Pj j hôÄVÿuWèEØşÿƒÄƒøtMjEÿ5¤PÿvWèÑ}ıÿƒÄ…Àu1ÿv¡d	ÿ   MQÿuPÿuèÔmşÿƒÄ…Àtj PWèÔxıÿƒÄjXë5¡d	j ÿ5¤°¸   ÿuè»ıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^]ÃU‹ìV‹uj h4ÅVÿuÿuè˜×şÿƒÄƒøt8jEÿ5¤Pÿvÿuè"}ıÿƒÄ…ÀuÿuèÔ …Àtj Pÿuè<xıÿƒÄjXë3À^]ÃU‹ìV‹uj hXÅVÿuÿuè4×şÿƒÄƒøt8jEÿ5¤Pÿvÿuè¾|ıÿƒÄ…Àuÿuèv …Àtj PÿuèØwıÿƒÄjXë3À^]ÃU‹ìEV‹uPj h|ÅVÿuÿuèÌÖşÿƒÄƒøtjEÿ5¤PÿvÿuèV|ıÿƒÄ…ÀtjXëÿuÿuÿuèVişÿƒÄ^]ÃV‹t$j h´ÅVÿt$ÿt$èsÖşÿƒÄƒøt)ÿv¡d	ÿ   Pè‘lşÿY…ÀYtj Pÿt$è&wıÿƒÄjX^Ã3À^ÃU‹ìEV‹uPj hàÅVÿuÿuèÖşÿƒÄƒøuë/ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuPÿuè¡bşÿƒÄ^]ÃU‹ìV‹uW‹}j hÆVÿuWèÃÕşÿƒÄƒøtFEP¡d	ÿvWÿ¤   ƒÄ…Àu,ÿuÿ$è…Àu$¡d	Wÿl  Yj ÿüãPWèYvıÿƒÄjXë#‹d	j ÿ5±´  Pè¢¸ıÿPWÿƒÄ3À_^]ÃU‹ìV‹uW‹}j h0ÆVÿuWè-ÕşÿƒÄƒøtFEP¡d	ÿvWÿ¤   ƒÄ…Àu,ÿuÿ è…Àu$¡d	Wÿl  Yj ÿüãPWèÃuıÿƒÄjXë#‹d	j ÿ5±´  Pè¸ıÿPWÿƒÄ3À_^]ÃU‹ìSV‹u‹]Wj j hLÆVÿuSè”ÔşÿƒÄƒøt9EP¡d	ÿvSÿ¤   ƒÄ…Àuj‹}ÿ5EPÿvSèzıÿƒÄ…ÀtjXë&ÿuWÿè‹d	P±´  ÿ‘Ø   PSÿƒÄ3À_^[]ÃU‹ìQV‹uWE‹}j Pƒeü j hlÆVÿuWèüÓşÿƒÄƒøt3jEÿ5PÿvWèˆyıÿƒÄ…ÀujPEüPÿvWèqyıÿƒÄ…ÀtjXë+ÿuüÿuÿuÿˆá‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^ÉÃU‹ìEV‹uPj hœÆVÿuÿuèoÓşÿƒÄƒøtjEÿ5PÿvÿuèùxıÿƒÄ…ÀtjXë*ÿuÿuÿ„á‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ììL  VEüW‹}PE3öPVhÀÆW‰uüÿuÇ…´üÿÿH  ÿuèàÒşÿƒÄƒøt?E‰uP¡d	ÿwÿĞ  9uYYu3Àÿuü´üÿÿQÿuPÿè…Àuÿuèı€ıÿYjXë"¡d	°´  …´üÿÿPèÖhşÿPÿuÿƒÄ3À_^ÉÃU‹ìV‹uEW‹}Pj h ÇVÿuWèNÒşÿƒÄƒøtIEP¡d	ÿvWÿ¤   ƒÄ…Àu/ÿuÿuÿè…Àu$¡d	Wÿl  Yj ÿüãPWèárıÿƒÄjXë#‹d	j ÿ5T±´  Pè*µıÿPWÿƒÄ3À_^]ÃU‹ìƒìV‹uEW‹}Pj h,ÇVÿuWè®ÑşÿƒÄƒøtDEğPÿvWèíÑıÿƒÄ…Àu0ÿuEğPÿè…Àu$¡d	Wÿl  Yj ÿüãPWèFrıÿƒÄjXë#‹d	j ÿ5T±´  Pè´ıÿPWÿƒÄ3À_^ÉÃU‹ìQQV‹uEW‹}Pj hTÇVÿuWèÑşÿƒÄƒøtFEøPÿvWè·ÒıÿƒÄ…Àu2ÿuÿuüÿuøÿè…Àu$¡d	Wÿl  Yj ÿüãPWèªqıÿƒÄjXë#‹d	j ÿ5T±´  Pèó³ıÿPWÿƒÄ3À_^ÉÃU‹ìƒìhV‹uW‹}j h|ÇVÇE˜h   ÿuWètĞşÿƒÄƒøt4jEÿ5TPÿvWè vıÿƒÄ…ÀuE˜Pÿuÿè…ÀuWèœ~ıÿYjXë¡d	°´  E˜PègşÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}j j h ÇVÿuWèñÏşÿƒÄƒøtRjEÿ5PÿvWè}uıÿƒÄ…Àu6EP¡d	ÿvWÿÄ   ƒÄƒøt3À9EtEğPÿvWèòÏıÿƒÄ…ÀtjXëEğPÿuWèVgşÿƒÄ_^ÉÃU‹ìQSV‹uEj Pj ƒeü hÌÇVÿuÿuèXÏşÿƒÄƒøt1ÿv¡d	ÿ   ƒ}Y‹Ø~jEüj PÿvÿuèÏtıÿƒÄ…ÀtjXë+ÿuüÿuSÿ€á‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^[ÉÃU‹ìQSV‹uEj Pj ƒeü hÈVÿuÿuèÅÎşÿƒÄƒøt1ÿv¡d	ÿ   ƒ}Y‹Ø~jEüj Pÿvÿuè<tıÿƒÄ…ÀtjXë+ÿuüÿuSÿ|á‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^[ÉÃU‹ì3ÀV‹uPPPEPhTÈVÿuÿuè7ÎşÿƒÄ ƒøtN¡d	SWÿvÿ   ÿv‹ø¡d	ÿ   ÿv‹Ø¡d	ÿ   ƒÄPSWÿuÿxá_[…ÀuÿuèE|ıÿYjXë3À^]ÃU‹ìQEV‹uPj ƒeü h°ÈVÿuÿuè´ÍşÿƒÄƒøtjEüÿ5ŒPÿvÿuè>sıÿƒÄ…ÀtjXëÿuÿuüÿuècnşÿƒÄ^ÉÃU‹ìƒì$V‹uMW3ÀQ‹}PPPhÜÈVÿu‰EüWèLÍşÿƒÄ ƒøt`jEüÿ5˜PÿvWèØrıÿƒÄ…ÀtjEüÿ5ØPÿvWè¼rıÿƒÄ…Àu(EÜPÿvWèC_ıÿƒÄ…ÀuEìPÿvWè/_ıÿƒÄ…ÀtjXëÿuEìPEÜPÿuüWèÑnşÿƒÄ_^ÉÃU‹ìQV‹uW‹}ƒeü j h ÉVÿuWè£ÌşÿƒÄƒøt8jEüÿ5˜PÿvWè/rıÿƒÄ…Àt!jEüÿ5ØPÿvWèrıÿƒÄ…ÀtjXëÿuüWè}oşÿYY_^ÉÃU‹ìEPhTÉÿuÿuÿuè5ÌşÿƒÄƒøu]Ãÿuÿuè™oşÿYY]ÃU‹ìEW‹}Ph€ÉÿuÿuWè ÌşÿƒÄƒøtEPÿuÿâ…ÀuWèDzıÿYjXë/¡d	VÿuÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À^_]ÃU‹ìV‹uj h¬ÉVÿuÿuèËşÿƒÄƒøtjEÿ5¤PÿvÿuèqıÿƒÄ…ÀtjXëÿuèäpşÿY3À^]ÃU‹ìQEV‹uPEPj hÌÉVÿuÿuè3ËşÿƒÄƒøt9jEüÿ5¤Pÿvÿuè½pıÿƒÄ…Àuÿuÿuÿuüè …ÀuÿuèVyıÿYjXë3À^ÉÃU‹ìV‹uj hÊVÿuÿuèÎÊşÿƒÄƒøtjEÿ5¤PÿvÿuèXpıÿƒÄ…ÀtjXëÿuÿuèBpşÿYY^]ÃU‹ìV‹uj h(ÊVÿuÿuèyÊşÿƒÄƒøtjEÿ5¤PÿvÿuèpıÿƒÄ…ÀtjXëÿuÿuèRrşÿYY^]ÃU‹ìQEV‹uPEPj hLÊVÿuÿuèÊşÿƒÄƒøt9jEüÿ5¤Pÿvÿuè¥oıÿƒÄ…Àuÿuÿuÿuüè …Àuÿuè>xıÿYjXë3À^ÉÃS‹\$V‹t$j h€ÊVÿt$ Sè´ÉşÿƒÄƒøt8ÿv¡d	ÿ   YPè¹ …Àu$¡d	Sÿl  Yj ÿüãPSèXjıÿƒÄjXë#‹d	j ÿ5¤±´  Pè¡¬ıÿPSÿƒÄ3À^[ÃU‹ìQEV‹uPEPj h¤ÊVÿuÿuè&ÉşÿƒÄƒøtjEüÿ5¤Pÿvÿuè°nıÿƒÄ…ÀtjXëÿuÿuÿuüÿuè»rşÿƒÄ^ÉÃU‹ìƒìVEWPE‹uPEPEüP3ÀMøPQMô‹}PQPhèÊVÿuWèªÈşÿƒÄ4ƒøtijEğÿ5¤PÿvWè6nıÿƒÄ…ÀuM¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   YYÿuMìQÿuÿuÿuüPÿuøSÿuôÿuğèm  …À[uWèvıÿYjXë-ÿuì¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìSVEøW‹}3öPVVVVhXËWÿuÿuèÜÇşÿƒÄ$ƒøt|E‰uP¡d	ÿwÿĞ  9uYY‰Eüu‰uüE‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uEP¡d	ÿwÿĞ  9uYYt$Mè]èQPÿXê;ÆtVPÿuè<hıÿƒÄjXë63ÛE‰uP¡d	ÿwÿĞ  9uYYu3ÀÿuøPSÿuÿuüÿuè­qşÿƒÄ_^[ÉÃU‹ìQEPEPEüPh¬ËÿuÿuÿuèõÆşÿƒÄƒøtÿuÿuÿuüèSş  „Àuÿuè6uıÿYjXÉÃ3ÀÉÃU‹ìV‹uW‹}j hğËVÿuWè­ÆşÿƒÄƒøt4jEÿ5¤PÿvWè9lıÿƒÄ…ÀuEPÿuÿâ…ÀuWèÕtıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìEPhÌÿuÿuÿuè!ÆşÿƒÄƒøu]ÃÿuÿuèFï  YY]ÃU‹ìV‹uj h@ÌVÿuÿuèîÅşÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXëÿuÿuè„ï  YY^]ÃU‹ìƒì$hdÌÿuÿuÿuèœÅşÿƒÄƒøtEôPèió  …ÀuÿuèâsıÿYjXÉÃ¶EôVP¡d	ÿØ   ‰EÜ¶EõP¡d	ÿØ   ‰Eà¶EöP¡d	ÿØ   ‰Eä¶E÷P¡d	ÿØ   ÿuø‰Eè¡d	ÿØ   ÿuü‰Eì¡d	ÿØ   ‰Eğ¡d	MÜQj°´  ÿÜ   PÿuÿƒÄ(3À^ÉÃU‹ìEPh„ÌÿuÿuÿuèËÄşÿƒÄƒøu]ÃVÿuÿ â‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^]ÃU‹ìƒì SV3öW‹}VVVVh°ÌW‰uüÿuÿuèpÄşÿƒÄ ƒø„Î   EP¡d	ÿwÿĞ  9uYYtMà‰MôMàQPÿXê;Æt	Vé   ‰uôEğP¡d	ÿwÿuÿ¤   ƒÄ…Àu{‹]ğEP¡d	ÿw‰uÿĞ  9uYY‰Eøu‰uøƒ}~jEüVPÿwÿuè}iıÿƒÄ…Àu7ÿuüÿuøSÿuôÿÜæƒøÿu'ÿu¡d	ÿl  YVÿüãPÿuèzdıÿƒÄjXë$‹d	Vÿ5¹´  PèÄ¦ıÿPÿuÿƒÄ3À_^[ÉÃU‹ìV‹uj hÍVÿuÿuèNÃşÿƒÄƒøt4jEÿ5PÿvÿuèØhıÿƒÄ…ÀuÿuÿØæ…ÀuÿuèvqıÿYjXë3À^]ÃU‹ìƒì,SV3öW‹}VVEäVPVVVhHÍW‰uüÿuÿuèÜÂşÿƒÄ,ƒø„  EP¡d	ÿwÿĞ  9uYYtMÔ‰MğMÔQPÿXê;Æt	Véß   ‰uğE‰uP¡d	ÿwÿĞ  9uYY‰Eôu‰uôEìP¡d	ÿwÿuÿ¤   ƒÄ…À…¦   jEèÿ5‹]ìPÿwÿuèægıÿƒÄ…À…   E‰uP¡d	ÿwÿĞ  9uYY‰Eøu‰uøƒ}~jEüVPÿwÿuè¡gıÿƒÄ…Àu@ÿuüÿuøÿuèÿuäSÿuôÿuğÿÔæƒøÿu'ÿu¡d	ÿl  YVÿüãPÿuè•bıÿƒÄjXë$‹d	Vÿ5¹´  Pèß¤ıÿPÿuÿƒÄ3À_^[ÉÃU‹ìQV‹u3ÀWM‹}PQPhÄÍV‰EüÿuWè]ÁşÿƒÄƒøtRjEÿ5PÿvWèéfıÿƒÄ…Àu6jEüÿ5PÿvWèÍfıÿƒÄ…ÀuÿuüÿuÿuÿĞæ…ÀuWègoıÿYjXë3À_^ÉÃU‹ìƒìSV‹uMW3ÀQMP‹}QPPhÎV‰Eøÿu‰EüWèÇÀşÿƒÄ$j[;Ã„’   SEÿ5PÿvWèNfıÿƒÄ…ÀuwSEøÿ5PÿvWè3fıÿƒÄ…Àu\SEüÿ5€PÿvWèfıÿƒÄ…ÀuAEğPEôÿuÿuüPÿuÿuøÿuÿÌæ‹Ø…Ûu#ÿüãƒøzt…ÀujWXj PWèaıÿƒÄjXëo¡d	S°´  ÿØ   PWÿÿuô¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿÿuğ¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^[ÉÃU‹ìƒìSV‹uW3ÿEWP‹]WWWhˆÎVÿu‰}ø‰}üSè€¿şÿƒÄ$ƒø„¤   jEÿ5PÿvSèeıÿƒÄ…À…„   jEøÿ5PÿvSèèdıÿƒÄ…ÀuhEèP¡d	ÿvÿ   YPÿXê;ÇtWPSèó_ıÿƒÄë=jEüÿ5tPÿvSè¡dıÿƒÄ…Àu!ÿuüEèÿuPÿuøÿuÿÈæ…ÀuSè4mıÿYjXë3À_^[ÉÃU‹ìƒìSV‹u3ÛWESP‹}SSShôÎVÿu‰]ô‰]ø‰]üWè“¾şÿƒÄ$ƒø„±   jEÿ5PÿvWèdıÿƒÄ…À…‘   jEôÿ5tPÿvWèûcıÿƒÄ…ÀuujEøÿ5äPÿvWèßcıÿƒÄ…ÀuYjEüÿ5PÿvWèÃcıÿƒÄ…Àu=ÿuüEğPÿuÿuøÿuôÿuÿÄæ;Ã‰Eu"ÿüãƒøzt;ÃujWXSPWèº^ıÿƒÄjXëG¡d	ÿu°´  ÿØ   PWÿÿuğ¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^[ÉÃU‹ìì  SV‹uW3ÿ‹]WWWWhŒÏVÿu‰}ü‰}ô‰}øSèU½şÿƒÄ ƒø„¯   EäP¡d	ÿvÿ   YPÿXê;ÇtWPSè^ıÿƒÄé   ƒ}~jEüÿ5ÜPÿvSè©bıÿƒÄ…Àu_ƒ}~ÿv¡d	ÿ   Y‰Eôƒ}~jEøWPÿvSètbıÿƒÄ…Àu*ÿuø…äıÿÿÿuôÿuüh   PEäPÿÀæ…ÀuSèşjıÿYjXë'¡d	äıÿÿjÿQf‰}â°´  ÿğ  PSÿƒÄ3À_^[ÉÃU‹ìƒìSV‹uW3ÿEWW‹]PWWhüÏVÿu‰}ô‰}ø‰}üSè8¼şÿƒÄ$ƒø„†   ÿv¡d	ÿ   j‰Eÿ5ÈEôPÿvSè¯aıÿƒÄ…ÀuYƒ}~ÿv¡d	ÿ   Y‰Eøƒ}~jEüWPÿvSèzaıÿƒÄ…Àu$ÿuüEğÿuøPÿuÿuôÿuÿ¼æ…ÀuSè
jıÿYjXë-ÿuğ¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À_^[ÉÃU‹ìì  SV‹uW3ÿ‹]WWWhtĞV‰}üÿu‰}øSèC»şÿƒÄƒø„€   jEÿ5PÿvSèË`ıÿƒÄ…ÀudjEüÿ5PÿvSè¯`ıÿƒÄ…ÀuHƒ}~jEøÿ5ÜPÿvSè`ıÿƒÄ…Àu&ÿuø…øıÿÿh   Pÿuüÿuÿ¸æ…ÀuSèiıÿYjXë'¡d	øıÿÿjÿQf‰}ö°´  ÿğ  PSÿƒÄ3À_^[ÉÃU‹ìƒìSVW3ÿEW‹uPEWPE‹]WPWhÜĞVÿu‰}ô‰}ø‰}üSèMºşÿƒÄ,ƒø„   jEğÿ5œPÿvSèÕ_ıÿƒÄ…ÀutjEôWPÿvSè¾_ıÿƒÄ…Àu]jEøWPÿvSè§_ıÿƒÄ…ÀuFjEüÿ5PÿvSè‹_ıÿƒÄ…Àu*ÿuüEìPÿuÿuøÿuÿuôÿuÿuğÿ$â…ÀuSèhıÿYjXë-ÿuì¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À_^[ÉÃU‹ìƒìV‹uEj PEüPhTÑVÿuÿuèU¹şÿƒÄƒøt:EP¡d	ÿvÿĞ  ƒ} YYt%MìuìQPÿXê…Àtj Pÿuè÷YıÿƒÄjXë3öVÿuÿuüÿuè÷¶  ƒÄ^ÉÃU‹ìV‹uj hœÑVÿuÿuèİ¸şÿƒÄƒøtEP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXëÿuÿuèç·  YY^]ÃhÈÑÿt$ÿt$ÿt$è¸şÿƒÄƒøuÃÿt$è'rşÿYÃhäÑÿt$ÿt$ÿt$èd¸şÿƒÄƒøuÃÿt$è¾sşÿYÃU‹ìV‹uW‹}j hüÑVÿuWè4¸şÿƒÄƒøt)ÿv¡d	ÿ   YMQPèiï  …Àtj PWèçXıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]Ãh$Òÿt$ÿt$ÿt$è··şÿƒÄƒøuÃÿt$èÿtşÿYÃU‹ìW‹}h@ÒÿuÿuWè‹·şÿƒÄƒøtEPèÖî  …Àtj PWèNXıÿƒÄjXë/¡d	VÿuÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À^_]ÃU‹ìEPh`Òÿuÿuÿuè·şÿƒÄƒøu]Ãÿuÿuè]sşÿYY]ÃU‹ìEPhŒÒÿuÿuÿuèæ¶şÿƒÄƒøu]ÃÿuÿuèètşÿYY]ÃU‹ìQEüƒeü Ph¬Òÿuÿuÿuè®¶şÿƒÄƒøuÉÃÿuüÿuèuşÿYYÉÃU‹ìQEüƒeü PhØÒÿuÿuÿuèv¶şÿƒÄƒøuÉÃÿuüÿuèótşÿYYÉÃU‹ìQEüƒeü PhÓÿuÿuÿuè>¶şÿƒÄƒøuÉÃÿuüÿuèØtşÿYYÉÃU‹ìQEüƒeü Ph8Óÿuÿuÿuè¶şÿƒÄƒøuÉÃÿuüÿuè½tşÿYYÉÃU‹ìEPhlÓÿuÿuÿuèÓµşÿƒÄƒøtÿuè%í  …Àtj Pÿuè•VıÿƒÄjX]Ã3À]ÃU‹ìEPEPhÓÿuÿuÿuèŠµşÿƒÄƒøu]ÃÿuÿuÿuèìvşÿƒÄ]ÃU‹ìEPEPhÌÓÿuÿuÿuèOµşÿƒÄƒøu]ÃÿuÿuÿuèîwşÿƒÄ]ÃU‹ìƒìV‹uj hÔVÿuÿuèµşÿƒÄƒøt1EìPÿvÿuè,   ƒÄ…ÀuEìPèVì  …Àtj PÿuèÀUıÿƒÄjXë3À^ÉÃU‹ìQSVE‹]WPEüP¡d	ÿuSÿ¼   ƒÄ…Àu-ƒ}üt/…Ût#¡d	j ÿu°   ÿX  YPh$ÔSÿƒÄjX_^[ÉÃ‹u‹EVÿ0¡d	Sÿ    ƒÄ…ÀuÜFP‹EÿpSè   ƒÄ…ÀuÅ‹E~Wÿp¡d	Sÿ    ƒÄ…Àu¨FP‹EÿpSèK   ƒÄ…Àu‘‹EƒÆVÿp¡d	Sÿ    ƒÄ…À…pÿÿÿf‹‹˜éPÿÓ·À‰f‹PÿÓ·À‰3ÀéPÿÿÿ¡d	VWÿt$ÿX  Y‹ğVÿœé‹øƒÿÿu7Vh`Ôèì  Y…ÀYt&ƒ|$ t¡d	j VhDÔÿt$ÿ   ƒÄjXë‹D$‰83À_^ÃU‹ìƒìSV‹uEüW‹}3ÛPSh ÔVÿuWèA³şÿƒÄƒø„²   EPEP¡d	ÿvWÿ¼   ƒÄ…À…   9]fÇEì ‰]ğf‰]î~‹Eÿ0¡d	ÿX  YPÿœé‰Eğƒ}~3EP‹Eÿp¡d	Wÿ¤   ƒÄ…Àu+}ÿÿ  w"ÿuÿ˜éf‰EîÿuüEìPWè”vşÿƒÄ_^[ÉÃ¡d	ShpÔWÿ¨  ƒÄjXëáU‹ìQEPEPEüPhÄÔÿuÿuÿuè[²şÿƒÄƒøuÉÃÿuÿuÿuüÿuèuşÿƒÄÉÃU‹ìEPEPhøÔÿuÿuÿuè²şÿƒÄƒøu]Ãÿuÿuÿuè€±  ƒÄ]ÃU‹ìEPEPh,Õÿuÿuÿuèâ±şÿƒÄƒøu]Ãÿuÿuÿuè´  ƒÄ]ÃU‹ìV‹uW‹}j j h`ÕVÿuWè§±şÿƒÄƒøt(EPÿvWèÈıÿÿƒÄ…ÀuEPÿvWè´ıÿÿƒÄ…ÀtjXëÿuÿuWèŞşÿƒÄ_^]ÃU‹ìV‹uW‹}j hˆÕVÿuWèC±şÿƒÄƒøt0EPÿvWèdıÿÿƒÄ…ÀuEPÿuè‰è  …Àtj PWèïQıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìƒìEVPE‹uPEøƒeü PEôPj h¬ÕVÿuÿuè¤°şÿƒÄ$ƒøtjEüj Pÿvÿuè2VıÿƒÄ…ÀtjXëÿuÿuÿuøÿuôÿuüÿuè¦pşÿƒÄ^ÉÃU‹ìQEV‹uPEƒeü Pj hôÕVÿuÿuè9°şÿƒÄƒøtjEüj PÿvÿuèÇUıÿƒÄ…ÀtjXëÿuÿuÿuüÿuè­fşÿƒÄ^ÉÃU‹ìƒìEVPE‹uPEøƒeü PEôPj h4ÖVÿuÿuèÊ¯şÿƒÄ$ƒøtjEüj PÿvÿuèXUıÿƒÄ…ÀtjXëÿuÿuÿuøÿuôÿuüÿuèipşÿƒÄ^ÉÃU‹ìQEV‹uPEƒeü Pj h|ÖVÿuÿuè_¯şÿƒÄƒøtjEüj PÿvÿuèíTıÿƒÄ…ÀtjXëÿuÿuÿuüÿuè?fşÿƒÄ^ÉÃU‹ìƒìSVW3ÿ‹uWEøWPEğWPWWh¼ÖVÿu‰}üÿuèò®şÿƒÄ,ƒøtjE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}ÿv¡d	ÿ   ÿv‹Ø¡d	ÿ   ÿv‰Eô¡d	ÿ   ‰EEüPÿvÿuè=ŞşÿƒÄ…Àt9}üt	ÿuüèkİşÿYjXëÿuüÿuÿuøÿuôÿuğSÿuÿuè~şÿƒÄ _^[ÉÃh×ÿt$ÿt$ÿt$è4®şÿƒÄƒøuÃÿt$èa‡şÿYÃU‹ìV‹uj j h(×Vÿuÿuè®şÿƒÄƒøuë?ƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   PSÿuèà‡şÿƒÄ[^]ÃU‹ìV‹uWE3ÿPWWh\×Vÿuÿuè—­şÿƒÄƒøtLESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   YÿuPSèYâ  ;Ç[tWPÿuè'NıÿƒÄjXë3À_^]ÃU‹ìV‹uj h”×Vÿuÿuè­şÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuè>}şÿYY^]ÃU‹ìV‹uj j h¼×VÿuÿuèÊ¬şÿƒÄƒøuë?ƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   PSÿuèŞ}şÿƒÄ[^]ÃU‹ìEV‹uPj j hô×Vÿuÿuè^¬şÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuèú}şÿƒÄ[^]ÃU‹ìQQSV‹uW3ÿEøWPWWWh(ØV‰}üÿuÿuèæ«şÿƒÄ$ƒøtYE‰}P¡d	ÿvÿĞ  9}YY‰Eu‰}ÿv¡d	ÿ   ÿv‹Ø¡d	ÿ   ‰EEüPÿvÿuèBÛşÿƒÄ…Àt9}üt	ÿuüèpÚşÿYjXëÿuüÿuøÿuSÿuÿuèü~şÿƒÄ_^[ÉÃU‹ìEV‹uPj j hpØVÿuÿuè5«şÿƒÄƒøuëBƒe ESPÿv¡d	ÿĞ  ƒ} YY‹Øu3Ûÿv¡d	ÿ   ÿuPSÿuèˆşÿƒÄ[^]ÃU‹ìQVEüW‹}3öPVVVh¤ØWÿuÿuèÃªşÿƒÄ ƒøuëuE‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uESP¡d	ÿw‰uÿĞ  9uYY‹Øu3ÛE‰uP¡d	ÿwÿĞ  9uYYu3ÀÿuüPSÿuÿuè‡‘şÿƒÄ[_^ÉÃU‹ìQEV‹uPEüPj hØØVÿuÿuèªşÿƒÄƒøuë2ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuÿuüPÿuè9“şÿƒÄ^ÉÃU‹ìEV‹uPj hÙVÿuÿuèÀ©şÿƒÄƒøt;ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuPè™Ş  …Àtj PÿuèaJıÿƒÄjXë3À^]ÃU‹ìQVEüW‹}3öPVVVh4ÙWÿuÿuèP©şÿƒÄ ƒøuëuE‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uESP¡d	ÿw‰uÿĞ  9uYY‹Øu3ÛE‰uP¡d	ÿwÿĞ  9uYYu3ÀÿuüPSÿuÿuèÉˆşÿƒÄ[_^ÉÃU‹ìV‹uWE3ÿPWWWhhÙVÿuÿuè«¨şÿƒÄ ƒøuëQESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3Ûÿv¡d	ÿ   ÿv‹ø¡d	ÿ   ÿuPWSÿuè“ŒşÿƒÄ[_^]ÃU‹ìV3öW‹}VVVh ÙWÿuÿuè.¨şÿƒÄƒøt}E‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uESP¡d	ÿw‰uÿĞ  9uYY‹Øu3ÛE‰uP¡d	ÿwÿĞ  9uYYu3ÀPSÿuèËÜ  ;Æ[tVPÿuèHıÿƒÄjXë3À_^]ÃU‹ìƒìVEôWP3ÿEğ‹uWPWWWEèWPWhÌÙVÿuÿuèn§şÿƒÄ4ƒøtEøP¡d	ÿvÿuÿ¤   ƒÄ…ÀtjXéÙ   ‹Eø‰}‰EäEP¡d	ÿvÿĞ  9}YY‰Eüu‰}üÿv¡d	ÿ   ‰EìEP¡d	ÿv‰}ÿĞ  ƒÄ9}‰Eu‰}ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿv ÿĞ  9}YYu3ÀÿuôPÿuğSÿuÿuìÿuüÿuèÿuäÿuèízşÿ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ43À[_^ÉÃU‹ìEV‹uPEPj hPÚVÿuÿuèC¦şÿƒÄƒøt*ÿv¡d	ÿ   YÿuÿuPèÀÛ  …ÀtPÿuètHıÿYYjXë3À^]ÃV‹t$j hˆÚVÿt$ÿt$èí¥şÿƒÄƒøu^Ãÿv¡d	ÿ   Pÿt$èÃzşÿƒÄ^ÃV‹t$j h´ÚVÿt$ÿt$è¬¥şÿƒÄƒøu^Ãÿv¡d	ÿ   Pÿt$èu‚şÿƒÄ^ÃU‹ìV‹uW3ÿWWhĞÚVÿuÿuèh¥şÿƒÄƒøuëMESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿvÿĞ  9}YYu3ÀPSÿuè]‚şÿƒÄ[_^]ÃU‹ìEV‹uPj h ÛVÿuÿuèï¤şÿƒÄƒøuë/ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuPÿuèW‚şÿƒÄ^]ÃU‹ìSV‹u3ÛWSSh4ÛV3ÿÿuÿuè“¤şÿƒÄƒøt5E‰]P¡d	ÿvÿĞ  9]YY‰Eu‰]ÿvÿuè;   ‹øY;ûYuWè   YjXëWÿuÿuèª‚şÿƒÄ_^[]Ãƒ|$ tÿt$ÿåYÃU‹ìƒìVE‹uWPEüP¡d	ÿuVÿ¼   ƒÄ…À…  ƒ}üt"…ö„ù   P¡d	h`ÛVÿ¨  ƒÄéß   EøP‹Eÿp¡d	ÿĞ  ‹øEP‹EøD Pj Vèj3ıÿƒÄ…À…©   ÿu‹Eÿ0¡d	Vÿ¤   ƒÄ…À…   ‹EƒÀP‹Eÿp¡d	Vÿ¤   ƒÄ…ÀuaEôP‹Eÿp¡d	Vÿ¤   ƒÄ…ÀuDEğP‹Eÿp¡d	Vÿ¤   ƒÄ…Àu'‹EŠMôWˆH‹EŠMğˆH	‹EƒÀPÿ`å‹EYYëÿuèºşÿÿY3À_^ÉÃU‹ìQEV‹uPEüPj hŒÛVÿuÿuèÆ¢şÿƒÄƒøt>ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀÿuÿuüPè¨×  …Àtj PÿuèdCıÿƒÄjXë3À^ÉÃU‹ìV‹uj hÈÛVÿuÿuè\¢şÿƒÄƒøuë+ƒe EP¡d	ÿvÿĞ  ƒ} YYu3ÀPÿuèá€şÿYY^]ÃU‹ìEV‹uPj j hğÛVÿuÿuè¢şÿƒÄƒøuëC¡d	Sÿvÿ   ƒe ‹ØEP¡d	ÿvÿĞ  ƒÄƒ} u3ÀÿuPSÿuè†wşÿƒÄ[^]ÃU‹ìQSV‹uW3ÿE‹]WPWh@ÜVÿu‰}üSè¡şÿƒÄƒøtREüPÿvSè§ÚşÿƒÄ…Àu>ÿv¡d	ÿ   YPÿuÿuüÿ(â;Çu1¡d	Sÿl  YWÿüãPSèBıÿƒÄ9}üt	ÿuüè4ÚşÿYjXë0‹d	Wÿ5¤±´  PèS„ıÿPSÿƒÄ9}üt	ÿuüèÚşÿY3À_^[ÉÃU‹ìSV‹uEj P‹]EPh€ÜVÿuSèÇ şÿƒÄƒøt?ÿv¡d	ÿ   YPÿuÿuÿ,â…Àu$¡d	Sÿl  Yj ÿüãPSèdAıÿƒÄjXë#‹d	j ÿ5¤±´  Pè­ƒıÿPSÿƒÄ3À^[]ÃU‹ìV‹uj h¼ÜVÿuÿuè: şÿƒÄƒøt4jEÿ5¤PÿvÿuèÄEıÿƒÄ…Àuÿuÿ0â…ÀuÿuèbNıÿYjXë3À^]ÃU‹ìQSVW‹u3ÿEWPE‹]PWhÜÜVÿu‰}üSèÉŸşÿƒÄ ƒøtUEüPÿvSèãØşÿƒÄ…ÀuAÿv¡d	ÿ   YPÿuÿuÿuüÿ4â;Çu1¡d	Sÿl  YWÿüãPSèP@ıÿƒÄ9}üt	ÿuüèmØşÿYjXë0‹d	Wÿ5¤±´  PèŒ‚ıÿPSÿƒÄ9}üt	ÿuüè:ØşÿY3À_^[ÉÃU‹ìSV‹uEj P‹]EPh4İVÿuSè ŸşÿƒÄƒøt?ÿv¡d	ÿ   YPÿuÿuÿ8â…Àu$¡d	Sÿl  Yj ÿüãPSè?ıÿƒÄjXë#‹d	j ÿ5¤±´  PèæıÿPSÿƒÄ3À^[]ÃU‹ìV‹uEW‹}Pj htİVÿuWèmşÿƒÄƒøt7jEÿ5¤PÿvWèùCıÿƒÄ…ÀuEPÿuÿuÿ<â…ÀuWè’LıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìì  V‹uEWPEü‹}Pj h¨İVÿuWèÎşÿƒÄƒøtwEPEP¡d	ÿvWÿ¼   ƒÄƒøtXƒ}@wR3ö9uv)j„µüşÿÿÿ5¤P‹Eÿ4°Wè'CıÿƒÄ…Àu(F;ur×ÿu…üşÿÿÿuüPÿuÿ@âƒøÿuWè³KıÿYjXë‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^ÉÃU‹ìV‹uj j j hüİVÿuÿuèşÿƒÄƒøuëc¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   ÿv‰E¡d	ÿ   PÿuSè5şÿ‹d	j ÿ5H±´  PÿuèÈ şÿPÿuÿƒÄ03À[^]ÃU‹ìQV‹uj ƒeü hDŞVÿuÿuè}œşÿƒÄƒøtjEüÿ5HPÿvÿuèBıÿƒÄ…ÀtjXëÿuüèşÿY3À^ÉÃhxŞÿt$ÿt$ÿt$è.œşÿƒÄƒøuÃÿt$è]ŠşÿYÃU‹ìƒì SV3öW‹}VEV‹]PVVhœŞWÿu‰uüSèï›şÿƒÄ$ƒø„¨   E‰uP¡d	ÿwÿĞ  9uYY‰Eu‰uÿw¡d	ÿ   ÿw‰Eø¡d	ÿø  Y…ÀYu‰uëVÿwSèİ»şÿƒÄ…ÀuKEà‰EjEüVPÿwSèAıÿƒÄ…Àu.EğPEèPVVÿuüÿuÿuÿuøÿuÿ,ç;ÆtVPSè<ıÿƒÄjXëX¡d	°¸   EèPèĞ„şÿYP¡d	Sÿ   YPSÿÿuô¡d	ÿuğ°¸   ÿ¨  ƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[ÉÃU‹ìQQV‹uj hßVÿuÿuè½šşÿƒÄƒøt2EøPÿvÿuè•„şÿƒÄ…ÀuEøPÿ0ç…Àtj Pÿuèg;ıÿƒÄjXë3À^ÉÃU‹ìƒì$SVEWP3ÛESPEü‹uPEø‹}PSSSh,ßVÿuWèEšşÿƒÄ0ƒøtxEèPÿvWè„şÿƒÄ…ÀudEP¡d	ÿvWÿÄ   ƒÄ…ÀuJ9]tEğPÿvWèìƒşÿƒÄ…Àu1Eğ‰Eë‰]ÿv¡d	ÿ   ‹ØEÜjPÿvWè"†şÿƒÄ…ÀtjXë*‹Eàÿu÷ØÀMÜ#ÁPEèÿuÿuüÿuøSÿuPWèkˆşÿƒÄ$_^[ÉÃU‹ìƒìSVE‹uWPE3ÛP‹}SSSh¸ßVÿuWèf™şÿƒÄ$ƒøt`EğPÿvWè@ƒşÿƒÄ…ÀuLEP¡d	ÿvWÿÄ   ƒÄ…Àu29]tEøPÿvWèƒşÿƒÄ…Àu]øEäjPÿvWè[…şÿƒÄ…ÀtjXë!‹Eèÿu÷ØÿuMäÀ#ÁPEğSPWèóˆşÿƒÄ_^[ÉÃU‹ìQQV‹uj hàVÿuÿuè·˜şÿƒÄƒøt2EøPÿvÿuè‚şÿƒÄ…ÀuEøPÿ4ç…Àtj Pÿuèa9ıÿƒÄjXë3À^ÉÃU‹ìQQV‹uW‹}j hDàVÿuWèU˜şÿƒÄƒøt2EøPÿvWè/‚şÿƒÄ…ÀuEPEøPÿ8ç…Àtj PWèÿ8ıÿƒÄjXë5¡d	j ÿ5¤°¸   ÿuèG{ıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQQV‹uj hpàVÿuÿuèÁ—şÿƒÄƒøt2EøPÿvÿuè™şÿƒÄ…ÀuEøPÿ<ç…Àtj Pÿuèk8ıÿƒÄjXë3À^ÉÃU‹ìQQEV‹uPj hœàVÿuÿuè]—şÿƒÄƒøtEøPÿvÿuè5şÿƒÄ…ÀtjXëÿuEøPÿuèƒ‰şÿƒÄ^ÉÃU‹ìƒìEV‹uPEüj Pj hÈàVÿuÿuèş–şÿƒÄ ƒøtEôPÿvÿuèÖ€şÿƒÄ…ÀtjXë+EP¡d	ÿvÿŒ   ÿuPEôÿuÿuüPÿuè£‹şÿƒÄ ^ÉÃU‹ìƒìV‹uEW‹}Pj j háVÿuWèˆ–şÿƒÄƒøtXEøPÿvWèb€şÿƒÄ…ÀuDEìjPÿvWè³‚şÿƒÄ…Àu.‹EğMì÷ØÀ#ÁMQÿuPEøPÿ@ç…Àtj PWè7ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìEV‹uPEüj Pj hDáVÿuÿuèË•şÿƒÄ ƒøtEôPÿvÿuè£şÿƒÄ…ÀtjXë+EP¡d	ÿvÿŒ   ÿuPEôÿuÿuüPÿuèŠ‹şÿƒÄ ^ÉÃU‹ìƒìV‹uEW‹}Pj j h€áVÿuWèU•şÿƒÄƒøtMEøPÿvWè/şÿƒÄ…Àu9PEìPÿvWèşÿƒÄ…Àu$EPEìÿuPEøPèğÌ  …Àtj PWèä5ıÿƒÄjXëV¡d	°¸   EìPè—‚şÿYP¡d	Wÿ   YPWÿÿu¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQQV‹uEWPEü3ÿPWWh°áVÿuÿuèz”şÿƒÄ ƒøt_ESP¡d	ÿv‰}ÿĞ  9}YY‹Øu3ÛE‰}P¡d	ÿvÿĞ  9}YYu3ÀÿuÿuüPEøSPÿ(à…À[uÿuèwBıÿYjXë%¡d	Wÿ54°´  ÿuøè@wıÿPÿuÿƒÄ3À_^ÉÃU‹ìQEüV‹uPj ƒeü hüáVÿuÿuèÂ“şÿƒÄƒøt7jEÿ54PÿvÿuèL9ıÿƒÄ…Àuÿuüÿuÿ$à…ÀuÿuèçAıÿYjXë3À^ÉÃU‹ìEV‹uPj h0âVÿuÿuè[“şÿƒÄƒøtjEÿ54Pÿvÿuèå8ıÿƒÄ…ÀtjXëÿuÿuÿuèÿŠşÿƒÄ^]ÃU‹ìEPEPhXâÿuÿuÿuèş’şÿƒÄƒøu]ÃÿuÿuÿuèØ‘şÿƒÄ]ÃU‹ìQQEPEPEüPEøPhŒâÿuÿuÿuè¹’şÿƒÄ ƒøuÉÃÿuÿuÿuüÿuøÿuèÑŒşÿƒÄÉÃU‹ìV‹uW‹}j hÔâVÿuWèz’şÿƒÄƒøt4jEÿ5¤PÿvWè8ıÿƒÄ…ÀuEPÿuÿDâ…ÀuWè¢@ıÿYjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^]ÃU‹ìQEV‹uPEPj hüâVÿuÿuèå‘şÿƒÄƒøt:jEüÿ5¤Pÿvÿuèo7ıÿƒÄ…ÀuÿuÿuÿuüÿHâ…Àuÿuè@ıÿYjXë3À^ÉÃU‹ìƒì$SVEWPEP‹uEü‹}P3ÀPPPh0ãVÿuWèj‘şÿƒÄ(ƒøtzjEôÿ5¤PÿvWèö6ıÿƒÄ…Àu^EP¡d	ÿvWÿ¤   ƒÄ…ÀuDj‹]ÿ5¤EøPÿvWè½6ıÿƒÄ…Àu%ÿuEğÿuÿuüPÿuøSÿuôÿpã…ÀuWèL?ıÿYjXë)ÿuğEÜh¸#PÿüäEÜjP¡d	Wÿ¨  ƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü h°ãVÿuÿuè–şÿƒÄƒøtjEüj Pÿvÿuè$6ıÿƒÄ…ÀtjXë'‹EüP‹ÿQ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uj ƒeü hÔãVÿuÿuè&şÿƒÄƒøtjEüj Pÿvÿuè´5ıÿƒÄ…ÀtjXë'‹EüP‹ÿQ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uW‹}ƒeü j høãVÿuWè´şÿƒÄƒøt|jEüÿ5ìPÿvWè@5ıÿƒÄ…Àt6jEüÿ5$PÿvWè$5ıÿƒÄ…ÀtjEüÿ5ìPÿvWè5ıÿƒÄë*¡d	Wÿl  ‹EüYU‹RPÿQ…Àtj PWè0ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEWPE‹}Pƒeü j h(äVÿuWèÑşÿƒÄƒø„‚   jEüÿ5ìPÿvWèY4ıÿƒÄ…Àt6jEüÿ5$PÿvWè=4ıÿƒÄ…ÀtjEüÿ5ìPÿvWè!4ıÿƒÄë0¡d	Wÿl  ‹EüYU‹RÿuÿuPÿQ…Àtj PWè'/ıÿƒÄjXë5¡d	j ÿ5Ü°¸   ÿuèoqıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQSV‹uEW3Û‹}PSSh`äVÿu‰]üWèŞşÿƒÄƒøt_jEüÿ5$PÿvWèj3ıÿƒÄ…ÀuCEP¡d	ÿvÿĞ  YYÿuPÿPæU‰E‹EüRÿu‹ÿuPÿQ;ÃtSPWè[.ıÿƒÄj[ë+ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄÿuÿXæ_‹Ã^[ÉÃU‹ìQQSE‹]V‹uPƒeø ƒeü j hœäVÿuSèşÿƒÄƒøt<jEøÿ5$PÿvSè™2ıÿƒÄ…Àu ‹EøUüRÿu‹PÿQ0…Àtj PSè­-ıÿƒÄjXë%¡d	ÿuü°´  èŸıÿPSÿƒÄÿuüÿXæ3À^[ÉÃU‹ìQV‹uEWPE‹}Pƒeü j hÔäVÿuWèrŒşÿƒÄƒøt?jEüÿ5$PÿvWèş1ıÿƒÄ…Àu#‹EüURÿu‹ÿuPÿQ,…Àtj PWè-ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h åVÿuWèÔ‹şÿƒÄƒøt9jEüÿ5$PÿvWè`1ıÿƒÄ…Àu‹EüURP‹ÿQ8…Àtj PWèw,ıÿƒÄjXë5¡d	j ÿ5´°¸   ÿuè¿nıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEWPE‹}Pƒeü j hXåVÿuWè,‹şÿƒÄƒøt?jEüÿ5$PÿvWè¸0ıÿƒÄ…Àu#‹EüURÿu‹ÿuPÿQ4…Àtj PWèÉ+ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j h”åVÿuWèŠŠşÿƒÄƒøt<jEüÿ5ÜPÿvWè0ıÿƒÄ…Àu ‹EüURÿu‹PÿQ …Àtj PWè*+ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j hĞåVÿuWèë‰şÿƒÄƒøt<jEüÿ5ÜPÿvWèw/ıÿƒÄ…Àu ‹EüURÿu‹PÿQ8…Àtj PWè‹*ıÿƒÄjXë5¡d	j ÿ5Ü°¸   ÿuèÓlıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hæVÿuWèH‰şÿƒÄƒøt9jEüÿ5ÜPÿvWèÔ.ıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWèë)ıÿƒÄjXë5¡d	j ÿ50°¸   ÿuè3lıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h4æVÿuWè¨ˆşÿƒÄƒøt=jEüÿ5ÜPÿvWè4.ıÿƒÄ…Àu!‹EüURU‹RPÿQH…Àtj PWèG)ıÿƒÄjXë_¡d	j ÿ5ü°¸   ÿuèkıÿƒÄP¡d	Wÿ   YPWÿÿu¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìS‹]VEW‹}3öPVhhæS‰uğÿu‰uü‰uø‰uôWèÊ‡şÿƒÄƒøtGjEğÿ5ÜPÿsWèV-ıÿƒÄ…Àu+Uô‹EğRURUø‹RUüRÿuPÿQ0;ÆtVPWè_(ıÿƒÄjXé¼   ¡d	ÿuü°¸   èNıÿYP¡d	Wÿ   YPWÿ‹5XæƒÄÿuüÿÖ¡d	ÿuø˜¸   èıÿYP¡d	Wÿ   YPWÿƒÄÿuøÿÖÿu¡d	ÿØ   Y‹d	PW™¸   ÿ‘   YPWÿ¡d	ÿuô˜¸   èÄıÿƒÄP¡d	Wÿ   YPWÿƒÄÿuôÿÖ3À_^[ÉÃU‹ìQV‹uEW‹}Pƒeü j h æVÿuWè†şÿƒÄƒøt<jEüÿ5ÜPÿvWè,ıÿƒÄ…Àu ‹EüURÿu‹PÿQ$…Àtj PWè-'ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìS‹]VEW‹}3öPVhØæS‰uğÿu‰uü‰uø‰uôWèâ…şÿƒÄƒøtGjEğÿ5üPÿsWèn+ıÿƒÄ…Àu+Uô‹EğRURUø‹RUüRÿuPÿQ$;ÆtVPWèw&ıÿƒÄjXé¼   ¡d	ÿuü°¸   èfıÿYP¡d	Wÿ   YPWÿ‹5XæƒÄÿuüÿÖ¡d	ÿuø˜¸   è2ıÿYP¡d	Wÿ   YPWÿƒÄÿuøÿÖÿu¡d	ÿØ   Y‹d	PW™¸   ÿ‘   YPWÿ¡d	ÿuô˜¸   èÜıÿƒÄP¡d	Wÿ   YPWÿƒÄÿuôÿÖ3À_^[ÉÃU‹ìQV‹uj ƒeü hçVÿuÿuè«„şÿƒÄƒøtjEüÿ5üPÿvÿuè5*ıÿƒÄ…ÀtjXë'‹EüP‹ÿQ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^ÉÃU‹ìQV‹uEW‹}Pƒeü j h<çVÿuWè1„şÿƒÄƒøt<jEüÿ5üPÿvWè½)ıÿƒÄ…Àu ‹EüURÿu‹PÿQ…Àtj PWèÑ$ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j hpçVÿuWè’ƒşÿƒÄƒøt<jEüÿ5üPÿvWè)ıÿƒÄ…Àu ‹EüURÿu‹PÿQ…Àtj PWè2$ıÿƒÄjXë5¡d	j ÿ5Ü°¸   ÿuèzfıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìƒìSV‹uW3ÿ‹]WWh çVÿu‰}üSèë‚şÿƒÄƒøtZjEüÿ5üPÿvSèw(ıÿƒÄ…Àu>EìP¡d	ÿvÿ   YPÿXê;Çu‹EüURUì‹RPÿQ;ÇtWPSèm#ıÿƒÄjXë4¡d	Wÿ5Ü°¸   ÿuè¶eıÿƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[ÉÃU‹ìƒìSVWEè3ÿP‰}ü‰}øÿdæ‹u‹]WWWhØçVÿuSè‚şÿƒÄƒøtbjEüÿ5tPÿvSè¤'ıÿƒÄ…ÀuFjEøWPÿvSè'ıÿƒÄ…Àu/ÿv¡d	ÿ   Yuè‹MüVPÿuø‹QÿR(;ÇtWPSè’"ıÿƒÄjXë.¡d	°´  EèPèë”ıÿPSÿƒÄfƒ}èu
EèPÿæ3À_^[ÉÃU‹ìƒìV‹uW‹}ƒeü j hèVÿuWèSşÿƒÄƒøt9jEüÿ5tPÿvWèß&ıÿƒÄ…Àu‹EüUìRP‹ÿQ…Àtj PWèö!ıÿƒÄjXë¡d	°´  EìPèıÿPWÿƒÄ3À_^ÉÃU‹ìQQS‹]V‹uƒeø ƒeü j h@èVÿuSèÆ€şÿƒÄƒøt9jEøÿ5tPÿvSèR&ıÿƒÄ…Àu‹EøUüRP‹ÿQ…Àtj PSèi!ıÿƒÄjXë%¡d	ÿuü°´  è[ıÿPSÿƒÄÿuüÿXæ3À^[ÉÃU‹ìQV‹uW‹}ƒeü j hlèVÿuWè6€şÿƒÄƒøt9jEüÿ5tPÿvWèÂ%ıÿƒÄ…Àu‹EüURP‹ÿQ …Àtj PWèÙ ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h˜èVÿuWèşÿƒÄƒøt9jEüÿ5tPÿvWè*%ıÿƒÄ…Àu‹EüURP‹ÿQ$…Àtj PWèA ıÿƒÄjXë5¡d	j ÿ5Ü°¸   ÿuè‰bıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQQV‹u3ÀW‹}PPhÈèV‰Eüÿu‰EøWèù~şÿƒÄƒøt8jEüÿ5tPÿvWè…$ıÿƒÄ…ÀujEøÿ5tPÿvWèi$ıÿƒÄ…ÀtjXë(‹Eüÿuø‹PÿQ<‹d	P±´  ÿ‘Ø   PWÿƒÄ3À_^ÉÃU‹ìQQSV‹uW3ÿ‹]WWhéVÿu‰}ü‰}øSèa~şÿƒÄƒøtNjEüÿ5tPÿvSèí#ıÿƒÄ…Àu2jEøWPÿvSèÖ#ıÿƒÄ…Àu‹Eüÿuø‹PÿQ;ÇtWPSèïıÿƒÄjXë3À_^[ÉÃU‹ìƒìSV‹uW3ÿ‹]WWWh8éV‰}üÿu‰}ô‰}øSèÓ}şÿƒÄƒøthjEüÿ5tPÿvSè_#ıÿƒÄ…ÀuLjEôWPÿvSèH#ıÿƒÄ…Àu5jEøWPÿvSè1#ıÿƒÄ…Àuÿuø‹Eüÿuô‹PÿQ;ÇtWPSèGıÿƒÄjXë3À_^[ÉÃU‹ìQV‹uW‹}ƒeü j hxéVÿuWè6}şÿƒÄƒøtjEüÿ5tPÿvWèÂ"ıÿƒÄ…ÀtjXë-‹EüP‹ÿQ@‹d	j ÿ5@±´  PWèşÿPWÿƒÄ3À_^ÉÃU‹ìƒìSV3ö‹]W‹}VVh¨éWÿu‰uü‰uø‰uôSè±|şÿƒÄƒøtRjEüÿ5tPÿwSè="ıÿƒÄ…Àu6jEøVPÿwSè&"ıÿƒÄ…Àu‹EüUôRÿuø‹PÿQD;ÆtVPSè;ıÿƒÄjXë#¡d	Vÿ5@¸´  ÿuôè„_ıÿPSÿƒÄ3À_^[ÉÃU‹ìQQSV‹uW3ÿ‹]WWhäéVÿu‰}ü‰}øSè|şÿƒÄƒøtSjEüÿ5tPÿvSè!ıÿƒÄ…Àu7jEøÿ5@PÿvSès!ıÿƒÄ…Àu‹Eüÿuø‹PÿQH;ÇtWPSèŒıÿƒÄjXë3À_^[ÉÃU‹ìQQSV‹uW3ÿ‹]WWhêVÿu‰}ü‰}øSèu{şÿƒÄƒøtNjEüÿ5tPÿvSè!ıÿƒÄ…Àu2jEøWPÿvSèê ıÿƒÄ…Àu‹Eüÿuø‹PÿQ;ÇtWPSèıÿƒÄjXë3À_^[ÉÃU‹ìQQSV‹uW3ÿ‹]WWhPêVÿu‰}ü‰}øSèìzşÿƒÄƒøtXjEüÿ5˜PÿvSèx ıÿƒÄ…Àu<jEøÿ5lPÿvSè\ ıÿƒÄ…Àu ‹EüURWÿuø‹PÿQP;ÇtWPSèpıÿƒÄjXëJ9}t¡d	jÿÿuÿğ  Y‹ğYÿuÿ0êë¡d	Whœÿè   Y‹ğY¡d	VSÿ´  Y3ÀY_^[ÉÃU‹ìQQSV‹uW3ÿ‹]WWh€êVÿu‰}ü‰}øSèzşÿƒÄƒøtSjEüÿ5|PÿvSèıÿƒÄ…Àu7jEøÿ5ˆPÿvSèıÿƒÄ…Àu‹Eüÿuø‹PÿQ;ÇtWPSèšıÿƒÄjXë3À_^[ÉÃU‹ìQV‹uj ƒeü h´êVÿuÿuè‹yşÿƒÄƒøt9jEüÿ5|PÿvÿuèıÿƒÄ…Àu‹EüP‹ÿQ…Àtj Pÿuè.ıÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü hàêVÿuÿuèyşÿƒÄƒøt<jEüÿ5|Pÿvÿuè§ıÿƒÄ…Àu‹Eüÿu‹PÿQ…Àtj Pÿuè½ıÿƒÄjXë3À^ÉÃU‹ìQQSV‹uW3ÿ‹]WWhëVÿu‰}ü‰}øSè¨xşÿƒÄƒøtRjEüÿ5$PÿvSè4ıÿƒÄ…Àu6jEøWPÿvSèıÿƒÄ…Àu‹EüURÿuø‹PÿQ;ÇtWPSè2ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PS±¸   ÿ‘   YPSÿƒÄ3À_^[ÉÃU‹ìQQSV‹uW3ÿ‹]WWhPëVÿu‰}ü‰}øSèğwşÿƒÄƒøtSjEüÿ5$PÿvSè|ıÿƒÄ…Àu7jEøÿ5ÔPÿvSè`ıÿƒÄ…Àu‹Eüÿuø‹PÿQ;ÇtWPSèyıÿƒÄjXë3À_^[ÉÃU‹ìQEV‹uPj ƒeü hœëVÿuÿuèfwşÿƒÄƒøt<jEüÿ5$PÿvÿuèğıÿƒÄ…Àu‹Eüÿu‹PÿQ…Àtj PÿuèıÿƒÄjXë3À^ÉÃU‹ìQV‹uW‹}ƒeü j hÜëVÿuWè÷vşÿƒÄƒøt9jEüÿ5øPÿvWèƒıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWèšıÿƒÄjXë5¡d	j ÿ5Ø°¸   ÿuèâYıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìƒìSV‹uW3ÿ‹]WWh0ìVÿu‰}üSèSvşÿƒÄƒøtZjEüÿ5øPÿvSèßıÿƒÄ…Àu>EìP¡d	ÿvÿ   YPÿXê;Çu‹EüURUì‹RPÿQ;ÇtWPSèÕıÿƒÄjXë4¡d	Wÿ5$°¸   ÿuèYıÿƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[ÉÃU‹ìQV‹uEW‹}Pƒeü j hŒìVÿuWèuşÿƒÄƒøt@jEüÿ5ØPÿvWèıÿƒÄ…Àu$‹EüURU‹RÿuPÿQ…Àtj PWè*ıÿƒÄjXë_¡d	j ÿ5$°¸   ÿuèrXıÿƒÄP¡d	Wÿ   YPWÿÿu¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uj ƒeü hĞìVÿuÿuè¿tşÿƒÄƒøt9jEüÿ5ØPÿvÿuèIıÿƒÄ…Àu‹EüP‹ÿQ…Àtj PÿuèbıÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü híVÿuÿuèQtşÿƒÄƒøt<jEüÿ5ØPÿvÿuèÛıÿƒÄ…Àu‹Eüÿu‹PÿQ…Àtj PÿuèñıÿƒÄjXë3À^ÉÃU‹ìQV‹uW‹}ƒeü j hPíVÿuWèâsşÿƒÄƒøt9jEüÿ5üPÿvWènıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWè…ıÿƒÄjXë5¡d	j ÿ5Ü°¸   ÿuèÍVıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uEW‹}Pƒeü j hŒíVÿuWè<sşÿƒÄƒøt<jEüÿ5ĞPÿvWèÈıÿƒÄ…Àu ‹EüUìRÿu‹PÿQ…Àtj PWèÜıÿƒÄjXë¡d	°´  EìPèèıÿPWÿƒÄ3À_^ÉÃU‹ìƒìSV‹uW3ÿ‹]WWWhĞíV‰}üÿuSè¬rşÿƒÄƒøtojEüÿ5LPÿvSè8ıÿƒÄ…ÀuSÿv¡d	ÿ   ‰EYEìP¡d	ÿvÿ   YPÿXê;Çu‹EüURUì‹RÿuPÿQ;ÇtWPSèıÿƒÄjXë4¡d	Wÿ5´°¸   ÿuèbUıÿƒÄP¡d	Sÿ   YPSÿƒÄ3À_^[ÉÃU‹ìQQSV‹u3ÛW‹}SSShîV‰]øÿu‰]üWèÏqşÿƒÄƒø„ƒ   jEøÿ5LPÿvWèWıÿƒÄ…Àugÿv¡d	ÿ   j‰Eÿ5˜EüPÿvWè*ıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àuÿuü‹Eøÿu‹PÿQ$;ÃtSPWè$ıÿƒÄjXë3À_^[ÉÃU‹ìQV‹uj j ƒeü hPîVÿuÿuèqşÿƒÄƒøtIjEüÿ5LPÿvÿuèıÿƒÄ…Àu+ÿv¡d	ÿ   Y‹MüPQ‹ÿR…Àtj Pÿuè¦ıÿƒÄjXë3À^ÉÃU‹ìQV‹uW‹}ƒeü j hˆîVÿuWè—pşÿƒÄƒøt9jEüÿ5LPÿvWè#ıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWè:ıÿƒÄjXë5¡d	j ÿ5Œ°¸   ÿuè‚SıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìƒìSV‹uW3ÿ‹]WWWh¸îV‰}üÿuSèòoşÿƒÄƒøtWjEüÿ5LPÿvSè~ıÿƒÄ…Àu;ÿv¡d	ÿ   ‰EYEìP¡d	ÿvÿ   YPÿXê;ÇtWPSèwıÿƒÄjXë,‹EüUìRÿu‹PÿQ(‹d	P±´  ÿ‘Ø   PSÿƒÄ3À_^[ÉÃU‹ìƒì$SV‹u3ÛWSSSShøîV‰]üÿuÿuè7oşÿƒÄ ƒø„“   jEüÿ5LPÿvÿuè½ıÿƒÄ…Àuuÿv¡d	ÿ   ‰EYEÜP¡d	ÿvÿ   ‹=XêYPÿ×;Ãu6EìP¡d	ÿvÿ   YPÿ×;ÃuU‹EüRUì‹RUÜRÿuPÿQ ;ÃtSPÿuè|ıÿƒÄjXë8¡d	Sÿ5´°¸   ÿuèÅQıÿƒÄP¡d	ÿuÿ   YPÿuÿƒÄ3À_^[ÉÃU‹ìQV‹uW3ÿWWhDïVÿu‰}üÿuè5nşÿƒÄƒøtWjEüÿ5LPÿvÿuè¿ıÿƒÄ…Àu9E‰}P¡d	ÿvÿĞ  9}YYu3À‹MüPQ‹ÿR;ÇtWPÿuèºıÿƒÄjXë3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hˆïVÿuWèªmşÿƒÄƒøt9jEüÿ5LPÿvWè6ıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWèMıÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hÄïVÿuWèmşÿƒÄƒøt9jEüÿ5ŒPÿvWèıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWè´ıÿƒÄjXë5¡d	j ÿ5Œ°¸   ÿuèüOıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uj ƒeü hôïVÿuÿuèslşÿƒÄƒøt9jEüÿ5ŒPÿvÿuèııÿƒÄ…Àu‹EüP‹ÿQ…Àtj PÿuèıÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü h$ğVÿuÿuèlşÿƒÄƒøt<jEüÿ5ŒPÿvÿuèıÿƒÄ…Àu‹Eüÿu‹PÿQ…Àtj Pÿuè¥ıÿƒÄjXë3À^ÉÃU‹ìQV‹uW‹}ƒeü j hXğVÿuWè–kşÿƒÄƒøtYjEüÿ5˜PÿvWè"ıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu!‹EüURU‹RPÿQ…Àtj PWèıÿƒÄjXë_·EP¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿ¡d	j ÿ5´°¸   ÿuè7NıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j h˜ğVÿuWè¨jşÿƒÄƒøtTjEüÿ5˜PÿvWè4ıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu‹Eüÿu‹PÿQ…Àtj PWè0ıÿƒÄjXë3À_^ÉÃU‹ìQSV‹u3ÛW‹}SShàğVÿu‰]üWèjşÿƒÄƒøtnjEüÿ5˜PÿvWèªıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu6EP¡d	ÿvWÿ¤   ƒÄ…Àu‹EüSÿu‹PÿQ8;ÃtSPWèŒ
ıÿƒÄjXë3À_^[ÉÃU‹ìQV‹uW‹}ƒeü j h$ñVÿuWè{işÿƒÄƒøtUjEüÿ5˜PÿvWèıÿƒÄ…ÀtjEüÿ5ØPÿvWèëıÿƒÄ…Àu‹EüURP‹ÿQ|…Àtj PWè
ıÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hlñVÿuWèÆhşÿƒÄƒøtUjEüÿ5˜PÿvWèRıÿƒÄ…ÀtjEüÿ5ØPÿvWè6ıÿƒÄ…Àu‹EüURP‹ÿQL…Àtj PWèM	ıÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h¨ñVÿuWèhşÿƒÄƒøtUjEüÿ5˜PÿvWèıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu‹EüURP‹ÿQT…Àtj PWè˜ıÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j häñVÿuWè\gşÿƒÄƒøtUjEüÿ5˜PÿvWèèıÿƒÄ…ÀtjEüÿ5ØPÿvWèÌıÿƒÄ…Àu‹EüURP‹ÿQD…Àtj PWèãıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h òVÿuWè¨fşÿƒÄƒøtUjEüÿ5˜PÿvWè4ıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu‹EüURP‹ÿQt…Àtj PWè/ıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h\òVÿuWèôeşÿƒÄƒøtYjEüÿ5˜PÿvWè€ıÿƒÄ…ÀtjEüÿ5ØPÿvWèdıÿƒÄ…Àu!‹EüURU‹RPÿQ,…Àtj PWèwıÿƒÄjXë[·EP¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿ·EP¡d	ÿØ   ‹d	ƒÄPW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}ƒeü j h˜òVÿuWèeşÿƒÄƒøtUjEüÿ5˜PÿvWè˜
ıÿƒÄ…ÀtjEüÿ5ØPÿvWè|
ıÿƒÄ…Àu‹EüUìRP‹ÿQ<…Àtj PWè“ıÿƒÄjXë¡d	°´  EìPè5öüÿPWÿƒÄ3À_^ÉÃU‹ìƒìV‹uW‹}ƒeü j hàòVÿuWèfdşÿƒÄƒøtUjEüÿ5˜PÿvWèò	ıÿƒÄ…ÀtjEüÿ5ØPÿvWèÖ	ıÿƒÄ…Àu‹EüUìRP‹ÿQ$…Àtj PWèíıÿƒÄjXë¡d	°´  EìPèõüÿPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h óVÿuWèÂcşÿƒÄƒøtUjEüÿ5˜PÿvWèN	ıÿƒÄ…ÀtjEüÿ5ØPÿvWè2	ıÿƒÄ…Àu‹EüURP‹ÿQ@…Àtj PWèIıÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j h\óVÿuWè
cşÿƒÄƒøtXjEüÿ5˜PÿvWè–ıÿƒÄ…ÀtjEüÿ5ØPÿvWèzıÿƒÄ…Àu ‹EüURÿu‹PÿQ…Àtj PWèıÿƒÄjXë5¡d	j ÿ5´°¸   ÿuèÖEıÿƒÄP¡d	Wÿ   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h óVÿuWèKbşÿƒÄƒøtUjEüÿ5˜PÿvWè×ıÿƒÄ…ÀtjEüÿ5ØPÿvWè»ıÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWèÒıÿƒÄjXë/·EP¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j hàóVÿuWè‘aşÿƒÄƒøtXjEüÿ5˜PÿvWèıÿƒÄ…ÀtjEüÿ5ØPÿvWèıÿƒÄ…Àu ‹EüURÿu‹PÿQ…Àtj PWèıÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h,ôVÿuWèÙ`şÿƒÄƒøtQjEüÿ5˜PÿvWèeıÿƒÄ…ÀtjEüÿ5ØPÿvWèIıÿƒÄ…Àu‹EüP‹ÿQ0…Àtj PWèdıÿƒÄjXë3À_^ÉÃU‹ìQV‹uW3ÿWWWh`ôV‰}üÿuÿuèS`şÿƒÄƒø„   jEüÿ5˜PÿvÿuèÙıÿƒÄ…ÀtjEüÿ5ØPÿvÿuè»ıÿƒÄ…ÀuS¡d	Sÿvÿ   ÿv‹Ø¡d	ÿ   ‹ğh,$VÿÜäƒÄ…Àu3ö‹EüVSP‹ÿQx;Ç[tWPÿuèœ ıÿƒÄjXë3À_^ÉÃU‹ìQS‹]V‹uj ƒeü j h¸ôVÿuSèŠ_şÿƒÄƒøtajEüÿ5˜PÿvSèıÿƒÄ…ÀtjEüÿ5ØPÿvSèúıÿƒÄ…Àu)ÿv¡d	ÿ   Y‹MüPQ‹ÿRH…Àtj PSè ıÿƒÄjXë3À^[ÉÃU‹ìQS‹]V‹uj ƒeü j h õVÿuSèó^şÿƒÄƒøtajEüÿ5˜PÿvSèıÿƒÄ…ÀtjEüÿ5ØPÿvSècıÿƒÄ…Àu)ÿv¡d	ÿ   Y‹MüPQ‹ÿRP…Àtj PSènÿüÿƒÄjXë3À^[ÉÃU‹ìQV‹uEW‹}Pƒeü j hHõVÿuWèZ^şÿƒÄƒøtTjEüÿ5˜PÿvWèæıÿƒÄ…ÀtjEüÿ5ØPÿvWèÊıÿƒÄ…Àu‹Eüÿu‹PÿQ`…Àtj PWèâşüÿƒÄjXë3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j h”õVÿuWèÎ]şÿƒÄƒøtTjEüÿ5˜PÿvWèZıÿƒÄ…ÀtjEüÿ5ØPÿvWè>ıÿƒÄ…Àu‹Eüÿu‹PÿQh…Àtj PWèVşüÿƒÄjXë3À_^ÉÃU‹ìQV‹uEW‹}Pƒeü j häõVÿuWèB]şÿƒÄƒøtTjEüÿ5˜PÿvWèÎıÿƒÄ…ÀtjEüÿ5ØPÿvWè²ıÿƒÄ…Àu‹Eüÿu‹PÿQp…Àtj PWèÊıüÿƒÄjXë3À_^ÉÃU‹ìQV‹uEWPE‹}Pƒeü j h$öVÿuWè²\şÿƒÄƒøtWjEüÿ5˜PÿvWè>ıÿƒÄ…ÀtjEüÿ5ØPÿvWè"ıÿƒÄ…Àuÿu‹Eüÿu‹PÿQ(…Àtj PWè7ıüÿƒÄjXë3À_^ÉÃU‹ìQSV‹uW3ÿ‹]WWhŒöVÿu‰}üSè%\şÿƒÄƒø„…   jEüÿ5˜PÿvSè­ıÿƒÄ…ÀtjEüÿ5ØPÿvSè‘ıÿƒÄ…ÀuMEP¡d	ÿvÿŒ   }ÿÿ  YY~¡d	WhpöSÿ¨  ë‹MüPÿu‹QÿRX;ÇtWPSèxüüÿƒÄjXë3À_^[ÉÃU‹ìQV‹uW‹}ƒeü j hÜöVÿuWèg[şÿƒÄƒøtQjEüÿ5˜PÿvWèó ıÿƒÄ…ÀtjEüÿ5ØPÿvWè× ıÿƒÄ…Àu‹EüP‹ÿQ4…Àtj PWèòûüÿƒÄjXë3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h÷VÿuWèâZşÿƒÄƒøt<jEüÿ5˜PÿvWèn ıÿƒÄ…Àu ‹EüURP‹ÿ‘„   …Àtj PWè‚ûüÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hD÷VÿuWèFZşÿƒÄƒøt<jEüÿ5˜PÿvWèÒÿüÿƒÄ…Àu ‹EüURP‹ÿ‘¬   …Àtj PWèæúüÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hh÷VÿuWè«YşÿƒÄƒøt<jEüÿ5˜PÿvWè7ÿüÿƒÄ…Àu ‹EüURP‹ÿ‘Œ   …Àtj PWèKúüÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hŒ÷VÿuWèYşÿƒÄƒøt<jEüÿ5˜PÿvWè›şüÿƒÄ…Àu ‹EüURP‹ÿ‘œ   …Àtj PWè¯ùüÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j h°÷VÿuWètXşÿƒÄƒøt<jEüÿ5˜PÿvWè şüÿƒÄ…Àu ‹EüURP‹ÿ‘¤   …Àtj PWèùüÿƒÄjXë-ÿu¡d	ÿØ   Y‹d	PW±¸   ÿ‘   YPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hÔ÷VÿuWèÙWşÿƒÄƒøt<jEüÿ5˜PÿvWèeıüÿƒÄ…Àu ‹EüURP‹ÿ‘”   …Àtj PWèyøüÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìQV‹uj j ƒeü h øVÿuÿuè=WşÿƒÄƒøtLjEüÿ5˜PÿvÿuèÇüüÿƒÄ…Àu.ÿv¡d	ÿ   Y‹MüPQ‹ÿ’€   …Àtj PÿuèÍ÷üÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü h0øVÿuÿuè¼VşÿƒÄƒøt?jEüÿ5˜PÿvÿuèFüüÿƒÄ…Àu!‹Eüÿu‹Pÿ‘¨   …Àtj PÿuèY÷üÿƒÄjXë3À^ÉÃU‹ìQV‹uj j ƒeü h`øVÿuÿuèJVşÿƒÄƒøtLjEüÿ5˜PÿvÿuèÔûüÿƒÄ…Àu.ÿv¡d	ÿ   Y‹MüPQ‹ÿ’ˆ   …Àtj PÿuèÚöüÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü hŒøVÿuÿuèÉUşÿƒÄƒøt?jEüÿ5˜PÿvÿuèSûüÿƒÄ…Àu!‹Eüÿu‹Pÿ‘˜   …Àtj PÿuèföüÿƒÄjXë3À^ÉÃU‹ìQEV‹uPj ƒeü h¸øVÿuÿuèUUşÿƒÄƒøt?jEüÿ5˜PÿvÿuèßúüÿƒÄ…Àu!‹Eüÿu‹Pÿ‘    …Àtj PÿuèòõüÿƒÄjXë3À^ÉÃU‹ìQV‹uj j ƒeü häøVÿuÿuèãTşÿƒÄƒøtLjEüÿ5˜PÿvÿuèmúüÿƒÄ…Àu.ÿv¡d	ÿ   Y‹MüPQ‹ÿ’   …Àtj PÿuèsõüÿƒÄjXë3À^ÉÃU‹ìƒì4V‹uW‹}ƒeü j hùVÿufÇEÌ0 Wè\TşÿƒÄƒøt9jEüÿ5´PÿvWèèùüÿƒÄ…Àu‹EüUÌRP‹ÿQ…Àtj PWèÿôüÿƒÄjXë¡d	°´  EÌPè@ìıÿPWÿƒÄ3À_^ÉÃU‹ìQV‹uW‹}ƒeü j hDùVÿuWèÔSşÿƒÄƒøt9jEüÿ5´PÿvWè`ùüÿƒÄ…Àu‹EüURP‹ÿQ…Àtj PWèwôüÿƒÄjXë.ƒ} t&¡d	jÿÿu°´  ÿğ  PWÿƒÄÿuÿ0ê3À_^ÉÃU‹ìƒì4S‹]V‹uj ƒeü j h|ùVÿuSè7SşÿƒÄƒøtMjEüÿ5´PÿvSèÃøüÿƒÄ…Àu1EÌPÿvSèÀïıÿƒÄ…Àu‹EüUÌRP‹ÿQ…Àtj PSèÆóüÿƒÄjXë3À^[ÉÃU‹ìQSV‹u3ÛW‹}Sh¸ùV‰]üÿuWèµRşÿƒÄƒøtjEüÿ5xPÿvWèAøüÿƒÄ…ÀtjXë}‹EüURP‹ÿQ ‹d	P±´  ÿ‘Ø   PWÿƒÄ9]t¡d	jÿÿuÿğ  Y‹ØYÿuÿ0êë¡d	Shœÿè   Y‹ØY¡d	SW°¸   ÿ   YPWÿƒÄ3À_^[ÉÃU‹ìQV‹uj ƒeü hèùVÿuÿuèëQşÿƒÄƒøtjEüÿ5xPÿvÿuèu÷üÿƒÄ…ÀtjXë'‹EüP‹ÿQ‹d	P±´  ÿ‘Ø   PÿuÿƒÄ3À^ÉÃU‹ìQEV‹uPj j ƒeü húVÿuÿuèqQşÿƒÄƒøtLjEüÿ5xPÿvÿuèûöüÿƒÄ…Àu.ÿv¡d	ÿ   Y‹Müÿu‹PQÿR…Àtj PÿuèòüÿƒÄjXë3À^ÉÃU‹ìQV‹uWE3ÿPWWhLúVÿu‰}üÿuèîPşÿƒÄƒøtZjEüÿ5xPÿvÿuèxöüÿƒÄ…Àu<E‰}P¡d	ÿvÿĞ  9}YYu3À‹Müÿu‹PQÿR;ÇtWPÿuèpñüÿƒÄjXë3À_^ÉÃU‹ìQV‹uj j ƒeü hŒúVÿuÿuè`PşÿƒÄƒøtIjEüÿ5xPÿvÿuèêõüÿƒÄ…Àu+ÿv¡d	ÿ   Y‹MüPQ‹ÿR…Àtj PÿuèóğüÿƒÄjXë3À^ÉÃS‹\$…Ûtj hğúSèÓy  ƒÄ…ÀujX[Ã¡d	VhèúhàúSÿL  ¡d	hÄúSÿ  ƒÄƒ=ğ u/¡<¤…Àt3öPèÂ   ‰†°‹†@¤ƒÆY…ÀuæÇğ   ¡pL…Àt&¾tLj ÿvÿ6P¡d	Sÿˆ  ‹FƒÆƒÄ…Àuß¡À…ÀtZW¿À¾ÄjhœP¡d	Sÿ¼  ÿ6¡d	ÿvjÿ7Sÿä  ÿ6¡d	ÿvj!ÿ7Sÿä  ƒÆƒÄ8‹Fü~ü…Àu²_hĞSèu   Y3ÀY^[Ã¡<V‹t$W…À‹øtÿ6ÿ7è,‡  Y…ÀYt0‹…ÿuê¡<‰F‹Ö3ÿ‰5<‹ÂNƒ9 t‰J‰Q‹ÑƒÁëî‹G…Àt‰F‹×‹ëØ…ÿt‰W‰z_^ÃU‹ìQW3ÿ9=Du¡d	WhøÿÜ  YÇD   Y‹E98„Ë   SVp‹ Ht^HtEHt1HtH…    ‹FWÿ0ÿvğÿ6è¤   ƒÄëH‹FWÿ0ÿ6èG1ıÿƒÄë6¡d	jÿÿ6ÿè   ëİFø¡d	QQİ$ÿÔ   Yëÿvğ¡d	ÿØ   Y‹Ø;ßt=¡d	jSj jÿ¸  ÿvìÿè   YYPÿuÿEüPÿvìhøÿ(ƒÄ ‰X3ÿƒÆ 9~èFè…<ÿÿÿ^[_ÉÃU‹ìì   V‹uÿ6è†  Y‹MDH=è  v3Àë6Q…üÿÿÿuÆ… üÿÿ_Pèë0ıÿÿ6Pè‡  … üÿÿjÿP¡d	ÿè   ƒÄ^ÉÃU‹ìƒìS‹]3ÀV‹uƒûW‰Eü‰Eô‰Eø‰EğÇEì   ŒJ  EP¡d	ÿvÿuÿ¤   ƒÄ…À…_  EP¡d	ÿvÿuÿ    ƒÄ…À…?  ‹Ej_¹ÿ   j#ÁZt4ƒøt%ƒøtƒøt%;Ç†[  ƒøvéQ  ‹E$ë‹E$Â‰E¸   9E‡   „¬  ƒ} @„   }   €„ö  ƒ}„Í   ƒ}„  9}„v  ƒ}„l  ƒ}ë0‹Eƒè@„Z  ƒè@„Q  -€   „F  -   „;  -   „0  é  ¸   9EÜ   t_‹E=   „  =    „  = @  „÷   = €  t=   ë³;ÚŒå   EôP¡d	ÿvÿuÿ¤   ƒÄ…À…ú  éß  ;ÚŒ¸   ‹E#Át-;Â…#  ÿv¡d	ÿ   ÿv‰Eü¡d	ÿ   Yé?  EøPÿvÿuè]àüÿƒÄ…À…Ÿ  EğPÿvÿuèCàüÿƒÄ…À……  ‹Eø‰Eüé^  }8 „—   }   t+}   „œ   }àtx}ÿÿÿtoj hLûé…   ;ß}¡d	h(ûVjÿuÿ(  ƒÄé  ‹E#Át;ÂuQÿv¡d	ÿ   Y‰Eüéß   EøPÿvÿuè™ßüÿƒÄ…À…Û   ‹EøëÙ;ßŒ¸   ‹E#Áƒè trƒètHHHtj hôúÿu¡d	ÿ¨  ƒÄé   ÿv¡d	ÿ   ;ßY‰Eü~rÿv¡d	ÿ   Yë^EüP¡d	ÿvÿuÿ¤   ƒÄ…Àu[;ß~Aé8şÿÿEøPÿvÿuèöŞüÿƒÄ…Àu<‹Eø;ß‰Eü~EğPÿvÿuèÖŞüÿƒÄ…Àu‹Eğ‰Eôÿuôÿuüÿuÿuÿøæƒeì ƒ}ø _^[t	ÿuøèCßüÿYƒ}ğ t	ÿuğè4ßüÿY‹EìÉÃU‹ìV‹ujFPÿuèXƒ  ƒÄ…Àt9jh¨ëÿuèBƒ  ƒÄ…Àt#jhˆëÿuè,ƒ  ƒÄ…Àt‹Eƒ  ¸@ €ë‹VÿP‹E‰03À^]Â ‹D$ÿ@‹@Â V‹t$ÿN‹Fu<‹F…ÀtP¡d	ÿh  Y‹F…Àtÿ‹Fƒ8 P¡d	ÿ€   YVÿåY3À^Â ‹D$…Àtƒ  3ÀÂ ¸@ €Â ¸@ €Â U‹ììì   SVW‹}3Û;ûu
¸@ €éÏ  EøPEüP¡d	ÿwSÿ¼   ƒÄ…Àt
¸@ €é§  ‹Eü…   Pÿ$å‹ğY;óu
¸ €é…  3À9]ü~‹Mø‹‰†@;Eü|ñÿu¡d	ÿà   ‹Müÿu‰¡d	ÿà   ‹Mü‰D·EP¡d	ÿØ   ‹MüSS‰D¡d	ƒEüÿÜ   ‹MüƒÄ‰‹M;ËtB‹AHx<‹ØÁã@‰Eë‹M¡d	¸¸   ‹ÃPè£ZıÿP‹Eüÿ4†j ÿƒÄƒëÿMuÒ‹}ÿEü3Û3É9]ü~‹Ö‹ƒÂÿ A;Mü|ó‹WÿP…ÿÿÿP¡d	ÿwÿô  ¡d	h   Vÿuüÿwÿ˜  ƒÄ;Ã‰Et‹]$…Ût&j j Sè”  ‹EƒÄ‰Cë9] t	ÿu ÿdæ‰]…ÿÿÿP¡d	ÿwÿğ  3ÛY9]üY~!‹ÿ‹ƒ8 P¡d	ÿ€   YCƒÆ;]ü|ß‹WÿP‹E_^[ÉÂ$ U‹ìƒìƒ}St¡d	hœûÿujÿuÿ(  ƒÄëH‹]EğP¡d	ÿsÿ   YPÿ@ê…À}j PÿuèìæüÿƒÄëEPj j ÿuè½ÕüÿƒÄ…ÀtjXëc‹EVWuğÇ €û‹Ex¥¥¥¥‹}¡d	Wÿ,  ‹E‰x‹EÇ@   ‹Cÿ ‹M‹C‰A¡d	ÿu°´  è WıÿPWÿƒÄ3À_^[ÉÃU‹ììŒ   S‹]VWj3ÿ^ƒû‰}Ø‰uÈ}!¡d	h¸üÿuVÿuÿ(  ƒÄ‹Æéh  ‹uEĞPÿvÿuèÊVıÿƒÄ…À…H  EèPEÌP¡d	ÿv‹uVÿ¼   ƒÄ…À…#  ƒ}Ì}Wh`üVé  E˜P‹Eèÿ0¡d	Vÿ¤   ƒÄ…À…ñ  E¤P‹Eèÿp¡d	Vÿ¤   ƒÄ…À…Ğ  EüP‹Eèÿp¡d	Vÿ    ƒÄ…À…¯  ‹Eü‰EìEÜP‹EèÿpVèJVıÿƒÄ…À…  ƒ}Ì|&EÔPEôP‹Eèÿp¡d	Vÿ¼   ƒÄ…Àtéb  Cı‰}Ô‰Eôë‹Eô‹5$å\ ‰E‹ÃÁàP‰] ÿÖ‰Eø‹EôD PÿÖY‰EàY‹Mø;Ï„  ;Ç„   ;ß‰}ü~‹EüÁàf‰<ÿEü9]ü|î‹EôƒÁ‹ĞÇEœıÿÿÿ÷ÚÒ#ÑöEì‰Uˆt5jY;Át¡d	Wh(üÿuÿ¨  ƒÄéQ  ‰M”Mœ‰MŒÇEÜ   ë‰}”‰}Œ;Ç‰}ü‹Ø„   ‹Mà‹ğÁæuøA‰EğVÿdæ‹EôÃÁàEøPÿdæ‹MüA;E|3Àë‹U‹‚‹UÔ;×t‹Šë3ÉP‹EôÿuğÃÁàEøPVQÿuèKtıÿƒÄ…À…º  ÿEüƒmğKƒî;ßuj E¨WPè²{  ƒÄUäƒMäÿ‹EĞRU¨Rf‹UÜfƒê‹f÷ÚÒ#UøRUˆRÿuìÿu¤hxëÿu˜PÿQ‹ğ‰}Ğ;÷‰uØŒ¢   fƒ}Üt¡d	ÿuø°´  èÛUıÿPÿuÿƒÄ‹EôjY‰Eğ9M‰Mü~f‹Mà‹ğÁæuøA‰Eì9}ğtPö t2¡d	h   V˜  èUıÿY‹MP‹EüWÿ4ÿuÿƒÄ…À„Ó  ÿEü‹EìÿMğ‹MüHƒîH;M‰Eì|«‰}Èé²  ş	 €…N  9}ÀtE¨PÿUÀ¡d	WWÿÜ   ‹ğ¡d	j
hü˜¸   ÿè   PVWÿ¡d	ÿu¬˜¸   è”ÒüÿPVWÿ¡d	jhü˜¸   ÿè   PVWÿ¡d	ƒÄ@ÿu°˜¸   è\ÒüÿPVWÿ¡d	jhüû˜¸   ÿè   PVWÿ¡d	ÿu´˜¸   è'ÒüÿPVWÿ¡d	jhìû˜¸   ÿè   PVWÿ¡d	ƒÄHÿu¸˜¸   ÿà   PVWÿ¡d	jhäû˜¸   ÿè   PVWÿ¡d	ÿuÄ˜¸   ÿà   PVWÿ¡d	jhÜû˜¸   ÿè   PVWÿ·M¨¡d	ƒÄHQ˜¸   ÿà   PVWÿVh	 €ÿuè]áüÿƒÄ9}°tFÿu¡d	ÿ   ‹Ø¡d	jhÜGSÿ  ¡d	ƒÄÿu°°  ÿ0æPÿu°SÿƒÄët9}Äto‹EÄ%  ÿ=   t=   t=   t=   uKÿuÄèdßüÿ‹ØY;ßt<ÿu¡d	ÿ   ‹ğ¡d	jhÜGVÿ  ¡d	jÿSVÿ  SÿåƒÄ ÿu¬‹5XæÿÖÿu°ÿÖÿu´ÿÖëXWVÿuèzàüÿƒÄş €tş €u;ƒ}äÿt5ÿuä…tÿÿÿhÀVjPÿ(å…tÿÿÿWP¡d	hÀûÿuÿ   ƒÄ 9}Ø|‹Eøfƒ8uPÿæ‹u jX;ğ‰Eü~‹EüÁàEøPÿuèYwıÿÿEü9uüYY|äÿuø‹5åÿÖÿuàÿÖ‹EÈYYëWh¤ûÿu¡d	ÿ¨  ƒÄjX_^[ÉÃè   é   ¹%ÿ%€ähvUè y  YÃ¹%ÿ%|äè   é   ¹$ÿ%xäh¢Uèôx  YÃ¹$ÿ%täè   é&   QŠD$j j ¹¢è˜  ƒ% £YÃhéUè­x  YÃö0u€0¹é^  Ã‹ …ÉtV‹ñè   VèŠx  ƒ%  Y^ÿ%°é¸VÑèx  QV‹ñW‰uğƒ~D ‹=hãÇEü   t"j j jÿvHÿ èhè  ÿvDÿxãÿvDÿ×‹F@…ÀtPÿ×N0è½  N$ÆEüèy  €eü Nè5  VÿLâ‹Mô_^d‰    ÉÃQÿLâÃU‹ìì  SV‹5Tâ3ÛWS¿,jWÿÖ+ÃtJHt-H„Ö   HSth$şëhÈıÿu¡d	ÿ¨  ƒÄé’   j[SSWÿÖ;Ã„    j ÿPâëé…pşÿÿPh  ÿé…ÀtSh¨ıëBèü   …ÀuSh|ıë1èÆ*  …ÀuShTıë èµO  …ÀuShıëè«H  …ÀSu"hÜüÿu¡d	ÿ¨  ƒÄjjWÿÖjXë¡d	hVÿ|  YYjjWÿÖ3À_^[ÉÃ¸lÑèçv  QV‹ñ‰uğÇàê‹Fƒeü …ÀtP¡d	ÿh  YƒMüÿjNÿ¬ä‹Mô^d‰    ÉÃÿt$‹AƒÁÿt$PQè†   ƒÄÂ V‹ñè’ÿÿÿöD$tVèhv  Y‹Æ^Â ¡…Àu)P¡d	h1^ÿ$  Y£(Yj j j ÿXâ£3É…À•Á‹ÁÃƒ= tÿ5(¡d	ÿ(  Yÿ5ÿhãÃ¸Ñèv  ƒìSVW3Û‰eğÿu‰]ìÿuèƒ  Y;ÃY‰EujX‹Mô_^d‰    [ÉÃ‹5äƒÀ0PÿÖ‹}‰]ü;ût'‹EƒÀ0PÿÖ‹ESSSS‰xÿ\â‹M‰A,‹E9X,ty‹EƒÀ0PÿÖ‹5xãjÿÿ5ÿÖ÷ØÀ@‰Eu3Àë¡MQPE¹Pè”	  ÿ5(¡d	ÿ0  Yÿ5ÿ0â;ût`‹EWÿp,ÿÖ;Ãtÿüã£ÇEì   ë?9]t:‹MEÜPè_   ‹\äÆEüÿ1‹MSPÿ`äjMÜˆ]üÿdä‹E‹@(‰EìƒMüÿ9]t	ÿuèA  Y‹EìéÙşÿÿ3Û9]t	ÿuè)  YSSèÄt  U‹ìQŠAƒeü VqW‹}j ‹Ïˆÿdä¡\ä‹Ïÿ0j Vÿ`ä‹Ç_^ÉÂ ¸–Ñè[t  Qj4èt  Y‹È‰Mğ3À;È‰EütPÿuÿuè   ‹Môd‰    ÉÃ¸´Ñè"t  Q‹ESV‹ñ3ÛW;Ã‰uğ‰tP¡d	ÿ,  Y‹E‰]ü‹@;Ãu¡Tä‰EŠE~S‹Ïˆÿ¬äÿuèûq  YP‹ÏÿuÿXä‹EN‰FŠESÆEüˆÿdä‹Mô‰^(‰^,‰^0‹Æ_^[d‰    ÉÂ ‹…ÀtP¡d	ÿh  YÃV‹t$F0Pÿ`â…Àu…öt‹Îè	   VèKs  Y^Ã¸ÔÑèLs  QV‹ñ‰uğ‹F,ÇEü   …ÀtPÿhãjNÿdä€eü jNÿ¬ä‹6ƒMüÿ…öt¡d	Vÿh  Y‹Mô^d‰    ÉÃU‹ìVW‹}ƒ tEŠEƒì‹ô‰ej ‹ÎˆÿdäÿuÿåYP‹ÎÿuÿPäÿu‹Ïè   ‹G,…ÀtPÿdâWèÿÿÿY_^]Ã¸éÑèŠr  3À9A‰Eüt‹U‰Q(‹\äƒÁÿ2PEPÿ`äƒMüÿjMÿdä‹Môd‰    ÉÂ ¸Òè=r  ƒì öEu3Àée  ‹ESW‹x‹…Û„:  ¡d	Sÿè  …ÀY…%  EÔVP‹Ïè>  ‹@ƒeü ‹5Tä…Àt‹ğŠEj MäˆEäÿ¬äVèøo  YPVMäÿXäjMÔÆEüÿ¬ä‹Eè…Àu¡TäP¡d	Sÿ  ‰E¡d	Sÿè  ƒÄ…À…‘   ƒ}u[¾TşVè™o  YPVj MäÿHä¾PşVè€o  YPVMäÿLä‹Eè…Àu¡TäÿuìP¡d	Sÿ  ¡d	Sÿ8  ƒÄ¡d	S°   ÿ   PÿPÿuWèşÿÿ¡d	S3ÿÿl  ƒÄƒMüÿjMäÿ¬ä^…ÿthôjWèŞıÿÿƒÄjX_[‹Môd‰    ÉÃU‹ìQŠAƒeü VqW‹}j ‹Ïˆÿ¬ä¡lä‹Ïÿ0j VÿDä‹Ç_^ÉÂ SVW‹=xãjÿÿ5ÿ×…Àul9‹0âtV¡¹‹ ‹pè"  ÿ5ÿÓ¡d	jÿPj Ç m\‰pP¡d	ÿ<  ƒÄjÿÿ5ÿ×…Àu9uªÿ5ÿÓ‹D$_^[Ã¸Òèîo  ìÀ   ŠESVWj ‰Mèˆÿ¬ä‹uƒeü ƒşE˜‰Eìë‹ÆÁàPÿ$å…ÀY‰Eì„í   j…ö_~[‹u‹]ì‹E+Ş‰Eğ3P¡d	ÿ6ÿp  YƒÆÿMğY|uáƒÿdv)Wÿ$å…ÀY‰Eğu#E˜9Eì„™   ÿuìÿåéŠ   …4ÿÿÿ‰Eğƒ} ‹uğ~5‹}‹]ì‹E+ß‰Eÿ4¡d	Vÿ7ÿX  ğƒÄƒÇÆ FÿMuŞ;uğu€& ë€fÿ ‹5åE˜9EìtÿuìÿÖYÿuğèm  Y‹MèPÿuğÿXä…4ÿÿÿ9EğtÿuğÿÖY‹Mô‹Eè_^[d‰    ÉÂ U‹ìƒìhVEüWPÿu¡d	‹ùÿp  @Y@YƒødvPÿ$å‹ğY…öuëNu˜ÿuü¡d	VÿuÿX  €$0 ƒÄƒ tj j‹Ïÿ”äVègl  YPV‹ÏÿLäE˜;ğtVÿåY‹Ç_^ÉÂ U‹ìƒìVEìÿu‹ñhÀVjPÿ(åƒÄEì‹ÎPèJÿÿÿ‹Æ^ÉÂ ¸.Òèám  QSV‹5Tâ3ÛWS¿jWÿÖ+Ãt!HtHtDH3ÀëDj[SSWÿÖ;Ãt3j ÿPâëíjLèÊm  Y‰Eğ;Ã‰]üt	‹Èè$   ë3ÀjjW£ ÿÖ¡ ‹Mô_^[d‰    ÉÃ¸KÒè^m  QQSV‹ñWV‰uìÿhâŠEó3ÿ^WW‹Ë‰}üˆè2  ‰C‰{ŠEó^$WW‹ËÆEüˆè;  ‰CŠEóWW‰{WˆF0‰~4‰~8‰~<W‰~D‰~Hÿ\â‹Mô‰F@‹Æ_^[d‰    ÉÃQSVW‹ù‹_‹3;ót‹Æ‹6PD$P‹Ïèš  ëéÿwè«l  ƒg ƒg Y_^[YÃQSVW‹ù‹_‹3;ót‹Æ‹6PD$P‹Ïè  ëéÿwèsl  ƒg ƒg Y_^[YÃQV‹ñ‹FP‰D$èTl  3ÀY‰F‰F‰F^YÃQV‹ñ‹FP‹D$QP‹Îè·   ÿvè&l  ƒf ƒf Y^YÃV‹ñ‹F‹ P‹H‹‰‹‹P‰Qèık  ÿNY^Ãjè*l  Y‹L$…Éu‹È‰‹L$…Éu‹È‰HÂ jèl  Y‹L$…Éu‹È‰‹L$…Éu‹È‰HÂ V‹t$W‹ùÿvVè_   ‰F‹H‰H…Ét‹T$‹‰‹L$ÿG_^‰‹ÁÂ V‹t$W‹ù;t$t‹Æ‹6P‹H‹‰‹‹P‰QèPk  ÿOYëÛ‹D$_‰0^Â jèrk  Y‹L$…Éu‹È‰‹L$…Éu‹È‰HÂ ‹D$V‹ñW‹H‹‹8P‰‹‹P‰Qèüj  ‹D$ÿNY‰8_^Â ‹D$V‹ñW‹H‹‹8P‰‹‹P‰QèÎj  ‹D$ÿNY‰8_^Â è   é   QŠD$¢P3À£T£X£\YÃhdè|j  YÃ¹Péü  è   é   QŠD$j ¹`¢`ÿ¬äYÃhSdèCj  YÃj¹`ÿ¬äÃ¸iÒèIj  ƒì,S3Û9]„  ‹Eÿ0è»  ƒøÿY„k  VW‹=T4@P‹Eh‘fÿ0Áæÿà‰D>¡T9\Dt7‹8ÇEÌ   ‰MÈMÈQÇEĞ   ‰]Ô‰]ØÇEÜ   ÇEàĞ  ÿ0ÿ à‹=TSSjSÿ\â‰D>¡T9\„³    `SMäˆEäÿ¬ä¡läMäÿ0Sh`ÿDä¡T‰]üÆ‹@;Ãu¡TäPMäèªúÿÿ¡TMäÿtè$ûÿÿhpşMäèŒúÿÿhüMäèúÿÿEÔMäPèo   SSÿ5@EÔÆEüPèûòÿÿƒÄMÔˆ]üjÿ¬äƒMüÿjMäÿ¬ä¡Tjÿÿtÿxã¡Tÿtÿhã¡T_‰\^‹Mô[d‰    ÉÂ U‹ìQƒeü V‹uW‹ùj ‹ÎŠˆÿ¬ä¡lä‹Îÿ0j WÿDä‹Æ_^ÉÂ SVW3ÿ3ö‹T…Ét:¡Xj+Á[™÷û;øs)‹D…Àu¡Täÿt$Pÿ ã…ÀtGƒÆëÀ‹ÇëƒÈÿ_^[Ã¸…Òèh  ƒì ‹TS3ÛV;ËW„  ¡Xj+ÁY™÷ù‹u;ğƒı   ‹EHt?Ht5Ht+Ht!}€   r}ÿ   w¿4ë"jxXéÏ   ¿ˆşë¿ Uë¿€şë¿xş `SMäˆEäÿ¬ä¡läMäÿ0Sh`ÿDä¡T4vÁæÆ‰]ü‹@;Ãu¡TäPMäè¬øÿÿ¡TMäÿtè&ùÿÿWMäè’øÿÿÿuMäèùÿÿEÔMäPèwşÿÿSSÿ5@EÔÆEüPèñÿÿƒÄMÔˆ]üjÿ¬äƒMüÿjMäÿ¬ä3À‹Mô_^[d‰    ÉÂ jÿ¬äÃU‹ìƒìSV3öW95DtVhÜşë‹};şuVhÀşÿu¡d	ÿ¨  ƒÄjXéó   j[Shqjÿlâ…Àu¡d	Vh”şÿuÿ¨  é¾   ‹E‰D£@P¡d	ÿ,  ‹Eÿu%0  £8è^d  YYP¹`ÿuÿXä;ş~M‹u‰}ŠE‹>j MèˆEèÿ¬äWè*d  YPWMèÿXäEè¹PPè  SMèÿ¬äƒÆÿMu»3öhHVVhiVVÿtã;Æ£<uVÿüãPÿuè ÌüÿƒÄ‹Ãë3À_^[ÉÃ¸©Òèe  ƒì@ŠEóS3ÛVWˆEÄ‰]È‰]Ì‰]Ğ‰]ü‰]ì3ö‹T;Ët@¡Xj+Á_™÷ÿ9Eìs.‹D;Ãu¡Tä‰EäEäPMÄÇEèadè  ÿEìƒÆë¶EäMÄP‰]ä‰]èèí  ÿuÈÿà;Ã…¡   9@„•   ŠEóSMÔˆEÔÿ¬ä¾œVèc  YPVMÔÿXäh4ÿMÔÆEüèöÿÿÿüãPMÔè“öÿÿhÿMÔèûõÿÿE´MÔPèëûÿÿSSÿ5@E´ÆEüPèwîÿÿƒÄM´ÆEüjÿ¬äjMÔˆ]üÿ¬äƒMüÿMÄè  ‹Mô_^3À[d‰    ÉÂ jXÃU‹ìƒìÿuè¼ûÿÿƒøÿYuj{ÿä3ÀÉÃ‹8@‰Mä‹M‰Mè‹M‰Mğ‰Mô‹MÇEì   ‰Mø‹M‰MüMäQ‹TÿtÁÿ àÉÃÿt$è]ûÿÿƒøÿYu¡d	j hXÿÿt$ÿ¨  ƒÄjXÃ‹T@‹DÁ…ÀtPÿdâ3ÀÃSV‹ñW‹^‹~;ût‹Ïè   ƒÇëğÿvècc  3ÀY‰F‰F‰F_^[Ãjÿ¬äÃÿt$jÿqè4   Â QV‹ñ‹FP‰D$è(c  3ÀY‰F‰F‰F^YÃÿt$jÿqèV  Â U‹ìƒìSV‹ñWj‹}‹^‹F+ÃY™÷ù‰]ü;Çƒ  ‹N…Ét‹Ãj+Á[™÷û;ø‹Ør‹ß…Éu3Àë‹Eüj+ÁY™÷ùÃ…À‰Eø}3À@ÁàPèØb  ‹^Y‰Eô‰E;]tSÿuèÓ  ƒEYYƒÃëç‹]…ÿv‰}üÿuSèµ  YƒÃÿMüYuí‹M‹^Á‹M;Ë‰Mt‰Eÿuÿuè‡  ƒEƒE9]YYuæ‹F‹^;Ø‰Et‹ËèÄşÿÿƒÃ;]uñÿvèb  ‹Eø‹VY‹Mô@…ÒÁ‰Fu3Àë‹Fj+Â[™÷ûÇ‰N@Á‰Fé  ‹Ã‹]+Ãj™Y÷ù;Çs~‰]Áà‰EôÃ;]üt ‰Eÿuÿuèé  ƒEƒE‹EY;EüYuã‹Fj+ÃY™÷ù+ø‹Ç‹~t‰EÿuWè·  YƒÇÿMYuí‹~;ßtÿu‹ËèÊ  ƒÃëí‹EôFéƒ   …ÿv‹Mü<Áç‹Á‰M+Ç;Á‰Et ë‹EPÿuèc  ƒEƒE‹EY;EüYuâ‹F‰E+Ç;Øtë‹Eƒmƒè‹MP‰Eè[  9]uå;Ø‰Etÿu‹ËèB  ƒÃ;]uî~_^[ÉÂ U‹ìQQSV‹ñW‹}‹N‹F+ÁÁø;Çƒì   ‹V…Òt‹Á+ÂÁø;ør‹Ç…Òu3Éë+ÊÁùÁ…À‰Eø}3ÀÁàPèš`  ‹Ğ‹FY‰Uü;Et…Òt
‹‰
‹H‰JƒÂƒÀëå…ÿ‹Âv‹M‰}…Àt
‹‰‹Y‰XƒÀÿMuê‹F‹ÏÁá9E‰Et"‹Ã+Á+ÂE…Ût
‹‰‹H‰KƒÀƒÃ;Euç‹FP‰EèÙ_  ‹Eø‹VY‹Mü…ÒÁ‰Fu3Àë‹F+ÂÁøÇ‰NÁ‰Féï   ‹U‹Á+ÂÁø;Çsv‹ßÁã;Ñ‰]t"‹Ğ+Ó…Àt‹‰‹Z‰X‹]ƒÂƒÀ;Ñuå‹U‹F‹È+ÊÁù+ù‹Mt‰}…Àt
‹9‰8‹y‰xƒÀÿMuê‹F;Ğt‹9‰:‹y‰zƒÂëí^ëk…ÿvgÁç‹Á‹Ù‰}+Ç;Át…Ût‹8‰;‹x‰{‹}ƒÃƒÀëã‹N‹Á+Ç;Ğt‹Xøƒèƒé;Â‰‹X‰Yuë;Ñt‹E‹‰‹X‰ZƒÂ;Ñuï~_^[ÉÂ ¸ÂÒè·^  Q‹M‰Mğƒeü …Étÿuè8   ‹Môd‰    ÉÃÃ¡läVW‹|$ÿ0‹ñj WÿDä‹G‰F‹G‰F‹Æ_^Â VW‹|$‹ñj Šˆÿ¬ä¡lä‹Îÿ0j WÿDä‹G‰F‹G‰F‹Æ_^Â ¸ÔÒè%^  QQV‹ñè]   …ÀtVÿtâƒ~,>r3Àë9‹E‰Eì‹E‰Eğ‹F(N$ƒeü Uì‹ RPEPè]  Vÿpâÿv@ÿdâjX‹Mô^d‰    ÉÂ VW‹ñ3ÿ9~DuFHPWVhzuWWÿ<åƒÄ‰FD3À9~D_^•ÀÃU‹ìV‹ñVÿtâ‹N(‹;Át;‹P;Uu‹U;Pt‹ ëèPEPN$è]òÿÿ‹M…Ét‹ÿ‰EEPN0è  Vÿpâÿv@ÿdâ^]Â ¸èÒè]  ƒìŠEVW‹ùj j MäˆEäè%ñÿÿƒeì ‰Eèƒeü Wÿtâ‹G(‹0;ğt"‹NF;MuPEğÿuèMäPèM  ‹6;w(uŞWÿpâ‹Eè3ÿ‹0;ğt…ÿuEPÿV‹6Y;uè‹øuëƒMüÿMäèëïÿÿ‹Mô‹Ç_^d‰    ÉÂ ¸üÒèz\  ƒì$‹EƒMğƒeğıƒeğûS‹Ù‰EäèŸşÿÿ…ÀtHVWSÿtâuä}Ğ¥¥‹E¥¥‰Eà‹CKƒeü UĞ‹ RPEPèi  Sÿpâÿs@ÿdâjX_^‹Mô[d‰    ÉÂ U‹ìƒì‹Eƒeì ƒeğ SVW‹ù‰EèWÿtâ‹G‹0;ğt.^EäP‹Ëè.   …Àt‹E;Ct‹6;wëİEVPOè‚ğÿÿWÿpâ_^[ÉÂ ‹D$‹P;töAu‹P;QtöAu‹@;At
öAt3ÀëjXÂ ¸Óè\[  ƒìŠEVW3ö‹ùVVMäˆEäè>ïÿÿ‰Eè‰uìW‰uüÿtâ‹G‹0;ğt*Sÿu^‹Ëèÿÿÿ…ÀtSEğÿuèMäPèK  ‹6;wuØ[Wÿpâ‹Eè3ÿ‹0;ğt…ÿuÿuÿV‹6Y;uè‹øuìƒMüÿMäèëíÿÿ‹Mô‹Ç_^d‰    ÉÂ ¸$Óè²Z  ƒì4ŠEóS3ÛVW‹ñˆEÜ‰]à‰]ä‰]è‰]ü‹=ğçjSSEÀSPÿ×…Àt8EÀ‹ÎPèÿÿÿ…Àuƒ}Ä„	  EÀPÿôçEÀPÿøçjSSEÀSPëÂÿuäMÜÿuàèM  F@MÜPÿuäè  Vÿtâ‹~4;~8t‹‹ÿP‹;Ët‹jÿPƒÇëâ‹F8‹V4N0PRè«  ‹F(‹8;øt‹GMÜ‰EìEìPè  ‹?;~(uçVÿpâ9]àu3ÿë	‹}ä+}àÁÿhÿ   jÿSÿuàWÿé;Ç„	ÿÿÿ;Ã„ÿÿÿv;Çr=€   v!Ç€   ;ÇsPMÜè|   ÿ0‹ÎèEüÿÿéÓşÿÿƒøÿt
éÉşÿÿ‹uÈëj^ƒMüÿMÜè0   ‹Mô‹Æ_^[d‰    ÉÃ‹L$èuşÿÿÂ ÃÃÿt$jÿqèÀ  Â QV‹ñ‹FP‰D$èüX  3ÀY‰F‰F‰F^YÃV‹ñW‹|$‹F…Àt‹N+ÈÁù;Ïw‹Îè  ‹F¸_^Â ÿt$jÿqè2  Â S‹\$VWÿs‹ùSè¦ìÿÿÿt$‹ğ‰s‹F‰0FPèÖ  ‹D$ÿGYY‰0_^[Â S‹\$VWÿs‹ùSèìÿÿÿt$‹ğ‰s‹F‰0FPè»  ‹D$ÿGYY‰0_^[Â U‹ì‹Q‹EV‹u;òtW‹>ƒÆ‰8ƒÀ;òuò_‹Q‰A‹E‰U^]Â SV‹t$Wÿt$‹ù‹_jVèq  ‹G+óÁş_°^[Â U‹ì‹Q‹EV‹u;òtW‹>ƒÆ‰8ƒÀ;òuò_‹Q‰A‹E‰U^]Â ¸9Óè²W  ƒì0ŠEóVj MàˆEàÿ¬ä¾ÈÿVèºU  YPVMàÿXäƒeü EàPMÄÿ¨ä¡¤äh(ğ‰EÄEÄPè…W  ^U‹ìQSV‹ñW‹}‹N‹F+ÁÁø;Çƒ×   ‹V…Òt‹Á+ÂÁø;ør‹Ç…Òu3Éë+ÊÁùÁ…À‰Eü}3ÀÁàPè6W  ‹Ğ‹FY‰U;Et…Òt‹‰
ƒÂƒÀëë…ÿ‹Âv‹Ï…Àt‹]‹‰ƒÀIuï‹F‹ÏÁá9E‰Et‹Ã+Á+ÂE…Ût‹‰ƒÀƒÃ;Euí‹FP‰EèŠV  ‹Eü‹VY‹M…Ò‰Fu3Àë‹F+ÂÁøÇ‰N‰FéÓ   ‹U‹Á+ÂÁø;Çsn‹ßÁã;Ñ‰]‰Eüt#+Ã‹]ü‰E…Ût‹ ‰‹EƒÀƒÃ;Á‰Euè‹]‹F‹È+ÊÁù+ù‹Mt‰}…Àt‹9‰8ƒÀÿMuğ‹F;Ğt	‹9‰:ƒÂëó^ëW…ÿvSÁç‹Á‹Ù‰}+Ç;Át…Ût‹8‰;‹}ƒÃƒÀëé‹N‹Á+Ç;Ğt‹Xüƒèƒé;Â‰uñ;Ğt‹M‹	‰
ƒÂëğ~_^[ÉÂ U‹ìQSV‹ñW‹}‹N‹F+ÁÁø;Çƒ×   ‹V…Òt‹Á+ÂÁø;ør‹Ç…Òu3Éë+ÊÁùÁ…À‰Eü}3ÀÁàPèfU  ‹Ğ‹FY‰U;Et…Òt‹‰
ƒÂƒÀëë…ÿ‹Âv‹Ï…Àt‹]‹‰ƒÀIuï‹F‹ÏÁá9E‰Et‹Ã+Á+ÂE…Ût‹‰ƒÀƒÃ;Euí‹FP‰EèºT  ‹Eü‹VY‹M…Ò‰Fu3Àë‹F+ÂÁøÇ‰N‰FéÓ   ‹U‹Á+ÂÁø;Çsn‹ßÁã;Ñ‰]‰Eüt#+Ã‹]ü‰E…Ût‹ ‰‹EƒÀƒÃ;Á‰Euè‹]‹F‹È+ÊÁù+ù‹Mt‰}…Àt‹9‰8ƒÀÿMuğ‹F;Ğt	‹9‰:ƒÂëó^ëW…ÿvSÁç‹Á‹Ù‰}+Ç;Át…Ût‹8‰;‹}ƒÃƒÀëé‹N‹Á+Ç;Ğt‹Xüƒèƒé;Â‰uñ;Ğt‹M‹	‰
ƒÂëğ~_^[ÉÂ ‹D$…Àt‹L$VW‹ñ‹ø¥¥¥¥‹I_‰H^Ã‹D$…Àt‹L$‹‰‹I‰HÃU‹ì‹EVHH„‘   -  tZƒèt,-ó|  tÿuÿuÿuÿuÿèèé‰   ÿuÿäç‹Më‹M‹9Eu‹E‰ëh…Àtdÿuÿuh  PÿèçëP‹uƒ~ tj j ÿuFPèôÜÿÿƒÄ‹6…öt.ÿuÿuh  VëÈ‹uÿ6ÿuÿìç…öt‹Îè   Vè»R  Y3À^]ÃjƒÁÿ¬äÃU‹ìQVWjèÖR  ‹ğY…ötŠENj ˆÿ¬äë3öÿuƒ& ~è©P  YP‹ÏÿuÿXäEüPVh,{ÿuèt²üÿƒÄ…Àt…ötj‹Ïÿ¬äVè9R  YjXë¡d	ÿuü°´  ÿà   PÿuÿƒÄ3À_^ÉÃÿt$ÿÜç3ÀÃè   é
   ¹pé·  hÃ|èÓQ  YÃ¹péË  U‹ìƒì(VEÿuƒì‹Ì‰eüPÿuÿ°äÿuMØÿuèT   MØè  …ÀuP¡d	häÿÿuÿ¨  ƒÄj^ë¡d	ÿuğ°´  ÿØ   PÿuÿƒÄ3öMØèO  ‹Æ^ÉÃ¸UÓè\Q  QV‹ñ‰uğÿu ƒeü EPèA   ‹Eƒf ‰F‹E‹ÎÆEü‰F Çìêè°  ƒMüÿjMÿ¬ä‹Mô‹Æ^d‰    ÉÂ ¸lÓèúP  QS‹]VWŠ‹ùj ‰}ğw‹Îˆÿ¬ä¡lä‹Îÿ0j SÿDä‹Eƒeü …À‰GtP¡d	ÿ,  Y‹MôÇàê‹Ç_^[d‰    ÉÂ ‹AÃV‹ñèo   öD$tVèpP  Y‹Æ^Â U‹ìƒì,j Eÿƒì‹Ì‰eøPhœÿ°äj j MÔèæşÿÿ‹E¹p‰EEÔPEPè  …ÀtMÔè>  MÔè   3ÀÉÃV‹ñƒ~ Çìêtf‹FPÿxâ‹Îè
Ùÿÿ^ÃVW‹|$‹ñ;÷tWè   ‹G‹Î‰F‹G ‰F è`   ‹Æ_^Â ¡läSV‹t$W‹ùÿ0FOj PÿDä^w;ót(‹…ÀtP¡d	ÿh  Y‹…À‰tP¡d	ÿ,  Y‹Ç_^[Â U‹ìƒì V‹ñƒ~ tf‹FPÿxâ‹F…Àu9F t(ÿv Ph  EàjPÿ(åƒÄEàPÿ|â·À‰F^ÉÃU‹ìQƒ=˜ VW‹ñ¿€  uyèáÿÿ…À£œ„¤   h  hï€‹Èèfòÿÿ…À„‹   ‹œWhpèMòÿÿ…Àtv‹œh€  hğè4òÿÿ…Àt]‹œjh$‚èòÿÿ…ÀtGÇ˜   ‹‹ÎÿP‰Eüj EüVP¹pèE  ƒøu‹‹ÎÿP‹œPj Wè   jX_^ÉÃ3ÀëøU‹ìSVW‹ùèˆğÿÿ…ÀtOÿu‹5 èÿuÿuÿwHÿÖ…Àu2‹PâjÿÓÿuÿuÿuÿwHÿÖ…Àuj
ÿÓÿuÿuÿuÿwHÿÖ…ÀtjXë3À_^[]Â ƒ=œ t‹ÿP‹œPj h€  èvÿÿÿjXÃ¸€Óè»M  ƒì,V3öVEóƒì‹Ì‰eìPhœÿ°äVVMÈè-üÿÿ‹E¹p‰uü‹@‰EEÈPEPèV	  …ÀtVVÿuÜEÌPèX×ÿÿƒÄƒMüÿMÈè8ıÿÿ‹MôjXd‰    ^ÉÃ¸”Óè:M  ƒì,V3öVEóƒì‹Ì‰eìPhœÿ°äVVMÈè¬ûÿÿ‹E¹p‰uü‹@‰EìEÈPEìPèÕ  …ÀtÿuèÿuäÿuìVÿXçƒMüÿMÈè¸üÿÿ‹MôjXd‰    ^ÉÃU‹ì‹Ej ¹p‹@‰EEPè÷  …Àtÿuj ÿìèjX]ÃjXÃU‹ìƒì‹Eƒxt3ÀÉÃVW¹pèk   ‹ø‹w;wt‹ÇEè€  ‰EğEäPèÿÿÿYƒÆëà_3À^ÉÃU‹ìQŠEÿV‹ñ€f ˆŠEÿˆFè  FPÿhâ‹Æ^ÉÃV‹ñFPÿLâ‹Îèm   ^ÃU‹ìQQSVW‹ñjè!L  Y3É;ÁtŠUÿ‰Hˆ‰H‰H‹Øë3Û~Wÿtâ‹N‹;Á‰EøtƒÀ‹ËPè   Møèÿ   ‹Eø;FuåWÿpâ_‹Ã^[ÉÃU‹ìQV‹ñ‹FP‹EüQP‹ÎèY   ÿvèlK  ƒf ƒf Y3öMüÿŒäÿ¤u‹5 ƒ%  Müÿä…ötVè0K  Y^ÉÃÿt$jÿqè  Â U‹ìQV‹ñ‹Mƒ~ t8‹F;u19Eu,ÿp‹Îè'  ‹F‹ ‰H‹Fƒf ‰ ‹F‰@‹F‹ë%;Mt W‹ùMè   EüWP‹ÎèI   ‹M;Muâ_‹E^‰ÉÂ ‹V‹5 ‹B;Æt
‹;Öt‹Âëö‹B‹;Pu‰‹@ëò‹9Bt‰^Ã¸©ÓèrJ  ƒìS‰MğVW‹}Mè¬ÿÿÿ‹7¡ _;ğ‰}ì‰]èu‹3ë‹;Èt‹;Ğt‹Êëö‹qA‰Mì‰EèMäÿŒä‹Eìƒeü ;Çtc‹‰A‹‰;u‰Fë‹H‹Uè‰N‹H‰1‹‰
‹‰A‹]ğ‹K9yu‰Aë‹O99u‰ë‰A‹O‰}ì‰H‹W4‹H4‰P4‰O4‹Çé…   ‹H‹Uğ‰N‹J9yu‰që‹O99u‰1ë‰q‹R‰Uè9:u$‹ 9u‹O‰
ë‹‹Ş;Ñt‹Ú‹ëö‹Mè‰‹Mğ‹Q9zu%‹ 9u‹O‰Jë‹^‹ş;Ùt‹û‹_ëõ‰z‹]ğj_9x4…  ‹C;p„ü   9~4…ó   ‹F;0u4‹@ƒx4 u‰x4‹F‹Ëƒ`4 ÿvè¦  ‹F‹@‹9y4uF‹H9y4u>ë0‹ ƒx4 u‰x4‹F‹Ëƒ`4 ÿvè·  ‹F‹ ‹H9y4uS‹9y4uLƒ`4 ‹vétÿÿÿ‹H9y4u‹P‰y4ƒ`4 ‹Ëè~  ‹F‹@‹N‹I4‰H4‹N‰y4‹@‹Ë‰x4ÿvè  ë<‹9y4u‹HP‰y4ƒ`4 ‹Ëèú  ‹F‹ ‹N‹I4‰H4‹N‰y4‹ ‹Ë‰x4ÿvè  ‰~4ƒMüÿMäÿä‹uìNèã÷ÿÿVèëG  ‹EÿKY_‹M^‰‹Mô[d‰    ÉÂ SVW‹|$;= ‹Ù‹÷t%ÿv‹Ëèãÿÿÿ‹6Oèü  Wè¡G  ;5 Y‹şuÛ_^[Â U‹ìQQSVW‹ùj8è¹G  Y‹ğ3ÛMø‰^ÇF4   ‰uüÿŒä9 u‰5 ‰¡ ‰]ü‰Xÿ¤Møÿä9]üt	ÿuüè-G  Y‹5 j8èYG  ‰p‰X4‰G‰_‰ ‹GY_^‰@[ÉÃU‹ìQSV‹ñW‹}‹N‹F+ÁÁø;Çƒ×   ‹V…Òt‹Á+ÂÁø;ør‹Ç…Òu3Éë+ÊÁùÁ…À‰Eü}3ÀÁàPèëF  ‹Ğ‹FY‰U;Et…Òt‹‰
ƒÂƒÀëë…ÿ‹Âv‹Ï…Àt‹]‹‰ƒÀIuï‹F‹ÏÁá9E‰Et‹Ã+Á+ÂE…Ût‹‰ƒÀƒÃ;Euí‹FP‰Eè?F  ‹Eü‹VY‹M…Ò‰Fu3Àë‹F+ÂÁøÇ‰N‰FéÓ   ‹U‹Á+ÂÁø;Çsn‹ßÁã;Ñ‰]‰Eüt#+Ã‹]ü‰E…Ût‹ ‰‹EƒÀƒÃ;Á‰Euè‹]‹F‹È+ÊÁù+ù‹Mt‰}…Àt‹9‰8ƒÀÿMuğ‹F;Ğt	‹9‰:ƒÂëó^ëW…ÿvSÁç‹Á‹Ù‰}+Ç;Át…Ût‹8‰;‹}ƒÃƒÀëé‹N‹Á+Ç;Ğt‹Xüƒèƒé;Â‰uñ;Ğt‹M‹	‰
ƒÂëğ~_^[ÉÂ ‹T$V‹B‹0‰r‹0;5 t‰V‹r‰p‹I^;Qu‰Aë‹J;u‰ë‰A‰‰BÂ ‹T$V‹‹p‰2‹p;5 t‰V‹r‰p‹I^;Qu‰Aë‹J;Qu‰Aë‰‰P‰BÂ ƒÁé•ôÿÿ¸´Óè§D  QQSV‹ñW‰eğ‰uì~Wÿtâÿuƒeü E‹ÎPèã   ‹F‹U;Ğt#‹M…Ét	ƒÂRèkôÿÿÿuE‹ÎPèÚùÿÿj^ë3öWÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EìƒÀPÿpâj j èED  ¸ÀÓèD  QQSV‹ñW‰eğ‰uì~Wÿtâÿuƒeü E‹ÎPèQ   ‹v‹E;Æt‹Mj…É^tƒÀPèÖóÿÿë3öWÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EìƒÀPÿpâj j èÁC  U‹ìQVW‹}‹ñWè)   ‹v‰E;Æt‹;H|Eë‰uüEü‹‹E_^‰ÉÂ ‹A‹ ‹H;ÊtV‹t$‹69q}‹Ië‹Á‹	;Êuî^Â ¸ÌÓè*C  ƒìSV‹ñW‰eğ‰uè~Wÿtâÿuƒeü Eì‹ÎPèeÿÿÿ‹F‹Mì;Èt$ƒ} tƒÁQ‹Mèëòÿÿ‹MìÿuƒÁèİòÿÿjëÿu‹Îè=   ÿu‹ÈèÅòÿÿj^Wÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EèƒÀPÿpâj j è±B  ¸èÓèB  ƒì\S3ÛVS‹ñƒìEó‹Ì‰eìPhœÿ°äSSMÀèğğÿÿ‹MP‰]ü‹	‰M˜Mœè@   E˜‹ÎPEäPÆEüè»   Mœˆ]üèòÿÿƒMüÿMÀèüñÿÿ‹Eä‹Mô^ƒÀd‰    [ÉÂ ¸ÔèøA  ƒìŠEV‹ñWj Mà‰uğˆEàÿ¬ä¿œWèú?  YPWMàÿXäƒeü Eàj P‹Îè±ğÿÿjMàÆEüÿ¬ä‹Eƒf ‹H‰N‹@ ‹Î‰F Çìêèòÿÿ‹Mô‹Æ_^d‰    ÉÂ U‹ìQSVW‹ù‹ ²‹G‹Ø‹p;ñt‹U‹Ş‹;VœÂ„Òt‹6ëç‹vëâ€ t
ÿuESVë2‹Ë„Ò‰Müt;u
ÿuESVëMüè‰  ‹Mü‹E‹Q;}PSVEP‹Ïè   ‹‹E‰Æ@ë	‹E€` ‰_^[ÉÂ U‹ìSVW‹Ùj8èó@  ‹u‹øÿuƒg4 ‰w¡ ‰¡ ‰GGPèW  ƒÄÿC;st%‹E; u‹E‹ ;F|‰~‹C;pu‰xë‰>‹C;ğu‰x‹Cëê;0u‰8‹C‹÷;x„­   ‹Fƒx4 …    ‹P‹
;ÁuV‹Jƒy4 ujZ‰P4‰Q4‹F‹@ƒ`4 ‹F‹pëg;pu
‹ğ‹ËVè¿úÿÿ‹F‹ËÇ@4   ‹F‹@ƒ`4 ‹Fÿpèâúÿÿë5ƒy4 t­;0u
‹ğ‹ËVèÌúÿÿ‹F‹ËÇ@4   ‹F‹@ƒ`4 ‹Fÿpègúÿÿ‹C;p…Sÿÿÿ‹C‹@Ç@4   ‹E‰8_^[]Â ‹Vƒx4 u‹P9Bu‹@‰^Ã‹‹5 ;Öt‹Â‹P;Öu÷ëå‹@‹;uÜ‰ëó¸Ôè??  Q‹E‰Eğƒeü …Àt‹M‹ƒÁQH‰èıÿÿ‹Môd‰    ÉÃU‹ì‹EHHt.ÿu-  ÿutÿuÿuÿèè]Ãÿuÿuÿuè.   ƒÄ]ÃV‹u‹F$…ÀtPÿğè…öt‹Îè%  Vè¨>  Y3À^]Ã¸9Ôè¦>  ìğ   SVW‹}3ÛMäŠSˆEäÿ¬ä¡läMäÿ0SWÿDä‹M‰]üƒùuhh Mäè·Ïÿÿét  ¸ €  ;Ètù€  …  ‹u‹V;W…  ;È¸X t¸@ PMäèwÏÿÿ‹FHH„	  H„º   HH…N  ƒÇjh¨Wè£=  ƒÄ…ÀtFjPWè=  ƒÄ…À…   h( Mäè"Ïÿÿ…ÿÿÿj(PFPÿ4ê‹=€â;Ãt"SSTÿÿÿh€   QP…ÿÿÿPShéı  ÿ×;ÃuˆTÿÿÿëˆ]Ó…TÿÿÿMäPèÉÎÿÿSS…Tÿÿÿh€   PƒÆjÿVShéı  ÿ×ë-h MäèÎÿÿSS…Tÿÿÿh€   PƒÆjÿVShéı  ÿ€â;ÃuˆTÿÿÿëˆ]Ó…TÿÿÿPé¤şÿÿh MäèVÎÿÿÿvMäèÖÎÿÿ·FPMäèÉÎÿÿEÔMäPè.ÔÿÿSSÿuEÔÆEüPè½ÆÿÿƒÄMÔˆ]üjÿ¬äƒMüÿjMäÿ¬ä‹Mô_^3À[d‰    ÉÃjÿ¬äÃU‹ìƒì$SVWj(èª<  ‹ØY…ÛtŠEj ‹Ëˆÿ¬äë3Ûÿuè„:  YP‹ËÿuÿXä‹Eƒc$ {¾¨‰CEü¥¥PS¥h£ÿu¥è9œüÿƒÄ…Àt…Û„Œ   j‹Ëÿ¬äSèú;  Yëyj^9uuyj EÜ_Wj Pè.:  3ÉƒÄ3À9M‰}Ü‰uàt‹u}è¥¥¥¥ë¡¤	;Ærgu9¨	t]jXPEÜPÿuüÿôè…Àu!PÿüãPÿuèñ¡üÿƒÄÿuüÿÜçjXë"‰C$¡d	ÿuü°´  ÿà   PÿuÿƒÄ3À_^[ÉÃ¡d	Qh| ÿuÿ¨  ë²ÿt$ÿÜç3ÀÃè   é   hô  ¹¸èå  Ãh“èù:  YÃ¹¸éæ  Vjè1;  ‹ğY…öt%ÿt$‹Îÿt$è[   ÿt$ÇøêÿPåY‰Fë3öV¹¸èñ  …Àu0…öt‹Îèi   Vè©:  Y¡d	j h° ÿt$ÿ¨  ƒÄjX^Ã3À^Ã‹D$V‹ñ…À‰FtP¡d	ÿ,  Yƒ|$ Çüêtÿt$ÿPåYë3À‰F‹Æ^Â V‹ñ‹FÇøê…ÀtPÿåY‹Îè   ^ÃV‹ñ‹FÇüê…ÀtPÿåY‹v…öt¡d	Vÿh  Y^Ã¸]Ôèû9  ƒìHSW‹ù3Û9_„‹  Vj E¬SPè8  ŠEó‹wƒÄMÜÇE°   ˆEÜSÿ¬äVèá7  YPVMÜÿXäÿwMÜ‰]üè÷Êÿÿ¡	‹w;ÃuSè¤Ãıÿ£	MìQM¬QhüVÿĞ‹ğVÿŒé;óthà MÜè¶ÊÿÿVMÜè8Ëÿÿé²   hxMMÜè›ÊÿÿŠEóSMÌˆEÌÿ¬ä¾œVèP7  YPVMÌÿXä‹EìÆEü‹ğ;Ãt2ƒx‹Huóƒxuífƒ9uçÿqÿ„éPMÌè@Êÿÿ‹Eì‹@‰EìëÊ‹EĞ;Ãu¡TäPMÜè Êÿÿ;ót¡	;ÃujèËÂıÿ£	VÿĞjMÌˆ]üÿ¬äEÌMÜPèæÏÿÿ‹SSEÌWPÆEüètÂÿÿƒÄMÌˆ]üjÿ¬äƒMüÿjMÜÿ¬ä^‹Mô_[d‰    ÉÃVjèt8  ‹ğY…öt%ÿt$‹Îÿt$èıÿÿÿt$Ç ëÿPåY‰Fë3öV¹¸è4  …Àu0…öt‹Îè)   Vèì7  Y¡d	j h ÿt$ÿ¨  ƒÄjX^Ã3À^ÃV‹ñ‹FÇ ë…ÀtPÿåY‹Îè…ıÿÿ^Ã¸yÔè¬7  ìX  SV‹ñ3Û9^„J  ŠEóW‹~SMàˆEàÿ¬äWè¥5  YPWMàÿXäÿvMà‰]üè»ÈÿÿÿvfÇEĞ ‰]Ôf‰]Òÿœéƒøÿ‰EÔu*h`Ôÿvè5  Y…ÀYthà Màè}Èÿÿh,é†   ¡	;Ãujè"Áıÿ£	jM j Qœûÿÿh  QMĞjQÿĞ‹øWÿŒé;ûthà Màè(ÈÿÿWMàèªÈÿÿë8hxMMàèÈÿÿÿv…œûÿÿPè‹4  Y…ÀYt	…œûÿÿPëhœMàèåÇÿÿEÀMàPèÕÍÿÿ‹vSSEÀVPÆEüècÀÿÿƒÄMÀˆ]üjÿ¬äƒMüÿjMàÿ¬ä_‹Mô^[d‰    ÉÃV‹ñÿt$ƒ& Nè8   ‹Æ^Â ¸Ôè6  V‹ñF4PÿtâƒL$ÿNè@   ‹L$^d‰    ÉÃU‹ìQEÿV‹ñPèM   F0Pÿhâ3ÀPÿuPPÿ„â‰FH‹Æ^ÉÂ V‹ñÿvHÿhãƒfH F0PÿLâƒ~, t	‹Îè4   ëñ^Ã‹Á‹L$Š	ˆ3É‰H‰H‰H‰H‰H‰H‰H‰H ‰H$‰H(‰H,Â ƒAÿI,‹At;Aué   ÃU‹ìƒìS‹ÙVW‹CH‰Kÿ0è(5  3ÀY9C,u+{uğ‰Eğ‰Eô‰Eø‰Eü¥¥¥¥{uğ¥¥ÿs$¥¥èø4  Yë#‹C{uğ‰Eü‹‰MğÁ   ‰Mô‹‰Mø¥¥¥¥_^[ÉÃSV‹ñW^4Sÿtâ3ÿ9>u&VWVh|œWWÿ<åƒÄ;Çt	Pÿhãë‰>9>tD$NPè   …Àuj_Sÿpâ‹Ç_^[Â ¸¤Ôès4  QV‹ñW~0W‰}ğÿtâƒeü j jÿvHÿ<â…Àtÿu‹Îè)   3öëj^Wÿpâ‹Mô‹Æ_^d‰    ÉÂ ÿ1ÿpâÃV‹ñƒ~, t7‹N‹V;Êt-A;Â‰Fu…Ét‹D$‹ ‰‹Îè3   ë*…Ét&‹D$‹ ‰ë‹Îè   ‹F…ÀH‰Nt‹L$‹	‰ÿF,^Â U‹ìƒìSVW‹Ùh   èÍ3  ƒ{, ‹ğY‰uüuI‹ËÇC(   èÒ   ‹C${‰p‹C$ƒÀ‰Eø‹‰MìÁ   Æ   ‰Mğ‰uôuì¥¥¥¥{uìé   ‹K(‹S$‹C LŠü;Ás'ƒÀ‰uô‰C {‰0‹C ‰Eøuì‹‰MìÁ   ‰MğëV+C‹ËÁø@‹ø?Pèd   ¸{‰Eø‰1‹‰UìÂ   ‰Uğ‹Suì‰Uô¥¥¥¥‹‰Mø‰Eì   ‰Eğ‹Eü‰Eô{uì¥¥¥¥_^[ÉÃV‹ñ‹F(Áày3ÀPèÎ2  Y‰F$^ÃU‹ìQS‹]‹ÃVÁà…ÀW‹ñ}3ÀPè«2  ‹ø‹ÃÁèY‹N‡‰Eü‹Ğ‹F ƒÀ;Èt‹ƒÁ‰ƒÂ;Èuò‹]ÿv$è;2  ‹EüY‰~$‰^(_^[ÉÂ ‹L$è   Â U‹ìQSVW‹ùƒeü Eü_h`ê  P‹ËèR   …Àu"‹Mü…Ét‹ÿ‹Mü…É‹ñtÑè¼÷ÿÿVèÛ1  YëÃw4Vÿtâ‹Ëè´   ‹Ø…Ûtƒ' Vÿpâ…Ût_^3À[ÉÃ¸¸Ôè°1  ƒìS‹ÙÿuÿsHÿxã…Àt=  t`jë^C0VP‰Eÿtâƒeü ƒ{, u¡d	h4ÿPYj^ë#‹E…ÀtWs}ä¥¥¥¥‹Mì_‹	‰‹ËèÛûÿÿ3öÿuÿpâ‹Æ^ëjX‹Mô[d‰    ÉÂ V‹ñW~0Wÿtâ‹v,Wÿpâ…ö”À_^¶ÀÃU‹ìQ‹	V…Ét‹jÿjè1  ‹ğY…öt!ÿuEÿƒì‹Ì‰ePÿuÿ°ä‹Îè   ë3À£	‹E£	3À^ÉÃ¸ÍÔèœ0  V‹ñÿuƒeü EPè…ßÿÿjh¶ÇëÿlâƒMüÿjMÿ¬ä‹Mô‹Æ^d‰    ÉÂ 3ÀÃV‹ñè   öD$tVè00  Y‹Æ^Â V‹ñj h¶Çëÿlâ‹Îè)¹ÿÿ^Ã‹	…Ét‹jÿƒ%	 3ÀÃ¸êÔèô/  ƒì ‹	S3ÛV;ËW„  ‹E+Ãt.Ht$HtƒètH…ì   ¿˜ë¿ë¿ˆë¿|ë¿tEÔPèÕ   ¾@A‰]üVèµ-  YPVMÔÿLäWè£-  YPWMÔÿLäŠESMäˆEäÿdä¡	MäQÆEüÿ5	‹@PEÔPè4¹ÿÿƒÄ…ÀuB‹Eè;Ãu¡ˆäj
SPÿDå‹ğƒÄ÷ŞöjMäˆ]ü÷ŞÿdäƒMüÿjMÔÿ¬ä‹ÆëjMäˆ]üÿdäƒMüÿjMÔÿ¬ä3À‹Mô_^[d‰    ÉÂ U‹ìQŠAƒeü VqW‹}j ‹Ïˆÿ¬ä¡lä‹Ïÿ0j VÿDä‹Ç_^ÉÂ jXÃè   é   ¹%	ÿ%€ähL èJ.  YÃ¹%	ÿ%|äè   é   ¹$	ÿ%xähx è.  YÃ¹$	ÿ%täè   é
   ¹0	éû  h£ èó-  YÃ¹0	é  U‹ìƒìVWèj  …ÀuP¡d	h¤ÿuÿ¨  ƒÄjXé«   h¤  èù-  ‹ğ3ÿ;÷YtBÿuEÿƒì‹Ì‰eôPÿuÿ°äÿuEşÿuÿu ÿuƒì‹Ì‰ePÿuÿ„ä‹Îè\   ë3À‰Eø‹‹ÈÿR‹ğEøWPE¹0	P‰uèû  ‹(	VWh€  èùŞÿÿ¡d	‰}øV¸´  ÿØ   PÿuÿƒÄ3À_^ÉÃ¸-Õè-  ƒìSV‹ñW‰uğÿu8E(ÇEü   PèüÛÿÿŠE~3Û‹ÏSÆEüˆÿdä¡\ä‹Ïÿ0ESPÿ`äŠE;~,ˆ‰_‰_‰_‹E ƒNDÿƒNHÿ‰F<‹E$h 	ÆEü‰F@‰   Çëÿä‰F‹E;Ã~o‹M‰E‰M ‹E ‹ ;ÃtT¾ƒé+tIIuÆE$@ë@ˆ]$8t9ÿu$U;ƒì‹Ì‰eRPÿ°äMÜèT   P‹ÏÆEüè
  jMÜÆEüÿ¬äƒE ÿMušjMˆ]üÿdäƒMüÿjM(ÿ¬ä‹Mô‹Æ_^d‰    [ÉÂ4 ¸AÕèâ+  V‹ñŠEƒeü j ˆÿ¬ä¡lä‹Îÿ0Ej PÿDäŠEƒMüÿjMˆFÿ¬ä‹Mô‹Æ^d‰    ÉÂ ‹AÃV‹ñè   öD$tVèl+  Y‹Æ^Â ¸`Õèi+  QV‹ñ‰uğÇëN,ÇEü   èç  €eü jNÿdäƒMüÿ‹ÎèB´ÿÿ‹Mô^d‰    ÉÃjÿ¬äÃèˆ  …ÀuP¡d	h¤ÿt$ÿ¨  ƒÄjXÃÿt$‹(	j h€  èÜÿÿ3ÀÃSV‹ñƒËÿW9^H…   9^D…•   ‹F 3ÿ;Çu¡ˆäWh   BjWjjPÿ´â;Ã‰FHuÿüã‰†   ëZWWjWÿ\â;Ã‰FDuÿüãÿvH‰†   ÿhãë.‹(	PhŞ¦è%Ìÿÿ…Àu ÿvD‰¾   ‹=hãÿ×ÿvH‰^Dÿ×‰^H3ÀëjX_^[Ã¸tÕè*  ƒìV‹ñ‹ÿP‰EğEğj P¹0	è8  ‹FDƒøÿujXë%‰uìÇEèëƒeü MèQ‹(	PhŞ¦èBÌÿÿ3À‹Mô^d‰    ÉÃÇ(ëÃöD$V‹ñÇ(ëtVè—)  Y‹Æ^Â V‹ñjèÀ)  …ÀYtÇ (ë‹N‰HÇ ë^Ã3À^ÃV‹ñ‹N…Étè   ‹N…Ét‹jÿ^ÃV‹ñW‹=hã‹FHƒøÿtPÿ×‹vDƒşÿtVÿ×_^ÃV‹ñèlÿÿÿöD$tVè)  Y‹Æ^Â V‹ñ3É†Œ  QPhX	ÿv@‹VD‰FLÿv<‰  ‰”  ‰˜  h@  PÿvH‰–œ  ÿˆâ…ÀtjX^Ãÿüã‰†   3À^ÃU‹ìQQ‹EV¾0	‹@‹Î‰EüEPEüPèZ  …Àtv‹Mè¬ıÿÿ…Àu<‹Mhè7  ‹M‹ÿP‰EøEøj P‹Îè™  ‹Mèÿÿÿ‹M…Ét6‹jÿë.‹Mè)ÿÿÿ…Àu"‹MhØèï  ÿuü‹(	j h€  èÊÙÿÿjX^ÉÃU‹ìQ‹E¹0	‹@‰EüEPEüPè»  …Àt‹MèÃıÿÿ…Àt‹M…Ét‹jÿjXÉÃU‹ìE¹0	Pÿuè  …Àt%‹Mj j ‹ÿP‹Mèşÿÿ…Àu‹MhØèV  jX]ÃjXÃƒ=(	 u\è—¹ÿÿ…À£(	tDh€  hú¥‹ÈèäÊÿÿ…Àt/‹(	h€  h¦èËÊÿÿ…Àt‹(	jh§èµÊÿÿ…Àu
ƒ%(	 3ÀÃjXÃ‹D$ƒxt3ÀÃV¾0	W‹Îè*  ‹Î‹øèŒ  ‹w;wt‹èËüÿÿƒÆëï_3À^Ã¸¢Õèà&  ìH  SVW‹ùEäj P‡Œ  PwLÿwHÿŒâ…À„É  ƒeè E´P‹Ïèß÷ÿÿ‹ØŠƒeü j MÔˆEÔÿ¬ä¡läMÔÿ0j SÿDäjM´ÆEüÿ¬ä‹MäD9L;ğƒ`  ‹F…À„  ¨…ü   T0LL;Ñ‡ì   3Û¬şÿÿSSh  QÑèPFPShéı  ÿ€â;Ã„ª    œ¬şÿÿ…¬şÿÿP‹Ïè3  …À„   ‹FHt9Ht-Ht!HtHt	ÇEìŒë+ÇEì€ë"ÇEìtëÇEìhëÇEì`ëÇEìX…¬şÿÿMÄ‰EğEìPjèµÿÿ9]ÌÆEüt‹EÈ;Ãu¡TäPMÔèĞ¶ÿÿÿEèjMÄÆEüÿ¬ä‹;Ãt‹MäğDL;ğ‚ñşÿÿ3Û9]è~JEÄMÔPè¼ÿÿÿu‹EÄÆEüÿuWPè¯ÿÿƒÄMÄ‹ğÆEüjÿ¬äƒMüÿjMÔÿ¬ä‹Æë%ƒMüÿjMÔÿ¬ä3Àëÿüã3É=å  •Á‹Á‹Mô_^[d‰    ÉÂ SV‹ñW‹N0…Ét‹F4j+ÁY™÷ù…ÀujXë_3ÿ3Û‹N0…ÉtR‹F4j+ÁY™÷ù;øsC‹F0Ã‹@…Àu¡TäjPÿt$¡d	ÿÔ  ƒÄ…ÀuGƒÃëº‹N0¿3Ò8T”Â‹Âë3À_^[Â ¸×Õè9$  ìP  SV‹ñ3Û‹F;Ã„¬  ŠEWSMÔˆEÔÿ¬äÿuè1"  YPMÔÿuÿXä‹†   ‰]ü;ÃtuPèÇˆüÿ;ÃY‰EtgSS¤şÿÿhÿ   QjÿPShéı  ÿ€â;Ãt<¿”ˆœ¤şÿÿWèÕ!  YPWMÔÿLä…¤şÿÿPè½!  YP…¤şÿÿPMÔÿLäÿuÿåYE¤‹ÎPè¨ôÿÿ‹øŠSMÄÆEüˆEÄÿ¬ä¡läMÄÿ0SWÿDäjM¤ÆEüÿ¬äŠESMäˆEäÿ¬ä¿¤WèE!  YPWMäÿXä‹‹ÎÆEüÿPPMäèà´ÿÿ‹EØ_;Ãu¡TäPMäè?´ÿÿ‹Eè;Ãu¡TäPMÄè*´ÿÿE´MÄPèºÿÿ‹vSSE´VPÆEüè¨¬ÿÿƒÄM´ÆEüj^Vÿ¬äVMäÆEüÿ¬äVMÄˆ]üÿ¬äƒMüÿVMÔÿ¬ä‹Mô^[d‰    ÉÂ SV‹ñW‹^‹~;ût‹Ïè*÷ÿÿƒÇëğÿvè5"  3ÀY‰F‰F‰F_^[Ãÿt$jÿqè?  Â U‹ìQŠEÿV‹ñ€f ˆŠEÿˆFè_  FPÿhâ‹Æ^ÉÃV‹ñFPÿLâ‹ÎèŒ   ^ÃU‹ìQQSVW‹ñjèı!  Y3É;ÁtŠUÿ‰Hˆ‰H‰H‹Øë3Û~Wÿtâ‹N‹;Á‰EøtƒÀ‹ËPè   Møèâ  ‹Eø;FuåWÿpâ_‹Ã^[ÉÃV‹ñW~Wÿtâ‹Îè£  Wÿpâ_^ÃU‹ìQV‹ñ‹FP‹EüQP‹Îèé  ÿvè)!  ƒf ƒf Y3öMüÿŒäÿ`	u‹5\	ƒ%\	 Müÿä…ötVèí   Y^ÉÃÿt$jÿqèÌ  Â U‹ìƒìSV‹ñWj‹}‹^‹F+ÃY™÷ù‰]ü;Çƒ  ‹N…Ét‹Ãj+Á[™÷û;ø‹Ør‹ß…Éu3Àë‹Eüj+ÁY™÷ùÃ…À‰Eü}3À€ÁàPè¨   ‹^Y‰Eô‰E;]tSÿuè¡  ƒEYYƒÃëç‹]…ÿv‰}øÿuSèƒ  YƒÃÿMøYuí‹M‹^¿‹M;Ë‰Mt‰EÿuÿuèU  ƒEƒE9]YYuæ‹F‹^;Ø‰Et‹ËèÏôÿÿƒÃ;]uñÿvè×  ‹Eü‹VY‹Mô€…Ò‰Fu3Àë‹Fj+Â[™÷ûÇ‰N€‰FéO  ‹M‹Ã+Áj™[÷û;Çƒ™   ¿‰MÁã;Müt#‰Eøÿuÿuøèµ  ƒEƒEø‹EY;EüYuã‹M‹Fj+ÁY™÷ù+ø‹Ç‹~t‰EÿuWè€  YƒÇÿMYuí‹F‹};ø‰E„È   ¡lä‹Ïÿ0j ÿuÿDä‹EƒÇ;}Š@ˆGüuÛé   …ÿ†™   ‹Eü¿Áã‹ø‰E+û;øtWÿuè  ƒEƒÇ;}üYYué‹M‹~‰}+û;Ït+¡läƒm‹Mƒïÿ0j WÿDä‹MŠG;}ˆAuØ‹M‹ù;È‰Et%¡lä‹Ïÿ0j ÿuÿDä‹EƒÇ;}Š@ˆGüuÛ^_^[ÉÂ U‹ìQV‹ñ‹MWƒ~ t[‹F;uT9EuOS‹X¡\	‹û;Øtÿw‹ÎèB  ‹?Sè
  ¡\	Y;ø‹ßuâ‹N[‰A‹Fƒf ‰ ‹F‰@‹F‹‹E‰ë%;Mt‹ùMè0   EüWP‹ÎèZ   ‹Mëà‹E‰_^ÉÂ Q‹AP‹D$RPèWÿÿÿYÃ‹V‹5\	‹B;Æt
‹;Öt‹Âëö‹B‹;Pu‰‹@ëò‹9Bt‰^Ã¸íÕèk  ƒìS‰MğVW‹}Mè¬ÿÿÿ‹7¡\	_;ğ‰}ì‰]èu‹3ë‹;Èt‹;Ğt‹Êëö‹qA‰Mì‰EèMäÿŒä‹Eìƒeü ;Çtc‹‰A‹‰;u‰Fë‹H‹Uè‰N‹H‰1‹‰
‹‰A‹]ğ‹K9yu‰Aë‹O99u‰ë‰A‹O‰}ì‰H‹W‹H‰P‰O‹Çé…   ‹H‹Uğ‰N‹J9yu‰që‹O99u‰1ë‰q‹R‰Uè9:u$‹\	9u‹O‰
ë‹‹Ş;Ñt‹Ú‹ëö‹Mè‰‹Mğ‹Q9zu%‹\	9u‹O‰Jë‹^‹ş;Ùt‹û‹_ëõ‰z‹]ğj_9x…  ‹C;p„ü   9~…ó   ‹F;0u4‹@ƒx u‰x‹F‹Ëƒ` ÿvè•  ‹F‹@‹9yuF‹H9yu>ë0‹ ƒx u‰x‹F‹Ëƒ` ÿvè¦  ‹F‹ ‹H9yuS‹9yuLƒ` ‹vétÿÿÿ‹H9yu‹P‰yƒ` ‹Ëèm  ‹F‹@‹N‹I‰H‹N‰y‹@‹Ë‰xÿvè  ë<‹9yu‹HP‰yƒ` ‹Ëèé  ‹F‹ ‹N‹I‰H‹N‰y‹ ‹Ë‰xÿvè
  ‰~ƒMüÿMäÿäÿuìèí  ‹EÿKY_‹M^‰‹Mô[d‰    ÉÂ SVW‹|$;=\	‹Ù‹÷tÿv‹Ëèãÿÿÿ‹6Wè«  ;5\	Y‹şuã_^[Â U‹ìQQSVW‹ùjèÃ  Y‹ğ3ÛMø‰^ÇF   ‰uüÿŒä9\	u‰5\	‰¡\	‰]ü‰Xÿ`	Møÿä9]üt	ÿuüè7  Y‹5\	jèc  ‰p‰X‰G‰_‰ ‹GY_^‰@[ÉÃU‹ìQSV‹ñW‹}‹N‹F+ÁÁø;Çƒ×   ‹V…Òt‹Á+ÂÁø;ør‹Ç…Òu3Éë+ÊÁùÁ…À‰Eü}3ÀÁàPèõ  ‹Ğ‹FY‰U;Et…Òt‹‰
ƒÂƒÀëë…ÿ‹Âv‹Ï…Àt‹]‹‰ƒÀIuï‹F‹ÏÁá9E‰Et‹Ã+Á+ÂE…Ût‹‰ƒÀƒÃ;Euí‹FP‰EèI  ‹Eü‹VY‹M…Ò‰Fu3Àë‹F+ÂÁøÇ‰N‰FéÓ   ‹U‹Á+ÂÁø;Çsn‹ßÁã;Ñ‰]‰Eüt#+Ã‹]ü‰E…Ût‹ ‰‹EƒÀƒÃ;Á‰Euè‹]‹F‹È+ÊÁù+ù‹Mt‰}…Àt‹9‰8ƒÀÿMuğ‹F;Ğt	‹9‰:ƒÂëó^ëW…ÿvSÁç‹Á‹Ù‰}+Ç;Át…Ût‹8‰;‹}ƒÃƒÀëé‹N‹Á+Ç;Ğt‹Xüƒèƒé;Â‰uñ;Ğt‹M‹	‰
ƒÂëğ~_^[ÉÂ ‹T$V‹B‹0‰r‹0;5\	t‰V‹r‰p‹I^;Qu‰Aë‹J;u‰ë‰A‰‰BÂ ‹T$V‹‹p‰2‹p;5\	t‰V‹r‰p‹I^;Qu‰Aë‹J;Qu‰Aë‰‰P‰BÂ ¸Öè¹  Q‹M‰Mğƒeü …Étÿuè   ‹Môd‰    ÉÃVW‹|$‹ñj Šˆÿ¬ä¡lä‹Îÿ0j WÿDäŠG_ˆF‹Æ^Â ¸ÖèY  ƒìSV‹ñW‰eğ‰uè~Wÿtâÿuƒeü Eì‹ÎPèü  ‹N‹Eì;Át‹M…Ét‹P‰‹Mj‹	‰Hëÿu‹Îè§  ‹Mj‹	‰^Wÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EèƒÀPÿpâj j èï  ¸Öè¿  QQSV‹ñW‰eğ‰uì~Wÿtâÿuƒeü E‹ÎPèc  ‹F‹M;Èt‹E…Àt‹Q‰EQP‹Îèÿøÿÿj^ë3öWÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EìƒÀPÿpâj j èc  ¸(Öè3  QQSV‹ñW‰eğ‰uì~Wÿtâÿuƒeü E‹ÎPè×   ‹M;Nt‹Ej…À^t	‹I‰ë3öWÿpâ‹Mô‹Æ_^d‰    [ÉÂ ‹EìƒÀPÿpâj j èå  U‹ìQSV‹ñW3Û~Wÿtâ‹F‹;È‰Müt2‹A…Àt
‹U‹@D;tMüèÚ÷ÿÿ‹Mü;Nußë‹Ej…À[t‹I‰Wÿpâ_‹Ã^[ÉÂ U‹ìƒì‹Eƒeü ‹ ‰EøEøPEğPèD   ‹EğƒÀÉÂ U‹ìQVW‹}‹ñWè  ‹v‰E;Æt‹;H|Eë‰uüEü‹‹E_^‰ÉÂ U‹ìQSVW‹ù‹\	²‹G‹Ø‹p;ñt‹U‹Ş‹;VœÂ„Òt‹6ëç‹vëâ€ t
ÿuESVë2‹Ë„Ò‰Müt;u
ÿuESVëMüè¶  ‹Mü‹E‹Q;}PSVEP‹Ïè   ‹‹E‰Æ@ë	‹E€` ‰_^[ÉÂ U‹ìSVW‹Ùjèx  ‹u‹øÿuƒg ‰w¡\	‰¡\	‰GGPè„  ƒÄÿC;st%‹E;\	u‹E‹ ;F|‰~‹C;pu‰xë‰>‹C;ğu‰x‹Cëê;0u‰8‹C‹÷;x„­   ‹Fƒx …    ‹P‹
;ÁuV‹Jƒy ujZ‰P‰Q‹F‹@ƒ` ‹F‹pëg;pu
‹ğ‹ËVè:ûÿÿ‹F‹ËÇ@   ‹F‹@ƒ` ‹Fÿpè]ûÿÿë5ƒy t­;0u
‹ğ‹ËVèGûÿÿ‹F‹ËÇ@   ‹F‹@ƒ` ‹Fÿpèâúÿÿ‹C;p…Sÿÿÿ‹C‹@Ç@   ‹E‰8_^[]Â ‹A‹\	‹H;ÊtV‹t$‹69q}‹Ië‹Á‹	;Êuî^Â ‹Vƒx u‹P9Bu‹@‰^Ã‹‹5\	;Öt‹Â‹P;Öu÷ëå‹@‹;uÜ‰ëó‹D$…Àt‹L$‹‰‹I‰HÃU‹ìÿu}  ÿuuÿuÿuÿuè   ƒÄ]Ãÿuÿuÿèè]Ã¸EÖèM  ƒì SV‹u3ÛSMäŠˆEäÿ¬ä¡läMäÿ0SVÿDä‹E3öƒø‰]üw7t.+Ãt%HHtHHtHH…’   ¸,ëD¸ ë=¸ë6j^ëx¸ôë*ƒè	t HtHtƒèua¸àë¸Ôë¸¼ë¸¬;ÃtCPMäèÿ¢ÿÿÿuMäè£ÿÿEÔMäPèä¨ÿÿSSÿuEÔÆEüPès›ÿÿƒÄMÔˆ]üjÿ¬äƒMüÿjMäÿ¬ä‹Mô‹Æ^[d‰    ÉÃU‹ìQVjèn  ‹ğY…ötŠEj ‹Îˆÿ¬äë3öÿuèH  YP‹ÎÿuÿXäEüPVh*¼ÿuèqüÿƒÄ…Àt…ötj‹Îÿ¬äVèØ  YjXë¡d	ÿuü°´  ÿà   PÿuÿƒÄ3À^ÉÃÿt$ÿÜç3ÀÃÌÌÌÌÌÌÌÌÌÌÌÌÌQV‹t$W3ÿV‰|$è   ƒÄ;Ç£d	u_3À^YÃ‹T$L$Q‹L$RQh@VÿPƒÄ;Çu_3À^YÃ‹L$‰d	‹Q;×t$‹_‰h	‹Q^‹R‰l	‹I‹Q‰p	YÃ‰=h	‰=l	‰=p	_^YÃ‹L$‹A…Àt8Ïº£ütÇDÇA    3ÀÃÿ% äÿ%äÿ%äÿ%äÿ%äÿ%äÿ%äÿ% äÿ%üãÿ%øãÿ%ôãÿ%ğãÿ%ìãÿ%èãÿ%äãÿ%àãÿ%Üãÿ%Øãÿ%Ôãÿ%Ğãÿ%Ìãÿ%Èãÿ%Äãÿ%Àãÿ%¼ãÿ%¸ãÿ%´ãÿ%°ãÿ%¬ãÿ%¨ãÿ%¤ãÿ% ãÿ%œãÿ%˜ãÿ%”ãÿ%ãÿ%Œãÿ%ˆãÿ%„ãÿ%€ãÿ%|ãÿ%xãÿ%tãÿ%pãÿ%lãÿ%hãÿ%dãÿ%`ãÿ%\ãÿ%Xãÿ%Tãÿ%Pãÿ%Lãÿ%Hãÿ%Dãÿ%@ãÿ%<ãÿ%8ãÿ%4ãÿ%0ãÿ%,ãÿ%(ãÿ%$ãÿ% ãÿ%ãÿ%ãÿ%ãÿ%ãÿ%ãÿ%ãÿ%ãÿ% ãÿ%üâÿ%øâÿ%ôâÿ%ğâÿ%ìâÿ%èâÿ%äâÿ%àâÿ%Üâÿ%Øâÿ%Ôâÿ%Ğâÿ%Ìâÿ%Èâÿ%Äâÿ%Àâÿ%¼âÿ%¸âÿ%´âÿ%°âÿ%¬âÿ%¨âÿ%¤âÿ% âÿ%œâÿ%˜âÿ%”âÿ%âÿ%áÿ%”áÿ%˜áÿ%œáÿ% áÿ%¤áÿ%¨áÿ%¬áÿ%°áÿ%´áÿ%¸áÿ%¼áÿ%Àáÿ%Äáÿ%Èáÿ%Ìáÿ%Ğáÿ%Ôáÿ%Øáÿ%Üáÿ%àáÿ%äáÿ%èáÿ%ìáÿ%ğáÿ%ôáÿ%øáÿ%üáÿ% âÿ%âÿ%âÿ%âÿ%âÿ%âÿ%âÿ%âÿ% âÿ%$âÿ%(âÿ%,âÿ%0âÿ%4âÿ%8âÿ%<âÿ%@âÿ%Dâÿ%Hâÿ%Lâÿ%Pâÿ%Tâÿ%Xâÿ%\âÿ%`âÿ%dâÿ%hâÿ%lâÿ%pâÿ%tâÿ%xâÿ%|âÿ%€âÿ%„âÿ%ˆâÿ%Œâÿ%páÿ%àÿ%àÿ%àÿ%àÿ%àÿ%háÿ%láÿ% àÿ%dáÿ%`áÿ%\áÿ%Xáÿ%Táÿ%Páÿ%Láÿ%Háÿ%Dáÿ%@áÿ%<áÿ%8áÿ%4áÿ%0áÿ%,áÿ%(áÿ%$áÿ% áÿ%áÿ%áÿ%áÿ%áÿ%áÿ%áÿ%áÿ% áÿ%üàÿ%øàÿ%ôàÿ%ğàÿ%ìàÿ%èàÿ%äàÿ%ààÿ%Üàÿ%Øàÿ%Ôàÿ%Ğàÿ%Ìàÿ%Èàÿ%Äàÿ%Ààÿ%¼àÿ%¸àÿ%´àÿ%°àÿ%¬àÿ%¨àÿ%¤àÿ% àÿ%œàÿ%˜àÿ%”àÿ%àÿ%Œàÿ%ˆàÿ%„àÿ%€àÿ%|àÿ%xàÿ%tàÿ%pàÿ%làÿ%hàÿ%dàÿ%`àÿ%\àÿ%Xàÿ%Tàÿ%Pàÿ%Làÿ%Hàÿ%Dàÿ%@àÿ%<àÿ%8àÿ%4àÿ%0àÿ%,àÿ%(àÿ%$àÿ% àÿ%àÿ%àÿ%èèÿ%äèÿ%àèÿ%Üèÿ%Øèÿ%Ôèÿ%Ğèÿ%Ìèÿ%\èÿ%Xèÿ%Tèÿ%Pèÿ%Lèÿ%Hèÿ%Dèÿ%@èÿ%üçÿ%Pçÿ%Tçÿ%tçÿ%xçÿ%|çÿ%€çÿ%„çÿ%ˆçÿ%Œçÿ%çÿ%”çÿ%˜çÿ%œçÿ% çÿ%¤çÿ%¨çÿ%¬çÿ%°çÿ%´çÿ%¸çÿ%¼çÿ%Àçÿ%Äçÿ%Èçÿ%Ìçÿ%Ğçÿ%Ôçÿ%Øçÿ%Üçÿ%àçÿ%`èÿ%dèÿ%hèÿ%lèÿ%pèÿ%tèÿ%xèÿ%|èÿ%€èÿ%„èÿ%ˆèÿ%Œèÿ%èÿ%”èÿ%˜èÿ%œèÿ% èÿ%¤èÿ%¨èÿ%¬èÿ%°èÿ%´èÿ%¸èÿ%¼èÿ%Àèÿ%éÿ%pçÿ%lçÿ%hçÿ%dçÿ%`çÿ%\çÿ%@éÿ%éÿ%Déÿ%éÿ%éÿ% éÿ%üèÿ%øèÿ%èÿ%<éÿ%8éÿ%4éÿ%0éÿ%,éÿ%(éÿ%$éÿ% éÿ%éÿ%éÿ%Èèÿ%Äèÿ%<èÿ%8èÿ%4èÿ%0èÿ%,èÿ%(èÿ%$èÿ% èÿ%èÿ%èÿ%èÿ%èÿ%èÿ%èÿ% èÿ%éÿ%øçÿ%ôçÿ%ğçÿ%ìçÿ%èçÿ%äçÿ%Xçÿ%ìèÿ%ğèÿ%ôèÿ%¬æÿ%¨æÿ% æÿ%¤æÿ%°æÿ%ˆáÿ%„áÿ%€áÿ%|áÿ%xáÿ%æÿ%Œæÿ%ˆæÿ%”æÿ%€æÿ%|æÿ%˜æÿ%„æÿ%ìåÿ%èåÿ%äåÿ%àåÿ%Üåÿ%Øåÿ%Ôåÿ%Ğåÿ%Ìåÿ%Èåÿ%Äåÿ%Àåÿ%¼åÿ%¸åÿ%´åÿ%°åÿ%¬åÿ%¨åÿ%¤åÿ% åÿ%œåÿ%˜åÿ%”åÿ%åÿ%Œåÿ%ˆåÿ%„åÿ%€åÿ%|åÿ%xåÿ%tåÿ%påÿ%låÿ%æÿ%ğåÿ%ôåÿ%æÿ%æÿ%håÿ%æÿ% æÿ%üåÿ%øåÿ%˜êÿ%”êÿ%êÿ%Œêÿ%ˆêÿ%„êÿ%€êÿ%|êÿ%xêÿ%têÿ%pêÿ%lêÿ%hêÿ%dêÿ%œêÿ%`êÿ%péÿ%<äÿ%8äÿ%4äÿ%0äÿ%,äÿ%(äÿ%„éÿ%ˆéÿ%Œéÿ%¬éÿ%”éÿ%˜éÿ%œéÿ% éÿ%¤éÿ%¨éÿ%€éÿ%°éÿ%éÿ%(êÿ%,êÿ%0êÿ%4êÿ%8êÿ%<êÿ%@êÿ%Dêÿ%Hêÿ%Xêÿ%Lêÿ%Pêÿ%Têÿ%0æÿ%Xæÿ%\æÿ%`æÿ%dæÿ%hæÿ%læÿ%Tæÿ%Læÿ%Pæÿ%æÿ%Hæÿ%Dæÿ%@æÿ%<æÿ%8æÿ%4æÿ%,æÿ%(æÿ%$æÿ% æÿ%æÿ%äæÿ%üæÿ%èæÿ%ìæÿ%ğæÿ%ôæÿ%øæÿ%xéÿ%\éÿ%déÿ%héÿ%`éÿ%àéÿ%ğéÿ%êÿ%êÿ% êÿ%êÿ%êÿ%êÿ%êÿ%êÿ% êÿ%üéÿ%øéÿ%ôéÿ%ìéÿ%èéÿ%äéÿ%tæÿ%(çÿ%$çÿ% çÿ%çÿ%çÿ%Dçÿ%çÿ%çÿ%çÿ%çÿ%çÿ%,çÿ%0çÿ%4çÿ%8çÿ%<çÿ%@çÿ%Hçÿ%Téÿ%Léÿ%Péÿ%Øéÿ%¼éÿ%¸éÿ%Äéÿ%Èéÿ%Ìéÿ%Ğéÿ%Ôéÿ%Àéÿ%Üæÿ%Øæÿ%Ôæÿ%Ğæÿ%Ìæÿ%Èæÿ%Äæÿ%Àæÿ%¼æÿ%¸æÿ%,åÌÌÌÌQ=   L$ré   -   …=   sì+È‹Ä…‹á‹‹@PÃÌÿ%(åÿ%$åÿ% åÿ%åÿ%åÿ%åÿ%åÿ%åÿ%åÌÌÌÌÌÌÌÌÌÌSV‹D$Àu‹L$‹D$3Ò÷ñ‹Ø‹D$÷ñ‹ÓëA‹È‹\$‹T$‹D$ÑéÑÛÑêÑØÉuô÷ó‹ğ÷d$‹È‹D$÷æÑr;T$wr;D$vN3Ò‹Æ^[Â ÌÌÌÌÌÌÌÌ‹D$‹L$È‹L$u	‹D$÷áÂ S÷á‹Ø‹D$÷d$Ø‹D$÷áÓ[Â ÌÌÌÌÌÌÌÌÌÌÌÌ€ù@s€ù s­ĞÓêÃ‹Â3Ò€áÓèÃ3À3ÒÃÌ€ù@s€ù s¥ÂÓàÃ‹Ğ3À€áÓâÃ3À3ÒÃÌÿ%üäÿ%øäÿ%ôäÿ%ğäÿ%ìäÌÌÿ%èäÿ%ääÿ%àäÿ%Üäÿ%Øäÿ%Ôäÿ%Ğäÿ%Ìäÿ%Èäÿ%`åÿ%Àäÿ%¼äƒ=@
ÿuÿt$ÿLåYÃh<
h@
ÿt$èÜ  ƒÄÃÿt$èËÿÿÿ÷ØÀY÷ØHÃÿ%¸äÿ%ÄäÌÌjÿPd¡    P‹D$d‰%    ‰l$l$PÃÌÿ%0åÿ%4åÿ%8åÿ%<åÿ%@å‹ÁÇ ¼ëÂ V‹ñèm  öD$tVè”ÿÿÿY‹Æ^Â ‹ÁÂ ÿ%Då‹D$…Àu9t	~.ÿt	‹\åƒø‹	‰4
u?h€   ÿ$å…ÀY£@
u3Àëfƒ  ¡@
h,@h @£<
èö   ÿt	YYë=…Àu9¡@
…Àt0‹<
Vqü;ğr‹…ÉtÿÑ¡@
ƒîëêPÿåƒ%@
 Y^jXÂ U‹ìS‹]V‹uW‹}…öu	ƒ=t	 ë&ƒştƒşu"¡8
…Àt	WVSÿĞ…ÀtWVSèÿÿÿ…Àu3ÀëNWVSè_   ƒş‰Eu…Àu7WPSèñşÿÿ…ötƒşu&WVSèàşÿÿ…Àu!Eƒ} t¡8
…ÀtWVSÿĞ‰E‹E_^[]Â ÿ%Håÿ%Tåÿ%Xåƒ|$uƒ=8
 u
ÿt$ÿäjXÂ ÌÌÿ%€äÿ%|äÿ%xäÿ%täÿ%päÿ%¬äÿ%häÿ%däÿ%`äÿ%Xäÿ%Päÿ%Läÿ%Häÿ%Däÿ%”äÿ%˜äÿ%œäÿ% äÿ%¨äÿ%°äÿ%äÿ%Œäÿ%„äÿ%äÿ%PåÌÌ‹Mğéq…ÿÿ‹MğƒÁé†ÿÿ‹MğƒÁ$é³ÿÿ¸ìéLıÿÿ‹MğƒÁÿ%pä¸@ìé6ıÿÿÌÌMÜÿ%hä¸hìé!ıÿÿÌÿuğèıÿÿYÃ¸Èìéıÿÿ‹Mğé{‰ÿÿ‹MğƒÁÿ%pä¸ğìéîüÿÿÌÌ‹Mğé[‰ÿÿ‹MğƒÁÿ%pä¸ íéÎüÿÿÌÌMÿ%hä¸Píé¹üÿÿÌMÔÿ%päMäÿ%pä¸xíéœüÿÿ‹Mèÿ%pä¸°íé‰üÿÿÌÿuğèzüÿÿYÃ¸Øíétüÿÿ‹Mìéq„ÿÿ‹MìƒÁé†ÿÿ¸ îéWüÿÿÌÌÌMäéy•ÿÿMÔÿ%pä¸0îé9üÿÿÌMäé]•ÿÿMÔÿ%pä¸`îéüÿÿÌMÄéÕ˜ÿÿMÔé9•ÿÿM´ÿ%pä¸îéùûÿÿÌÿuÿuğèaÿÿYYÃ¸ÈîéàûÿÿMìé³¢ÿÿ¸ğîéÎûÿÿÌÌMäé!ÿÿ¸ïéºûÿÿÌÌMĞéŠ¢ÿÿ¸@ïé¦ûÿÿÌÌMäéÁÿÿ¸hïé’ûÿÿÌÌMÜéu¢ÿÿ¸ïé~ûÿÿÌÌMàÿ%pä¸8ğéiûÿÿÌMÿ%pä‹Mğén„ÿÿ¸`ğéMûÿÿÌ‹MğƒÁÿ%pä¸ğé6ûÿÿÌÌMÈé«ÿÿ¸¸ğé"ûÿÿÌÌMÈé«ÿÿ¸àğéûÿÿÌÌMäÿ%ä¸ñéùúÿÿÌ¸0ñéîúÿÿÌÌ¸ˆñéâúÿÿÌÌ¸àñéÖúÿÿÌÌMÀé¸ªÿÿM˜é¶ÿÿ¸8òéºúÿÿÌÌMàÿ%pä‹Mğé¾ƒÿÿ¸hòéúÿÿÌÿuÿuğèœÿÿYYÃ¸ òé„úÿÿMäé©“ÿÿMÔÿ%pä¸ÈòéiúÿÿÌMÜé“ÿÿMÌé…“ÿÿMÌÿ%pä¸øòéEúÿÿÌMàéi“ÿÿMÀÿ%pä¸0óé)úÿÿÌ‹M˜ƒÁébÄÿÿ¸`óéúÿÿÌÌÌMğéîÅÿÿ¸ˆóéşùÿÿÌÌMéÚÅÿÿ¸°óéêùÿÿÌÌMÿ%pä¸ØóéÕùÿÿÌMÔÿ%päMäÿ%hä¸ ôé¸ùÿÿM(ÿ%päMÿ%hä‹Mğéµ‚ÿÿ‹MğƒÁÿ%hä‹MğƒÁ,é)×ÿÿMÜéaÎÿÿ¸0ôéuùÿÿÌMÿ%pä¸€ôéaùÿÿÌ‹Mğéo‚ÿÿ‹MğƒÁÿ%hä¸¨ôéBùÿÿÌÌMèé~Ïÿÿ¸Øôé.ùÿÿÌÌM´ÿ%päMÔéH’ÿÿMÄé@’ÿÿMÄÿ%pä¸ õé ùÿÿMÔÿ%päM¤ÿ%päMÄé’ÿÿMäé’ÿÿM´ÿ%pä¸HõéËøÿÿÌÌÌMäÿ%ä¸˜õéµøÿÿÌÿuÿuğèšÿÿYYÃ¸Àõéœøÿÿ¸èõé’øÿÿÌÌ¸@öé†øÿÿÌÌ¸˜öézøÿÿÌÌMäé‘ÿÿMÔÿ%pä¸ğöé]øÿÿ                                                                                                                                                                                                                                                                                                                                                                                                                                                 Š    0 > H â Â ® ˜ € f H 6 $  ş î Ö ¾ ¨  v ` H 2  
 ú ê Ø È ® – € n V > $  ş ê Ø Æ ¶ œ  | d D & 
 î Ò º ª   ’ z f T @ .   ô Ú Ä ¬  v ` <      î Ö Â ¸ ˜ z \ @ $  ì Î ¶   b x î     Ü" Ä" ®" " "     R n Œ  ° º Æ Ö ò  . H V r ‚ ” ª È Ü ğ  . P ` |  ¤ Â Ü ğ   8 X p †  ¸ Ê Ú è ø   2 L d | ” œ º Ê Ú ò ş  2 J b v ˆ  ² Ê : $ 
 ò
 ê
 Ü
 Î
 À
 ¬
 
 ˆ
 d
 J
 2
 
 ø	 æ	 Ò	 ¾	 ¬	 ”	 €	 p	 Z	 H	 2	 	 
	 ö â Î ¾ ® œ  z d P 8    ö à Â ® ’ € h L > 0    ş ğ â Ğ À ª ˜ „ n \ P @ 0     ò Ş Ğ Â ° ” ‚ f P .    ğ à Ê ¶ ¨ ˜ † t ^ L < 0   ì9 È à ğ ş  ¸     Ú( Ê( ¬( ”( ~( j(     ¸6 `6 6 °5 T5 ü4 ²4 V4 4 ¼3 7 "3 
3 ò2 Ò2 ²2 €9 $9 
9 ğ8 ^7 ´7 Ø7 ü7 8 68 l3 8     Ì1 Â1 ¸1 Ü1 ¤1 š1 1 †1 z1 p1 f1 \1 H1 >1 41 *1 1 1 1 ö0 ì0 â0 Ø0 Î0 Æ0 ¼0 ²0 ¨0 œ0 ’0 ğ1 ü1 2 "2 42 P2 f2 t2 : ~2 –2 ¢2 ®1     †& $& & ü% ê% Ô% À% ¨% ˜% ˆ% z% h% V% F% 6% (% % ş$ ä$ Ğ$ Â$ °$ ˜$ †$ t$ f$ R$ 8$  $ $ ø# è# Ú# Æ# D& R& Æ& ¶& ¦& `& t& 2& ˜&     	  €¸  €¹  €B €C €¤  €  €º  €£  €¢  €·  €#  €¥  €  €  €M  €  €è  €Å  €  €  €  €    `,     l# V# ¤# *# # # ># ˆ#     T" f" D" 2" t"     f0 F0 (0 0 æ/ Â/ ª/ / p/ N/     ü) (* <* Z* r* Œ* *     `- F- .- - p- Ş, Ä, ¨, ’, €, ‚- - ¶- Î- ê- . ò, .     2 J Â! F 6 &  ú ì ` p ‚ š ¦ ´ À Ô æ ü  $ 6 D T j z Š ¦ º Ì Ú ì ş   ( 8 ¬! œ! „! t! `! L!  !  ! ô  â  Î  ¸  ¬    –  z  \  H  .        ö è Ü Ê ¶ ¨ š D P b n € ’ œ ² È Ø ä ô   * @ R d r ‚   ² Æ Ò ì Ú † z f T D 2    Ô! è! " ş ì Ü Æ ® 0! ~ Ş È ¸ ¦ ˜ „ p Z F 2 " d ˜     L. `. 8.     È* 
+ Ş* ø*     R(     ª*     8  €  €  €p  €s  €7  €	  €  €o  €4  €3  €  €t  €     . . ./ º. Ò. ğ. / / ~.     (+ >, 0, , <+ , ô+ ä+ Ö+ È+ ´+ ¤+ ’+ „+ N+ b+ v+     ) ) ,) <) N) b) p) €) ’) ¶) Æ) Ú) ¤)     6( ( ú' ê' Ú' ¸' ¢' ' x' Z' B' ,' ' ' è&  (                     ¸‘J       j        R     ÿÿÿÿ·n Ån    )XÔÎX!~~X¯”ÔÎş–a^X%£!£Ê§¥=¥~¥ÔÎÔÎù¤         À      Fù     À      F@;òûğã„ˆ ª >Vø »ÊWÚÏ™t  ¯×—b                      À      F      À      F        À      FğëıÎ€        ÿÿÿÿ        Àë               Øë            €àë     “   (ì                    ÿÿÿÿ8Ñ    @Ñ   KÑ “   `ì                    ÿÿÿÿ`Ñ “   ˆì    ì            ÿÿÿÿ        xÑÿÿÿÿ                 ¸ì                ÿY “   èì                    ÿÿÿÿŒÑ “   í                    ÿÿÿÿ Ñ    ¨Ñ “   @í                    ÿÿÿÿÀÑ    ÈÑ “   pí                    ÿÿÿÿàÑ “   ˜í                    ÿÿÿÿôÑ    ıÑÿÿÿÿıÑ “   Ğí                    ÿÿÿÿÒ “   øí                    ÿÿÿÿ$Ò “    î                    ÿÿÿÿ8Ò    @Ò “   Pî                    ÿÿÿÿXÒ    `Ò “   €î                    ÿÿÿÿtÒ    |Ò “   °î                    ÿÿÿÿÒ    ˜Ò    Ò “   èî                    ÿÿÿÿ´Ò “   ï                    ÿÿÿÿÌÒ “   8ï                    ÿÿÿÿàÒ “   `ï                    ÿÿÿÿôÒ “   ˆï                    ÿÿÿÿÓ “   °ï                    ÿÿÿÿÓ    pÿ    ÿÿÿÿ       ìÎ        ˆÿ    ÿÿÿÿ       úĞ        ¨ÿ    ÿÿÿÿ        Ñ       øïØï¸ï    Ñ    ğ “   Xğ                    ÿÿÿÿ0Ó “   €ğ                    ÿÿÿÿDÓ    MÓ “   °ğ                    ÿÿÿÿ`Ó “   Øğ                    ÿÿÿÿxÓ “    ñ                    ÿÿÿÿŒÓ “   (ñ                    ÿÿÿÿ Ó “   Pñ   `ñ            ÿÿÿÿ    ÿÿÿÿ                  xñ                Š “   ¨ñ   ¸ñ            ÿÿÿÿ    ÿÿÿÿ                  Ğñ                ‹ “    ò   ò            ÿÿÿÿ    ÿÿÿÿ                  (ò                Œ “   Xò                    ÿÿÿÿØÓ    àÓ “   ˆò                    ÿÿÿÿôÓ    ıÓÿÿÿÿıÓ “   Àò                    ÿÿÿÿÔ “   èò                    ÿÿÿÿ(Ô    0Ô “   ó                    ÿÿÿÿDÔ    LÔ    TÔ “   Pó                    ÿÿÿÿhÔ    pÔ “   €ó                    ÿÿÿÿ„Ô “   ¨ó                    ÿÿÿÿœÔ “   Ğó                    ÿÿÿÿ°Ô “   øó                    ÿÿÿÿÄÔ “    ô                    ÿÿÿÿØÔ    áÔ “   Pô                    ÿÿÿÿôÔ    ıÔ   Õ   Õ   Õ   %Õ “    ô                    ÿÿÿÿ8Õ “   Èô                    ÿÿÿÿLÕ    TÕ “   øô                    ÿÿÿÿlÕ “    õ                    ÿÿÿÿ€Õ    ‰Õÿÿÿÿ‰Õ   ‘Õ   ™Õ “   hõ                    ÿÿÿÿ¬Õ    µÕ   ¾Õ    ¾Õ   ÆÕ   ÎÕ “   ¸õ                    ÿÿÿÿäÕ “   àõ                    ÿÿÿÿøÕ “   ö   ö            ÿÿÿÿ    ÿÿÿÿ                  0ö                Õ· “   `ö   pö            ÿÿÿÿ    ÿÿÿÿ                  ˆö                a¸ “   ¸ö   Èö            ÿÿÿÿ    ÿÿÿÿ                  àö                ß¸ “   ÷                    ÿÿÿÿ4Ö    <Ö¤ú         à á ù            à d          &" Pç ´ÿ         „"  æ Œú         ú" xá ÿ         ¼# |æ |ş         Ú& hå t         J( `ê „         `( pé <ı         ô( (ä ”         ü( €é <         ä) (ê ,ÿ         î) æ øÿ         * äæ Œ         º* xé p         + \é ô         R, àé ˆÿ         r, tæ           ,. ç `         r. Lé Ì         @/ ¸é Ìÿ         „0 ¸æ Ìı         Z2 ¸ä Xı         à9 Dä                     Š    0 > H â Â ® ˜ € f H 6 $  ş î Ö ¾ ¨  v ` H 2  
 ú ê Ø È ® – € n V > $  ş ê Ø Æ ¶ œ  | d D & 
 î Ò º ª   ’ z f T @ .   ô Ú Ä ¬  v ` <      î Ö Â ¸ ˜ z \ @ $  ì Î ¶   b x î     Ü" Ä" ®" " "     R n Œ  ° º Æ Ö ò  . H V r ‚ ” ª È Ü ğ  . P ` |  ¤ Â Ü ğ   8 X p †  ¸ Ê Ú è ø   2 L d | ” œ º Ê Ú ò ş  2 J b v ˆ  ² Ê : $ 
 ò
 ê
 Ü
 Î
 À
 ¬
 
 ˆ
 d
 J
 2
 
 ø	 æ	 Ò	 ¾	 ¬	 ”	 €	 p	 Z	 H	 2	 	 
	 ö â Î ¾ ® œ  z d P 8    ö à Â ® ’ € h L > 0    ş ğ â Ğ À ª ˜ „ n \ P @ 0     ò Ş Ğ Â ° ” ‚ f P .    ğ à Ê ¶ ¨ ˜ † t ^ L < 0   ì9 È à ğ ş  ¸     Ú( Ê( ¬( ”( ~( j(     ¸6 `6 6 °5 T5 ü4 ²4 V4 4 ¼3 7 "3 
3 ò2 Ò2 ²2 €9 $9 
9 ğ8 ^7 ´7 Ø7 ü7 8 68 l3 8     Ì1 Â1 ¸1 Ü1 ¤1 š1 1 †1 z1 p1 f1 \1 H1 >1 41 *1 1 1 1 ö0 ì0 â0 Ø0 Î0 Æ0 ¼0 ²0 ¨0 œ0 ’0 ğ1 ü1 2 "2 42 P2 f2 t2 : ~2 –2 ¢2 ®1     †& $& & ü% ê% Ô% À% ¨% ˜% ˆ% z% h% V% F% 6% (% % ş$ ä$ Ğ$ Â$ °$ ˜$ †$ t$ f$ R$ 8$  $ $ ø# è# Ú# Æ# D& R& Æ& ¶& ¦& `& t& 2& ˜&     	  €¸  €¹  €B €C €¤  €  €º  €£  €¢  €·  €#  €¥  €  €  €M  €  €è  €Å  €  €  €  €    `,     l# V# ¤# *# # # ># ˆ#     T" f" D" 2" t"     f0 F0 (0 0 æ/ Â/ ª/ / p/ N/     ü) (* <* Z* r* Œ* *     `- F- .- - p- Ş, Ä, ¨, ’, €, ‚- - ¶- Î- ê- . ò, .     2 J Â! F 6 &  ú ì ` p ‚ š ¦ ´ À Ô æ ü  $ 6 D T j z Š ¦ º Ì Ú ì ş   ( 8 ¬! œ! „! t! `! L!  !  ! ô  â  Î  ¸  ¬    –  z  \  H  .        ö è Ü Ê ¶ ¨ š D P b n € ’ œ ² È Ø ä ô   * @ R d r ‚   ² Æ Ò ì Ú † z f T D 2    Ô! è! " ş ì Ü Æ ® 0! ~ Ş È ¸ ¦ ˜ „ p Z F 2 " d ˜     L. `. 8.     È* 
+ Ş* ø*     R(     ª*     8  €  €  €p  €s  €7  €	  €  €o  €4  €3  €  €t  €     . . ./ º. Ò. ğ. / / ~.     (+ >, 0, , <+ , ô+ ä+ Ö+ È+ ´+ ¤+ ’+ „+ N+ b+ v+     ) ) ,) <) N) b) p) €) ’) ¶) Æ) Ú) ¤)     6( ( ú' ê' Ú' ¸' ¢' ' x' Z' B' ,' ' ' è&  (     éGetVersionExA ,InterlockedIncrement  (SetLastError  ø FreeLibrary  GetProcAddress  RLoadLibraryA  ÈGetSystemTime \LocalFree qGetLastError  TLoadLibraryExW  uMultiByteToWideChar ó FormatMessageA  ô FormatMessageW  
GlobalUnlock  ÿGlobalFree  GetComputerNameW  GetComputerNameExW  ÅGetSystemInfo êGetVersionExW GlobalMemoryStatus  GlobalMemoryStatusEx  šGetPrivateProfileSectionNamesW  ±GetProfileSectionW  ›GetPrivateProfileSectionW â FindNextVolumeW á FindNextVolumeMountPointW  QueryDosDeviceW fGetFileType èGetVersion  GetNumberFormatW  =GetCurrencyFormatW  ÃlstrcmpiA ÍlstrlenW  £WriteConsoleW ¹GetStdHandle  ³ReadConsoleW  HeapFree  £GetProcessHeap  ÁGetSystemDirectoryA [GetExitCodeThread _TerminateThread WaitForSingleObject o CreateThread  “ DuplicateHandle †OpenProcess 4 CloseHandle BGetCurrentProcess øGlobalAlloc GlobalReAlloc GlobalLock  GlobalSize  ½ ExpandEnvironmentStringsW —GetPrivateProfileIntW ¯GetProfileIntW  GetPrivateProfileStringW  ³GetProfileStringW ªWritePrivateProfileStringW  ±WriteProfileStringW ÊGetSystemTimeAsFileTime ßGetTickCount  Å FileTimeToSystemTime  [SystemTimeToFileTime  ^TerminateProcess  FGetCurrentThreadId  EGetCurrentThread  ŠOpenThread  i CreateProcessW  ÒResumeThread  XSuspendThread 1SetPriorityClass  •GetPriorityClass  DSetThreadPriority ÛGetThreadPriority ¸ReadProcessMemory ZGetExitCodeProcess  GetCommandLineW OGetDiskFreeSpaceExW TGetDriveTypeW xGetLogicalDrives  ìGetVolumeInformationW NSetVolumeLabelW ~ DefineDosDeviceW  Ú FindFirstVolumeW  ç FindVolumeClose Ù FindFirstVolumeMountPointW  è FindVolumeMountPointClose PSetVolumeMountPointW  ‰ DeleteVolumeMountPointW îGetVolumeNameForVolumeMountPointW ğGetVolumePathNameW  V CreateFileW |VerLanguageNameW  pMoveFileExW eGetFileTime SetFileTime  Beep  äGetUserDefaultLangID  ¿GetSystemDefaultLangID  ãGetUserDefaultLCID  ¾GetSystemDefaultLCID  åGetUserDefaultUILanguage  ÀGetSystemDefaultUILanguage  ÚGetThreadLocale uGetLocaleInfoW  ı GetACP  “GetOEMCP  
 AllocConsole  J CreateConsoleScreenBuffer Æ FillConsoleOutputAttribute  È FillConsoleOutputCharacterW í FlushConsoleInputBuffer õ FreeConsole ü GenerateConsoleCtrlEvent  "GetConsoleCP  3GetConsoleMode  5GetConsoleOutputCP  7GetConsoleScreenBufferInfo  :GetConsoleTitleW  ;GetConsoleWindow  pGetLargestConsoleWindowSize ‘GetNumberOfConsoleInputEvents ’GetNumberOfConsoleMouseButtons  ìSetConsoleCP  òSetConsoleCursorPosition  ıSetConsoleMode  SetConsoleOutputCP  SetConsoleScreenBufferSize  SetConsoleTextAttribute SetConsoleTitleW  SetConsoleWindowInfo  7SetStdHandle  ¡WriteConsoleOutputCharacterW  ëSetConsoleActiveScreenBuffer  šProcessIdToSessionId  LGetDevicePowerState ÆGetSystemPowerStatus  ASetThreadExecutionState Š DeviceIoControl a CreateMutexW  …OpenMutexW  ÂReleaseMutex  l CreateSemaphoreW  ‰OpenSemaphoreW  ÃReleaseSemaphore  WaitForMultipleObjects  nGetHandleInformation  %SetHandleInformation   DeleteCriticalSection VSleep &InterlockedCompareExchange  ` CreateMutexA  O CreateEventA  (InterlockedDecrement  SetEvent  #InitializeCriticalSection îSetConsoleCtrlHandler QLeaveCriticalSection  ˜ EnterCriticalSection  úGlobalDeleteAtom  öGlobalAddAtomA  ”WideCharToMultiByte k CreateSemaphoreA  ´ReadDirectoryChangesW ”GetOverlappedResult KERNEL32.dll  O ConvertSidToStringSidA  sLsaNtStatusToWinError ÷ GetLengthSid  @IsValidSid  Z CopySid W ConvertStringSidToSidA  HLookupAccountNameW  ´PrivilegeCheck  GetTokenInformation FSetTokenInformation NLookupPrivilegeNameW  LLookupPrivilegeDisplayNameW  AdjustTokenPrivileges 4InitializeSecurityDescriptor  GetSecurityDescriptorSacl 	GetSecurityDescriptorDacl 
GetSecurityDescriptorGroup  GetSecurityDescriptorOwner  GetSecurityDescriptorControl  å GetAce  æ GetAclInformation GetNamedSecurityInfoW GetSecurityInfo uLsaOpenPolicy dLsaFreeMemory ]LsaEnumerateAccountRights _LsaEnumerateAccountsWithUserRight SLsaAddAccountRights ‚LsaRemoveAccountRights  }LsaQueryInformationPolicy ÄQueryServiceStatusEx  GetServiceKeyNameW  GetServiceDisplayNameW  ReportEventW  í GetEventLogInformation  ÊReadEventLogW – CryptGenRandom  ¬OpenProcessToken  ±OpenThreadToken JLookupAccountSidW PLookupPrivilegeValueW >IsValidAcl   AddAce  3InitializeAcl GetSidLengthRequired  ?IsValidSecurityDescriptor >SetSecurityDescriptorSacl :SetSecurityDescriptorDacl <SetSecurityDescriptorOwner  9SetSecurityDescriptorControl  6SetNamedSecurityInfoW ?SetSecurityInfo FLogonUserW  0ImpersonateLoggedOnUser RevertToSelf  2ImpersonateSelf ESetThreadToken  ´ DuplicateTokenEx   AllocateLocallyUniqueId VLsaClose  9InitiateSystemShutdownW  AbortSystemShutdownW  ` CreateProcessAsUserW  ®OpenSCManagerW  BLockServiceDatabase €UnlockServiceDatabase ÁQueryServiceLockStatusW °OpenServiceW  e CreateServiceW  ¯ DeleteService LStartServiceW B ControlService  ÃQueryServiceStatus  ¿QueryServiceConfigW 7 ChangeServiceConfigW  Õ EnumServicesStatusW Ô EnumServicesStatusExW Ğ EnumDependentServicesW  > CloseServiceHandle  
RegisterEventSourceW  ° DeregisterEventSource «OpenEventLogW §OpenBackupEventLogW = CloseEventLog " BackupEventLogW : ClearEventLogW  GetNumberOfEventLogRecords  GetOldestEventLogRecord † CryptAcquireContextW    CryptReleaseContext DSetServiceStatus  RegisterServiceCtrlHandlerExA JStartServiceCtrlDispatcherA ADVAPI32.dll   DefWindowProcA  SetWindowLongW  oGetWindowLongW  PostMessageA  a CreateWindowExW RegisterClassExW  ×wsprintfA ÎWaitForInputIdle   BlockInput  Ş EnumWindows Ë EnumChildWindows  zGetWindowTextW  :SendInput ÉVkKeyScanW  İ EnumWindowStationsW Ï EnumDesktopsW Í EnumDesktopWindows  Ì EnumClipboardFormats  Ò EnumDisplayMonitors á ExitWindowsEx ĞLockWorkStation šSystemParametersInfoW EGetParent ï GetAncestor jGetWindow GetDesktopWindow  XGetShellWindow  GetForegroundWindow WSetForegroundWindow CSetActiveWindow ë GetActiveWindow æ FindWindowW å FindWindowExW RealGetWindowClassW ı GetClassNameW ƒSetWindowPos  {GetWindowThreadProcessId  GetGUIThreadInfo  ‡SetWindowTextW  ’ShowWindow  “ShowWindowAsync ShowOwnedPopups Ä EnableWindow  ùOpenIcon  D CloseWindow ™ DestroyWindow ¦IsIconic  ³IsZoomed  ±IsWindowVisible ­IsWindow  °IsWindowUnicode ®IsWindowEnabled IsChild ?SendMessageTimeoutW BSendNotifyMessageW  PostMessageW  VSetFocus  ÿ GetClientRect tGetWindowRect mGetWindowInfo sGetWindowPlacement  ‚SetWindowPlacement  ÔWindowFromPoint “InvalidateRect  ìMoveWindow  ¼UpdateWindow  ç FlashWindow ŞMessageBeep ô GetCaretBlinkTime ESetCaretBlinkTime HideCaret ShowCaret õ GetCaretPos FSetCaretPos  AttachThreadInput 
 ArrangeIconicWindows  GetCursorPos  OSetCursorPos  [SetLayeredWindowAttributes  HGetProcessWindowStation hSetProcessWindowStation üOpenWindowStationW  c CreateWindowStationW  E CloseWindowStation  øOpenDesktopW  Q CreateDesktopW  úOpenInputDesktop  C CloseDesktop  —SwitchDesktop aGetThreadDesktop  ySetThreadDesktop  GetDoubleClickTime  )GetLastInputInfo  ò GetAsyncKeyState  !GetKeyState ÖMapVirtualKeyA  öOpenClipboard B CloseClipboard  Á EmptyClipboard  JSetClipboardData  GetClipboardData  DGetOpenClipboardWindow  GetClipboardFormatNameW GetClipboardOwner ŸIsClipboardFormatAvailable  RegisterClipboardFormatW  GetDC lGetWindowDC *ReleaseDC Ñ EnumDisplayDevicesW ëMonitorFromWindow êMonitorFromRect éMonitorFromPoint  @GetMonitorInfoW PostThreadMessageA  íMsgWaitForMultipleObjects ¡ DispatchMessageA  ªTranslateMessage   PeekMessageA   ChangeClipboardChain  ;SendMessageA  KSetClipboardViewer  RegisterHotKey  ¶UnregisterHotKey  µUnregisterDeviceNotification  RegisterDeviceNotificationA USER32.dll  ¤RpcStringFreeA  ±UuidToStringA ­UuidFromStringA ªUuidCreate  «UuidCreateNil RPCRT4.dll  OGetObjectA  %GetDeviceCaps  AddFontResourceExW  ³RemoveFontResourceExW L CreateScalableFontResourceW GDI32.dll  EnumProcesses  EnumProcessModules   EnumDeviceDrivers  GetModuleFileNameExW   GetModuleBaseNameW  	 GetDeviceDriverFileNameW   GetDeviceDriverBaseNameW   GetModuleInformation  PSAPI.DLL i NetApiBufferFree  ô NetUserEnum  NetGroupEnum  ª NetLocalGroupEnum õ NetUserGetGroups  ÷ NetUserGetLocalGroups ¬ NetLocalGroupGetMembers   NetGroupGetUsers  ñ NetUserAdd  ö NetUserGetInfo  Ÿ NetGroupGetInfo « NetLocalGroupGetInfo  û NetUserSetInfo  š NetGroupAdd ¤ NetLocalGroupAdd  ¦ NetLocalGroupAddMembers © NetLocalGroupDelMembers  DsGetDcNameW  â NetShareAdd æ NetShareEnum  ã NetShareCheck è NetShareGetInfo é NetShareSetInfo ï NetUseEnum  ğ NetUseGetInfo – NetGetDCName  Î NetScheduleJobGetInfo Ë NetScheduleJobAdd Í NetScheduleJobEnum  ß NetSessionEnum  à NetSessionGetInfo s NetConnectionEnum “ NetFileEnum ” NetFileGetInfo  ó NetUserDel  œ NetGroupDel § NetLocalGroupDel  › NetGroupAddUser  NetGroupDelUser ä NetShareDel ’ NetFileClose  Ş NetSessionDel Ì NetScheduleJobDel NETAPI32.dll  I PdhLookupPerfNameByIndexW " PdhEnumObjectsW  PdhEnumObjectItemsW K PdhMakeCounterPathW S PdhParseCounterPathW  ; PdhGetFormattedCounterValue 
 PdhBrowseCountersW  8 PdhGetDllVersion   PdhConnectMachineW  } PdhSetDefaultRealTimeDataSource Q PdhOpenQueryW  PdhCloseQuery  PdhAddCounterW  y PdhRemoveCounter   PdhCollectQueryData ˆ PdhValidatePathW  pdh.dll  PlaySoundW  WINMM.dll - WNetGetLastErrorW L WNetUseConnectionW  < WNetGetUniversalNameW 7 WNetGetResourceInformationW > WNetGetUserW   WNetCancelConnection2W  MPR.dll WS2_32.dll  . CoInitializeEx  N CoTaskMemAlloc  O CoTaskMemFree StringFromGUID2  CoCreateInstance  $ CoGetObject ¡ IIDFromString  CLSIDFromProgID ä ProgIDFromCLSID  CLSIDFromString Y CreateBindCtx ^ CreateFileMoniker Ø OleRun  ole32.dll OLEAUT32.dll   CommandLineToArgvW  B SHFreeNameMappings  @ SHFileOperationW  S SHGetSpecialFolderLocation  Q SHGetPathFromIDListW  Z SHInvokePrinterCommandW ; SHChangeNotify  SHELL32.dll a EnumPrintersW WINSPOOL.DRV   GetFileVersionInfoW  GetFileVersionInfoSizeW 
 VerQueryValueA   VerQueryValueW  VERSION.dll : GetNetworkParams   GetAdaptersInfo @ GetPerAdapterInfo . GetInterfaceInfo  ) GetIfEntry  + GetIfTable  / GetIpAddrTable  4 GetIpNetTable 2 GetIpForwardTable G GetTcpTable N GetUdpTable   GetBestRoute   GetAdapterIndex ; GetNumberOfInterfaces  FlushIpNetTable ‡ SetTcpEntry  GetBestInterface  iphlpapi.dll   SetSuspendState POWRPROF.dll   GetUserNameExW  % LsaFreeReturnBuffer $ LsaEnumerateLogonSessions & LsaGetLogonSessionData   FreeContextBuffer  EnumerateSecurityPackagesW    InitializeSecurityContextW    AcceptSecurityContext . QueryContextAttributesW , MakeSignature  EncryptMessage   AcquireCredentialsHandleW  FreeCredentialsHandle  DeleteSecurityContext 1 QuerySecurityContextToken  ImpersonateSecurityContext  O VerifySignature  DecryptMessage  Secur32.dll ! LoadUserProfileW  , UnloadUserProfile  GetProfileType  USERENV.dll   WTSCloseServer   WTSFreeMemory  WTSEnumerateProcessesW   WTSEnumerateSessionsW  WTSQuerySessionInformationW  WTSDisconnectSession  	 WTSLogoffSession   WTSOpenServerW   WTSSendMessageW WTSAPI32.dll  SetupDiCreateDeviceInfoListExW  SetupDiDestroyDeviceInfoList  3SetupDiGetClassDevsExW   SetupDiEnumDeviceInfo JSetupDiGetDeviceRegistryPropertyW !SetupDiEnumDeviceInterfaces HSetupDiGetDeviceInterfaceDetailW  SetupDiClassNameFromGuidExW SetupDiClassGuidsFromNameExW  ESetupDiGetDeviceInstanceIdW SETUPAPI.dll  ¸strcmp  ®_snprintf ‘malloc  ¾strlen  ˜memmove ^free  æwcslen  ™memset  È _errno  _pctype _isctype  a __mb_cur_max  ²sprintf ¯_snwprintf  é_wcsdup Åstrstr  ·strchr  Ê _except_handler3  ºstrcpy  §realloc áwcscmp  ­setlocale ¶strcat  Éstrtoul @calloc  Ástrncpy ãwcscpy  printf  –memcmp   ??3@YAXPAX@Z  I __CxxFrameHandler ’_purecall A _CxxThrowException   ??2@YAPAXI@Z  ¦ _beginthreadex   ??0exception@@QAE@ABV0@@Z ğwcstol  MSVCRT.dll  U __dllonexit †_onexit  ??1type_info@@UAE@XZ  _initterm  _adjust_fdiv   ??0Init@ios_base@std@@QAE@XZ  	??1Init@ios_base@std@@QAE@XZ  ¥ ??0_Winit@std@@QAE@XZ ??1_Winit@std@@QAE@XZ é ??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAE@XZ  ø?_Tidy@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@AAEX_N@Z  ê ??1?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAE@XZ  ù?_Tidy@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@AAEX_N@Z  "?assign@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAEAAV12@ABV12@II@Z  b?npos@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@2IB   ?assign@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@PBDI@Z  -?_C@?1??_Nullstr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@CAPBDXZ@4DB &?assign@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAEAAV12@PBGI@Z  ?append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@PBDI@Z  ü?insert@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@IPBDI@Z ?assign@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@ABV12@II@Z  a?npos@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@2IB  ?append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@ID@Z  À ??0logic_error@std@@QAE@ABV01@@Z  Å ??0out_of_range@std@@QAE@ABV01@@Z ??1out_of_range@std@@UAE@XZ ¯??_7out_of_range@std@@6B@ Á ??0logic_error@std@@QAE@ABV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@1@@Z L ??0?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAE@PBDABV?$allocator@D@1@@Z  ??1_Lockit@std@@QAE@XZ  ¢ ??0_Lockit@std@@QAE@XZ  .?_C@?1??_Nullstr@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@CAPBGXZ@4GB S ??0?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAE@PBGABV?$allocator@G@1@@Z  MSVCP60.dll ‹ DisableThreadLibraryCalls ¿_strdup                   ¸‘J    \:          H: P: X: 'D   f: p:    twapi.dll SWIG_init Twapi_Init                                                                                                                                                                                                                                                                                                                                                                                                          UUU­Uçc$d£|w“+ W ƒ                     global  twapi::SHChangeNotify   twapi::ComEventSink twapi::IDispatch_Invoke twapi::get_build_config twapi::kl_get   twapi::try  twapi::parseargs    Could not get OS version    ,   . Must be one of    Invalid Non-boolean Non-integer enumeration Non-integer     Command has extra arguments specified:  Unknown option '    No value supplied for option '  Invalid option type '   Badly formed option descriptor: '   switch  bool    arg int Extra argument or unknown option '  '   Non-integer value specified for -maxleftover    Missing value for -maxleftover  Too many options specified  -maxleftover    -nulldefault    -ignoreunknown  argvVar optlist ?-ignoreunknown? ?-nulldefault? ?-?  value '    ' specified for option '-   errorResult Invalid syntax: should be    SCRIPT ?onerror ERROR ERRORSCRIPT? ...?finally FINALSCRIPT?    script ?onerror ERROR errorscript? ...?finally FINALSCRIPT? errorCode   finally onerror KEYLIST KEY ?DEFAULT?   No field     found in keyed list.   Invalid keyed list format. Must have even number of elements.   errorInfo   can't find "global" command invalid TclX result save object Failed to allocate %d bytes.    DllGetVersion   Integer '%d' not within range %d-%d Invalid item id list format CoTaskMemAlloc failed in SHChangeNotify Could not convert SID pointer:  Integer value must be less than 65536   T w a p i H i d d e n W i n d o w    	ddddddd
 !"#dddddd
 !"#     äF   ÄF   ”F   xF   XF   <F    FInvalid option specified.   Internal limit exceeded.    Incorrect number of arguments.  Extra arguments specified.  Attempt to write past the end of memory buffer. Invalid arguments specified.    No error.   Twapi error %d  TWAPI   W i n d o w s   e r r o r :   % l d     f u n c t i o n   n o t   s u p p o r t e d   u n d e r   t h i s   W i n d o w s   v e r s i o n   p d h . d l l   n e t m s g . d l l     Windows error: %ld  TWAPI_WIN32     :       0123456789abcdef           äA   Ü   Ø   Ô   Ğ   Ì   È   À   ¸	   ¬
   ¤   œ      Œ   „   €   |   x   t   p   ğA   h   `   X   P   H$   @   4aÖÖ0×ĞÖü Ø ×ìĞØpØÜ Ù@ÙÌ›ÚÚ¸xÛÛ¤TÜïÛ˜0İËÜˆ
Ş§İ|ãŞ€Ş            hPYßàPàHX    `0ÑXÿŸPÏoHŸ?                @Ô¾`Ih    8)Ê,˜ ‹Ş~®Nø~äNîĞ¾À¬¢                 x' pğIx    ˜’ 3 a!!„1"Ñ!t-#¡"d1$¥#P$%©$                @¤œ%K&€˜Jˆ    <¶&W&8…'%'                0´õ'¤(K˜    8l22;3Û2$%4«35¢46™5ø
76è8‡7Üø8~8Ğğ9u9            À h:; XK¨    °í ¼€\€ŒŒ,x\‚ü\,ƒÌ‚Lüƒœƒ@Ì„l„            0X<…ë…°ğK¸    °“    ğb—    Ğø—    ¨™    ”Š™    xÍ™    X+š    8š    úš    üd›    ÜÑ›    ¼Oœ    œÈœ    ˆJ    pÎ    \t    HÙ    4OŸ     ´Ÿ    #     ø„     è¡    Üˆ¡    Äã¡    ¬€¢    %£    t‚£    \Ø£    @Å¥    "¦     »¦    ìT§    ØW¨    ¼Ğ¨    ¨*©    Œ|©    tÎ©    T6ª    4¥ª    «    u«    ìä«    ĞS¬    ¬Â¬    „S­    `ä­    8f®    ÷®    ğˆ¯    È
°     ›°    x±    L®±     0²    ü²²    ĞC³    ´Ô³    µ    t·µ    `P¶    D×¶     ò¸    t¹    ôº    à¸º    È1»    °ª»    ˜:¼    tÊ¼    P[½    $ì½    ¾    ì
šÂ    È
JÆ    ¬
îÆ    Œ
(È    t
İÈ    `
"Ê    @
ùÊ    ,
YË    
’Ë    ü	ÓË    ä	SÌ    Ğ	LÎ    ¸	¹Î    ˜	Ï    €	}Ï    h	ÅÏ    P	şÏ    4	}Ğ    $	bÑ    üĞÑ    ÌNÒ    ¨øÒ    „Ô    `+Õ    @UÕ    ¥Õ    èÖ    ¸aÖ    ŒĞÖ    `0×    4 ×     Ø    ÜpØ    °ĞØ    „@Ù    X Ù    ,Ú     ›Ú    ĞÛ     xÛ    pïÛ    @TÜ    ËÜ    ğ0İ    Ä§İ    ˜
Ş    p€Ş    HãŞ    ,Yß    ²ß    ô}7 pIàà    È|à    ¬óà    Œrá    pâ    Pnâ    0ã    ä    ø÷ä    ä€å    Ìâå    °æ    ˜™æ    xç    `è    <şè     ½é     tê    Øİê    ¼/ë     Yë    |Ğë    Túë    4$ì    ºì     :í    à ¦í    Ì õí    ° <î    ” ¶î    l 0ï    D qï     Ûï     9ğ    ìÿÄğ    Ôÿ9ñ    ¸ÿ ñ    œÿUò    |ÿ
ó    \ÿó    @ÿ2ô    (ÿSõ    ÿ}õ    ğşÒõ    Ôşüõ    ¼şCö    ¨ş¸ö    şC÷    xş ÷    \şÉù    Hşü    0ş“ü    şı     ştı    äıíı    ÈıTş    ıĞş    Xı%ÿ    <ızÿ     ıQ     ıß     ìü>    Ğü    ´üº     ü¢    ˆüı    lüD    Tü©    <ü    $üq    üİ    ôûš    Üû\    ¸û¼    ˜û    tûO	    Xû¯	    8û
    ûc
    ôúí
    àúw    ¼ú|    ˜úI    xú|    Tú    <úW    úÓ    ìù(    Äù£    °ùø    œùM    ˆù¹    tù£    \ùÑ    Dù0    0ùŸ    ùÿ    ùo    ìøÏ    Ôø?    ¼øŸ    ¬ø    ˜øe    Œø}7 ĞIløÊ    Lø)    ,ø˜    ø    ì÷‹    Ì÷    ¬÷~    Œ÷Ş    l÷N    L÷®    $÷    üö~    Ôöî    ¬öN    „ö¾    \ö    4ö    ö    äõ¢    ¼õ    ¤õx    ˆõÎ    tõ}7 xJPõ3     ,õ’     õ!    äôa!    ÀôÑ!    œô1"    pô¡"    Dô-#    ô¥#    ìó1$    Àó©$    ”ó$%    xóœ%    Xóò%    @ó}7 ğJ,óW&    ó¶&    ó%'    ğò…'    Üòõ'    ÈòK(    ¸ò}7 8K¤ò°(    ŒòÚ(    xò-)    dò¨)    Pò**    8ò¬*     ò +    òT+    èñ¨+    Ğñ,    ¸ñ³,    ¤ñ-    ñ¦-    tñ“.    `ñ(/    Hñ½/    0ñ10    ñÎ0    üğs1    Üğ2    ¼ğl2    œğÛ2    |ğ;3    Xğ«3    4ğ%4    ğ¢4    ìï5    Äï™5    œï6    tï6    Lï
7    $ï‡7    üî8    Øî~8    ´îø8    îu9    lîğ9    Pîh:    4î¾:    î}7 ĞKî#;    ìí˜;    Ôí/<    Àí¢<    ¨í=    íŠ=    |íï=    líc>    XíÁ>    @í?    0í}?     íê?    íW@    øìÄ@    àì1A    ÈìA    ¸ìB    œì™B    €ìKC    lìÀC    \ì5D    Dì°D    ,ì/E    ì®E    øë<F    ÜëÊF    ÄëXG    ¬ëĞG    ˜ëvH    „ëúH    pëXI    dëÌI    PëJ    4ëcJ    ëªJ    ëëJ    ğêIK    Üê§K    ÈêL    ¬êNL    ê¬L    |êM    `êLM    LêM    8êN    $êzN    êÂN    ôéO    àé8O    ÈékO    ¤é¤P    „éQ    déQ    HéîQ    ,é…R    éYS    ôè¹S    ØèãS    Äè8T    °èT    ˜è+U    €èBV    lèÍV    Tè-W    <èW    $è
X    èjX    ğç±X    ØçY    ÄçiY    ¬ç»Y    ”çZ    |çyZ    dç²Z    LçëZ    4çŠ[    ç\    ğæ[\    Ğæ…\    ´æ]    æV]    pæ¥]    Pæ^    4æC^    æ–^    øåß^    Üå(_    Àåo_     å¶_    |å`    dåj`    Håa    0åÂa    å	b    å£b    øäêb    àä1c    Èä©c    °ä!d    ˜äÙd    xäQe    `äf    @ä¯f     ä=g     äÊg    äãëh    Äã|i    ¨ãÖi    ˆã8j    hãšj    Lãok    4ãÑk    ãJl    ãİl    ìâ‰m    Ğân    °â—n    ”â7o    pâ‘o    Pâ1p    ,âq    âhq    øáÊq    ÜáEr    ÌáÑr    ¬á7s    Œá£s    tá3t    Tá÷t    0á’u    á(v    øà±v    ààVw    Èàx    °àZx    œà x    €àæx    hày    Tà}y    4à;z    ànz    øß˜z    Üß|    ¼ß†|    œß÷|    |ß8}    \ßĞ}    <ßg~    ß    ìŞí    ÀŞ\€    ”Ş¼€    dŞ,    4ŞŒ    Şü    Üİ\‚    ¨İÌ‚    tİ,ƒ    Lİœƒ    $İüƒ    üÜl„    ÔÜÌ„    ¸Ü<…    ˜Ü’…    €Ü}7 PLhÜ÷…    LÜâ†    ,Üv‡    ÜÖ‡    øÛ ‰    àÛYŠ    ÈÛAŒ    ´Û¡Œ    œÛ£    €Û.    dÛ²    HÛP’    (Ûò’    Û”“    ğÚY•    ÔÚø˜    ´Úl›    ˜ÚÁœ    |Ú!    `Ú~    @Ú.     Ú—    ÚÊ    ğÙ{Ÿ    ĞÙæ     ¼ÙF¡     Ù÷¡    ŒÙ¨¢    tÙ£    \Ùm£    DÙß£     Ùa¤     Ùï¤    äØ}¥    ĞØ¦    ¬ØE¦    ˆØ§    dØv¨    DØ8©    0Ø™©    ØÒ©    ü×ª    ä×aª    È×ğª    ¤×7«    Œ×Ô¬    t×J­    P×È­    (×Y®     ×è®    ìÖT¯    ØÖÑ¯    ¸Ö°     Ö‹°    „Öó°    `Ö4±    @Ö­±    (Ö²    Öd²    øÕÎ³    äÕ6´    ÀÕß´    œÕ µ    ˆÕ¶    dÕ_¶    <Õš¶    $ÕÄ¶    Õ5·    ğÔ‰·    ÔÔU¸    ¸Ôó¸    œÔÑ¹    €Ôº    XÔuº    DÔ»º    ,Ô`»    ÔÅ»    üÓz¼    àÓŞ¼    ¼ÓB½    ¤ÓŸ½    „Óó½    tÓM¾    `Óã¾    LÓy¿    8Ó	À     ÓŸÀ    ÓÁ    èÒ¾Á    ĞÒ[Â    ¸ÒöÂ     Ò’Ã    „ÒÄ    hÒ®Ä    LÒAÅ    (ÒÔÅ    ÒUÆ    äÑ·Æ    ¸ÑhÇ    ”ÑİÇ    xÑÈ    `ÑƒÈ    DÑÖÈ    $ÑDÉ    Ñ™É    ğĞîÉ    ØĞ\Ê    ´ĞãÊ    œĞHË    ˆĞ)Ì    pĞÍ    TĞcÍ    4ĞñÍ    Ğ$Î    øÏwÎ    ØÏGÏ    °Ï–Ï    ŒÏÄĞ    lÏ$Ñ    LÏ©Ò    $Ï4Ó     Ï~Ô    ØÎhÕ    ´Î§Ö    ÎÃ×    lÎ½Ø    TÎ¦Ù    ,Î²Ú    Î5Û    ğÍˆÛ    ØÍ²Û    ÀÍÜÛ    ¨Í_Ü    ˆÍ‰Ü    lÍùÜ    XÍ,İ    DÍ_İ    ,Í—İ    ÍÏİ    øÌŞ    àÌ?Ş    ´Ì„Ş    ˆÌ¿Ş    tÌúŞ    `ÌÆà    LÌ®á    (Ìñá    Ì,â    ğËgâ    ØËÍâ    ¼ËWã    ˜ËÌã    |Ë1ä    XË¦ä    DËå    0Ëâå    Ëæ     Ëtæ    äÊôæ    ÈÊFç    °Ê®ç    ˜Êè    |Ê×è    hÊFé    PÊìé    <ÊNê    $Ê¹ê    Ê_ë    ğÉàë    ĞÉì    °ÉÇí    ”É%î    €Éfî    lÉ§î    LÉï    0Éyï    ÉCñ    øÈ¶ñ    ĞÈò    ¼Èxò    ¨ÈAó    ”ÈØó    |È8ô    dÈõ    LÈŸõ    ,È4ö    üÇ÷    ĞÇ÷    ¬Çè÷    ŒÇø    lÇSù    HÇ³ù    (Ç›ú    ÇYû    äÆ¹û    ÀÆOü     Æ¯ü    ˆÆı    pÆı    XÆ:ş    @Æ²ş    $Æ‹ÿ    ÆG     ğÅ³     ÔÅ    °ÅK    ”Å–    xÅ$    `Å“    HÅw    0Åç    ÅW    ìÄ2    ÌÄ'    ¨Äõ    €Ä‘    XÄ7    4Ä×    Ä}	    ìÃ
    ÌÃÃ
    ¤Ãc    €Ã1    \Ãz    8Ã    Ãb    ôÂÖ    ØÂu    ´Â    ˜Âá    |Â¶    `Â@    DÂÕ    $Âm     Â    àÁ¤    ÀÁ-     ÁÕ    |ÁP    XÁ    8Á    Á    üÀô    àÀ‚    ÄÀì    ¤À]    tÀ    PÀ£    À    à¿´    ¼¿y    ˜¿N    t¿¸    L¿)     (¿É     ¿Z!    ä¾5"    Ä¾ø"    ¨¾t#    ˆ¾$    d¾Ï$    <¾Ö%    ¾a&    ø½ú&    Ü½š'    À½(    ˜½u(    p½_)    H½ë)    ½*    ğ¼E+    È¼ú+     ¼¯,    |¼c-    T¼.    $¼ı.    ø»£/    Ô»I0    ¬»ı0    €»À1    T»v2    4»23    »·3    Üº4    ´º5    „º­5    Tº96    0ºÅ6    ºQ7    Ü¹ä7    ¸¹¤8    ˜¹)9    |¹Å9    `¹`:    D¹ü:    (¹—;    ¹2<    ä¸Î<    È¸M=    ¬¸Á=    ¸@>    t¸´>    P¸(?    0¸§?    ¸7@    è·Ğ@    È·UA    ¬·"B    ·–B    t·C    P·«C                    H·    @·                H·                                                        4·    ,·8K            4·                                                         ·    ·                ·                        ô¶                        è¶                         ·                        Ü¶                                                        È¶    ´¶                È¶                                                        ¬¶    ¤¶                ¬¶                                                        ”¶    ˆ¶                ”¶                                                        €¶    x¶                €¶                                                        l¶    d¶                l¶                                                        X¶    L¶                X¶                                                        D¶    4¶ĞI            D¶                                                        $¶    ¶                $¶                                                        è¶    ¶                ·                        ô¶                        è¶                         ·                        Ü¶                                                         ¶    øµ                 ¶                                                        ìµ    àµ                ìµ                                                        Ôµ    Ìµ                Ôµ                                                        ¼µ    °µ                ¼µ                                                         µ    µ                 µ                                                        „µ    xµ                „µ                                                        Xµ    <µ                Xµ                                                        $µ    µ                $µ                                                         µ    ğ´                 µ                                                        è´    à´                è´                                                        Ø´    Ô´                Ø´                                                        ¼´    ¤´                ¼´                                                        ˜´    ´                ˜´                                                        |´    l´                |´                                                        X´    D´                X´                                                        4´    $´xJ            4´                                                        ´    ´                ´                        ´                        ´                                                        ğ³    Ü³                ğ³                                                        Ä³    °³                Ä³                                                        ¤³    ˜³                ¤³                                                        ˆ³    x³                ˆ³                                                        l³    `³                l³                                                        T³    L³                T³                                                        D³    <³                D³                                                        4³    ,³                4³                                                         ³    ³                 ³                                                        ô²    Ø²                ô²                                                        Ä²    °²                Ä²                                                        ¨²     ²                ¨²                                                        ”²    ˆ²                ”²                                                        |²    p²                |²                                                        X²    @²                X²                                                        $²    ²                $²                                                        ·    ²                ·                        ô¶                        è¶                         ·                        Ü¶                                                        ô±    è±                ô±                                                        Ü±    Ğ±                Ü±                                                        À±    ´±                À±                                                        ˜±    |±                ˜±                                                        l±    \±                l±                                                        L±    <±                L±                                                        4±    ,±                4±                                                         ±    ±                 ±                                                         ±    ğ°                 ±                                                        ä°    Ø°                ä°                                                        È°    ¸°                È°                                                        °°    ¨°                °°                                                        œ°    ”°                œ°                                                        €°    l°                €°                                                        `°    T°                `°                                                        L°    D°                L°                                                        8°    ,°                8°                                                         °    °                 °                                                         °    ğ¯                 °                                                        à¯    Ğ¯                à¯                                                        È¯    À¯                È¯                                                        ´¯    ¨¯                ´¯                                                        ´     ¯                ´                        ´                        ´                                                        ”¯    Œ¯                ”¯                                                        t¯    \¯                t¯                                                        P¯    H¯                P¯                                                        0¯    ¯                0¯                                                        ü®    à®                ü®                                                        Ä®    ¬®                Ä®                                                        œ®    ®                œ®                                                        €®    p®                €®                                                        H®    $®                H®                                                        ®    ®                ®                                                         ®    ì­                 ®                                                        Ü­    Ì­                Ü­                                                        ¸­    ¤­                ¸­                                                        ­    |­                ­                                                        p­    d­                p­                                                        T­    H­                T­                                                        <­    0­                <­                                                         ­    ­                 ­                                                        ­    ø¬                ­                                                        è¬    Ø¬                è¬                                                        Ä¬    ´¬                Ä¬                                                        œ¬    ˆ¬                œ¬                                                        |¬    t¬                |¬                                                        `¬    P¬ĞK            `¬                                                        @¬    0¬                @¬                                                        ¬    ¬                ¬                                                        ø«    à«                ø«                                                        Ğ«    Ä«                Ğ«                                                        ´«    ¤«                ´«                                                        ”«    „«                ”«                                                        t«    d«                t«                                                        T«    D«                T«                                                        4«    $«                4«                                                        «    üª                «                                                        Üª    ¼ª                Üª                                                        ¨ª    ”ªpI            ¨ª                                                        „ª    tª                „ª                                                        `ª    LªPL            `ª                        8ª                                                    8ª    $ªPL            8ª                        `ª                                                    ª    ô©                ª                                                        à©    Ğ©                à©                                                        ô¶    À©                ·                        ô¶                        è¶                         ·                        Ü¶                                                        ¬©    ˜©                ¬©                                                        Ü¶    ©                ·                        ô¶                        è¶                         ·                        Ü¶                                                        €©    p©                €©                                                        \©    L©                \©                                                        4©    ©                4©                                                         ©    è¨                 ©                                                        à¨    Ø¨                à¨                                                        È¨    ¸¨                È¨                                                        ¤¨    ¨                ¤¨                                                        |¨    h¨                |¨                                                        \¨    P¨                \¨                                                        D¨    8¨                D¨                                                        (¨    ¨                (¨                                                        ´    ¨                ´                        ´                        ´                                                         ¨    ì§ğJ             ¨                                                        Ø§    Ä§                Ø§                                                        ¬§    ”§                ¬§                                                        „§    x§                „§                                                        l§    `§                l§                                                        X§    P§                X§                                                        @§    0§                @§                                                         §    §                 §                                                        §     §                §                                                        ô¦    ì¦                ô¦                                                        Ü¦    Ì¦                Ü¦                                                        ¼¦    ¬¦                ¼¦                                                        ¤¦    œ¦                ¤¦                                                        „¦    l¦                „¦                                                    pqÈq rèr@s˜sğsHt tøtPu¨upvÈv wxwĞw(x€xØx0yˆyày8zzèz@{˜{ğ{€|Ø|0}ˆ}à}8~~è~@˜ğH€ €ø€P¨ ‚È‚ ƒxƒĞƒ(„€„Ø„0…ˆ…à…8††è†@‡˜‡ğ‡Hˆ ˆøˆP‰¨‰ ŠXŠèŠ@‹˜‹ğ‹HŒ ŒøŒP¨ X°`¸hÀ‘p‘È‘ ’x’Ğ’(“€“Ø“0”ˆ”à”8••è•@–˜–ğ–H— —˜€˜Ø˜0™ø™Pš›p›È› œxœĞœ(€Ø0ˆàpŸÈŸ  x Ğ (¡€¡Ø¡0¢ˆ¢à¢8££è£    IScheduledWorkItem *    _p_IScheduledWorkItem   IID *   _p_IID  MIB_TCPROW *    _p_MIB_TCPROW   STARTUPINFOW *  _p_STARTUPINFOW HGLOBAL _HGLOBAL    ACL *   _p_ACL  TASK_TRIGGER *  _p_TASK_TRIGGER LPMODULEINFO *  _p_LPMODULEINFO ATOM *  _p_ATOM IUnknown *  _p_IUnknown IUnknown ** _p_p_IUnknown   PROCESS_INFORMATION *   _p_PROCESS_INFORMATION  TOKEN_PRIVILEGES *  _p_TOKEN_PRIVILEGES WINDOWPLACEMENT *   _p_WINDOWPLACEMENT  BOOL *  IMoniker ** _p_p_IMoniker   IMoniker *  _p_IMoniker HINSTANCE   _HINSTANCE  IEnumWorkItems **   _p_p_IEnumWorkItems IEnumWorkItems *    _p_IEnumWorkItems   unsigned int *  _p_unsigned_int BSTR *  _p_BSTR LSA_OBJECT_ATTRIBUTES * _p_LSA_OBJECT_ATTRIBUTES    SECURITY_ATTRIBUTES *   _p_SECURITY_ATTRIBUTES  IRecordInfo **  _p_p_IRecordInfo    IRecordInfo *   _p_IRecordInfo  ULONG * DISPLAY_DEVICEW *   _p_DISPLAY_DEVICEW  unsigned long * LASTINPUTINFO * _p_LASTINPUTINFO    SYSTEM_POWER_STATUS *   _p_SYSTEM_POWER_STATUS  LPSERVICE_STATUS    _LPSERVICE_STATUS   SERVICE_STATUS *    _p_SERVICE_STATUS   Tcl_Interp *    _p_Tcl_Interp   OSVERSIONINFOEXW *  _p_OSVERSIONINFOEXW CONSOLE_SCREEN_BUFFER_INFO *    _p_CONSOLE_SCREEN_BUFFER_INFO   LPCWSTR_MULTISZ *   _p_LPCWSTR_MULTISZ  RECORDDATA **   _p_p_RECORDDATA RECORDDATA *    _p_RECORDDATA   ITypeComp **    _p_p_ITypeComp  ITEMIDLIST *    _p_ITEMIDLIST   ITEMIDLIST **   _p_p_ITEMIDLIST ITypeComp * _p_ITypeComp    struct sockaddr_in *    _p_sockaddr_in  LPWSTR_CoTaskMem *  _p_LPWSTR_CoTaskMem IDispatchEx *   _p_IDispatchEx  GUITHREADINFO * _p_GUITHREADINFO    COORD * _p_COORD    LPCWSTR_WITH_NULL * _p_LPCWSTR_WITH_NULL    LARGE_INTEGER * _p_LARGE_INTEGER    OVERLAPPED *    _p_OVERLAPPED   HDEVINFO    _HDEVINFO   MONITORINFO *   _p_MONITORINFO  LPWSTR *    _p_LPWSTR   ITypeLib ** _p_p_ITypeLib   ITypeLib *  _p_ITypeLib HMODULE_LITERAL *   _p_HMODULE_LITERAL  ADDRESS_LITERAL *   _p_ADDRESS_LITERAL  HWND_LITERAL *  _p_HWND_LITERAL ULARGE_INTEGER *    _p_ULARGE_INTEGER   HMENU   _HMENU  SP_DEVICE_INTERFACE_DETAIL_DATA_W * _p_SP_DEVICE_INTERFACE_DETAIL_DATA_W    ITypeInfo **    _p_p_ITypeInfo  ITypeInfo * _p_ITypeInfo    IEnumConnectionPoints * _p_IEnumConnectionPoints    IEnumConnectionPoints **    _p_p_IEnumConnectionPoints  IProvideClassInfo2 *    _p_IProvideClassInfo2   char ** _p_p_char   LSA_UNICODE_STRING *    _p_LSA_UNICODE_STRING   CLSID * _p_CLSID    long *  wchar_t *   _p_wchar_t  HDESK   _HDESK  ITaskTrigger *  _p_ITaskTrigger ITaskTrigger ** _p_p_ITaskTrigger   SC_HANDLE   _SC_HANDLE  LSA_HANDLE  _LSA_HANDLE HANDLE  _HANDLE HANDLE *    _p_HANDLE   NONNEGATIVE_HANDLE  _NONNEGATIVE_HANDLE ITask * _p_ITask    WORD *  _p_WORD SMALL_RECT *    _p_SMALL_RECT   FILETIME *  _p_FILETIME IEnumVARIANT ** _p_p_IEnumVARIANT   VARIANT *   _p_VARIANT  BYTE *  _p_BYTE IEnumVARIANT *  _p_IEnumVARIANT IPersistFile *  _p_IPersistFile SP_DEVICE_INTERFACE_DATA *  _p_SP_DEVICE_INTERFACE_DATA IBindCtx ** _p_p_IBindCtx   IBindCtx *  _p_IBindCtx SecHandle * _p_SecHandle    LPDWORD LPCWSTR_NULL_IF_EMPTY * _p_LPCWSTR_NULL_IF_EMPTY    LPWSTR_NULL_IF_EMPTY *  _p_LPWSTR_NULL_IF_EMPTY LPOLESTR *  _p_LPOLESTR HMONITOR    _HMONITOR   int *   _p_int  ITaskScheduler *    _p_ITaskScheduler   SEC_WINNT_AUTH_IDENTITY_W * _p_SEC_WINNT_AUTH_IDENTITY_W    double *    _p_double   HTHEME  _HTHEME void *  _p_void void ** _p_p_void   HCRYPTPROV  _HCRYPTPROV HCRYPTPROV *    _p_HCRYPTPROV   LOGFONTW *  _p_LOGFONTW IConnectionPoint ** _p_p_IConnectionPoint   IConnectionPoint *  _p_IConnectionPoint _p_BOOL _p_long LONG *  _p_LONG WINDOWINFO *    _p_WINDOWINFO   SP_DEVINFO_DATA *   _p_SP_DEVINFO_DATA  SecBufferDesc * _p_SecBufferDesc    HGDIOBJ _HGDIOBJ    SECURITY_DESCRIPTOR *   _p_SECURITY_DESCRIPTOR  HDC _HDC    PSID *  _p_PSID SYSTEMTIME *    _p_SYSTEMTIME   IProvideClassInfo * _p_IProvideClassInfo    IConnectionPointContainer * _p_IConnectionPointContainer    HMODULE *   _p_HMODULE  IDispatch **    _p_p_IDispatch  IDispatch * _p_IDispatch    SC_LOCK _SC_LOCK    LPCWSTR *   _p_LPCWSTR  WCHAR * _p_WCHAR    DWORD * LPDEVMODEW *    _p_LPDEVMODEW   RECT const *    _p_RECT AT_INFO *   _p_AT_INFO  HWINSTA _HWINSTA    GUID *  _p_GUID LPCOLESTR * _p_LPCOLESTR    UUID *  _p_UUID Twapi_fileverptr_t  _Twapi_fileverptr_t _p_ULONG    _p_DWORD    _p_unsigned_long    _LPDWORD    HREFTYPE *  _p_HREFTYPE POINT * _p_POINT    LUID *  _p_LUID twapi::IPersistFile_SaveCompleted   twapi::IPersistFile_Save    twapi::IPersistFile_Load    twapi::IPersistFile_IsDirty twapi::IPersistFile_GetCurFile  twapi::ITaskTrigger_SetTrigger  twapi::ITaskTrigger_GetTriggerString    twapi::ITaskTrigger_GetTrigger  twapi::ITask_SetWorkingDirectory    twapi::ITask_SetTaskFlags   twapi::ITask_SetPriority    twapi::ITask_SetParameters  twapi::ITask_SetMaxRunTime  twapi::ITask_SetApplicationName twapi::ITask_GetWorkingDirectory    twapi::ITask_GetTaskFlags   twapi::ITask_GetPriority    twapi::ITask_GetParameters  twapi::ITask_GetMaxRunTime  twapi::ITask_GetApplicationName twapi::IScheduledWorkItem_Terminate twapi::IScheduledWorkItem_SetWorkItemData   twapi::IScheduledWorkItem_SetIdleWait   twapi::IScheduledWorkItem_SetFlags  twapi::IScheduledWorkItem_SetErrorRetryInterval twapi::IScheduledWorkItem_SetErrorRetryCount    twapi::IScheduledWorkItem_SetCreator    twapi::IScheduledWorkItem_SetComment    twapi::IScheduledWorkItem_SetAccountInformation twapi::IScheduledWorkItem_Run   twapi::IScheduledWorkItem_GetTriggerString  twapi::IScheduledWorkItem_GetTriggerCount   twapi::IScheduledWorkItem_GetTrigger    twapi::IScheduledWorkItem_GetStatus twapi::IScheduledWorkItem_GetNextRunTime    twapi::IScheduledWorkItem_GetMostRecentRunTime  twapi::IScheduledWorkItem_GetIdleWait   twapi::IScheduledWorkItem_GetFlags  twapi::IScheduledWorkItem_GetExitCode   twapi::IScheduledWorkItem_GetCreator    twapi::IScheduledWorkItem_GetComment    twapi::IScheduledWorkItem_GetAccountInformation twapi::IScheduledWorkItem_EditWorkItem  twapi::IScheduledWorkItem_DeleteTrigger twapi::IScheduledWorkItem_CreateTrigger twapi::IEnumWorkItems_Skip  twapi::IEnumWorkItems_Reset twapi::IEnumWorkItems_Clone twapi::ITaskScheduler_GetTargetComputer twapi::ITaskScheduler_SetTargetComputer twapi::ITaskScheduler_NewWorkItem   twapi::ITaskScheduler_IsOfType  twapi::ITaskScheduler_Enum  twapi::ITaskScheduler_Delete    twapi::ITaskScheduler_AddWorkItem   twapi::ITaskScheduler_Activate  twapi::IProvideClassInfo2_GetGUID   twapi::IProvideClassInfo_GetClassInfo   twapi::IEnumConnectionPoints_Skip   twapi::IEnumConnectionPoints_Reset  twapi::IEnumConnectionPoints_Next   twapi::IConnectionPointContainer_FindConnectionPoint    twapi::IConnectionPointContainer_EnumConnectionPoints   twapi::IConnectionPoint_Unadvise    twapi::IConnectionPoint_GetConnectionInterface  twapi::IConnectionPoint_Advise  twapi::IEnumVARIANT_Skip    twapi::IEnumVARIANT_Reset   twapi::IEnumVARIANT_Clone   twapi::IMoniker_GetDisplayName  twapi::IRecordInfo_RecordInit   twapi::IRecordInfo_RecordDestroy    twapi::IRecordInfo_RecordCreateCopy twapi::IRecordInfo_RecordCreate twapi::IRecordInfo_RecordCopy   twapi::IRecordInfo_RecordClear  twapi::IRecordInfo_IsMatchingType   twapi::IRecordInfo_GetTypeInfo  twapi::IRecordInfo_GetSize  twapi::IRecordInfo_GetName  twapi::IRecordInfo_GetGuid  twapi::IRecordInfo_GetField twapi::ITypeLib_GetTypeInfoOfGuid   twapi::ITypeLib_GetTypeInfo twapi::ITypeLib_GetTypeInfoType twapi::ITypeLib_GetTypeInfoCount    twapi::ITypeLib_GetDocumentation    twapi::ITypeInfo_GetImplTypeFlags   twapi::ITypeInfo_GetDocumentation   twapi::ITypeInfo_GetContainingTypeLib   twapi::ITypeInfo_GetTypeComp    twapi::ITypeInfo_GetRefTypeInfo twapi::ITypeInfo_GetRefTypeOfImplType   twapi::IDispatchEx_GetNextDispID    twapi::IDispatchEx_GetNameSpaceParent   twapi::IDispatchEx_GetMemberProperties  twapi::IDispatchEx_GetMemberName    twapi::IDispatchEx_GetDispID    twapi::IDispatch_GetTypeInfo    twapi::IDispatch_GetTypeInfoCount   twapi::IUnknown_AddRef  twapi::IUnknown_Release twapi::DuplicateHandle  twapi::SetHandleInformation twapi::GetHandleInformation twapi::Twapi_GetHandleInformation   twapi::Tcl_GetChannelHandle twapi::CryptGenRandom   twapi::CryptReleaseContext  twapi::CryptAcquireContext  twapi::DecryptMessage   twapi::EncryptMessage   twapi::VerifySignature  twapi::MakeSignature    twapi::QueryContextAttributes   twapi::ImpersonateSecurityContext   twapi::QuerySecurityContextToken    twapi::DeleteSecurityContext    twapi::AcceptSecurityContext    twapi::InitializeSecurityContext    twapi::FreeCredentialsHandle    twapi::AcquireCredentialsHandle twapi::EnumerateSecurityPackages    twapi::Twapi_Free_SEC_WINNT_AUTH_IDENTITY   twapi::Twapi_Allocate_SEC_WINNT_AUTH_IDENTITY   twapi::WaitForMultipleObjects   twapi::ReleaseSemaphore twapi::OpenSemaphore    twapi::CreateSemaphore  twapi::ReleaseMutex twapi::OpenMutex    twapi::CreateMutex  twapi::Twapi_WNetGetResourceInformation twapi::NetScheduleJobEnum   twapi::NetScheduleJobDel    twapi::NetScheduleJobAdd    twapi::NetScheduleJobGetInfo    twapi::NetGetDCName twapi::WNetGetUser  twapi::WNetGetUniversalName twapi::WNetCancelConnection2    twapi::Twapi_WNetUseConnection  twapi::NetSessionDel    twapi::NetSessionGetInfo    twapi::NetSessionEnum   twapi::NetFileClose twapi::NetFileGetInfo   twapi::NetFileEnum  twapi::NetConnectionEnum    twapi::NetShareSetInfo  twapi::NetShareGetInfo  twapi::Twapi_NetShareCheck  twapi::Twapi_NetShareEnum   twapi::NetShareDel  twapi::Twapi_NetUseGetInfo  twapi::NetUseEnum   twapi::NetShareAdd  twapi::Twapi_FormatExtendedUdpTable twapi::GetExtendedUdpTable  twapi::Twapi_FormatExtendedTcpTable twapi::GetExtendedTcpTable  twapi::GetBestInterface twapi::GetBestRoute twapi::Twapi_ResolveAddressAsync    twapi::Twapi_ResolveHostnameAsync   twapi::getaddrinfo  twapi::getnameinfo  twapi::SetTcpEntry  twapi::AllocateAndGetUdpExTableFromStack    twapi::AllocateAndGetTcpExTableFromStack    twapi::FlushIpNetTable  twapi::GetIpForwardTable    twapi::GetIpNetTable    twapi::GetIpAddrTable   twapi::GetIfTable   twapi::GetIfEntry   twapi::GetPerAdapterInfo    twapi::GetNumberOfInterfaces    twapi::GetInterfaceInfo twapi::GetAdapterIndex  twapi::GetAdaptersInfo  twapi::GetNetworkParams twapi::Twapi_DeviceChangeNotifyStop twapi::Twapi_DeviceChangeNotifyStart    twapi::DeviceIoControl  twapi::SetupDiGetDeviceInstanceId   twapi::SetupDiClassGuidsFromNameEx  twapi::SetupDiClassNameFromGuidEx   twapi::SetupDiGetDeviceInterfaceDetail  twapi::SetupDiEnumDeviceInterfaces  twapi::SetupDiGetDeviceRegistryProperty twapi::SetupDiEnumDeviceInfo    twapi::SetupDiGetClassDevsEx    twapi::SetupDiDestroyDeviceInfoList twapi::SetupDiCreateDeviceInfoListEx    twapi::SetThreadExecutionState  twapi::GetSystemPowerStatus twapi::Twapi_PowerNotifyStop    twapi::Twapi_PowerNotifyStart   twapi::GetDevicePowerState  twapi::SetSuspendState  twapi::DsGetDcName  twapi::WTSSendMessage   twapi::WTSQuerySessionInformation   twapi::WTSOpenServer    twapi::WTSLogoffSession twapi::WTSEnumerateSessions twapi::WTSEnumerateProcesses    twapi::WTSDisconnectSession twapi::WTSCloseServer   twapi::ProcessIdToSessionId twapi::Twapi_EnumPrinters_Level4    twapi::IScheduledWorkItem_GetWorkItemData   twapi::IScheduledWorkItem_GetRunTimes   twapi::IEnumWorkItems_Next  twapi::CreateScalableFontResource   twapi::RemoveFontResourceEx twapi::AddFontResourceEx    twapi::EnumDisplayMonitors  twapi::GetMonitorInfo   twapi::MonitorFromPoint twapi::MonitorFromRect  twapi::MonitorFromWindow    twapi::EnumDisplayDevices   twapi::GetDeviceCaps    twapi::GetObject    twapi::ReleaseDC    twapi::GetWindowDC  twapi::GetDC    twapi::PdhLookupPerfNameByIndex twapi::PdhValidatePath  twapi::PdhGetFormattedCounterValue  twapi::PdhCollectQueryData  twapi::PdhRemoveCounter twapi::PdhAddCounter    twapi::PdhCloseQuery    twapi::PdhOpenQuery twapi::PdhSetDefaultRealTimeDataSource  twapi::PdhBrowseCounters    twapi::PdhParseCounterPath  twapi::PdhMakeCounterPath   twapi::PdhEnumObjectItems   twapi::PdhEnumObjects   twapi::PdhConnectMachine    twapi::PdhGetDllVersion twapi::UnregisterConsoleEventNotifier   twapi::RegisterConsoleEventNotifier twapi::ReadConsole  twapi::SetConsoleActiveScreenBuffer twapi::WriteConsoleOutputCharacter  twapi::WriteConsole twapi::SetStdHandle twapi::SetConsoleWindowInfo twapi::SetConsoleTitle  twapi::SetConsoleTextAttribute  twapi::SetConsoleScreenBufferSize   twapi::SetConsoleOutputCP   twapi::SetConsoleMode   twapi::SetConsoleCursorPosition twapi::SetConsoleCP twapi::GetStdHandle twapi::GetNumberOfConsoleMouseButtons   twapi::GetNumberOfConsoleInputEvents    twapi::GetLargestConsoleWindowSize  twapi::GetConsoleWindow twapi::GetConsoleTitle  twapi::GetConsoleScreenBufferInfo   twapi::GetConsoleOutputCP   twapi::GetConsoleMode   twapi::GetConsoleCP twapi::GenerateConsoleCtrlEvent twapi::FreeConsole  twapi::FlushConsoleInputBuffer  twapi::FillConsoleOutputCharacter   twapi::FillConsoleOutputAttribute   twapi::CreateConsoleScreenBuffer    twapi::AllocConsole twapi::Twapi_IsEventLogFull twapi::GetOldestEventLogRecord  twapi::GetNumberOfEventLogRecords   twapi::ClearEventLog    twapi::BackupEventLog   twapi::CloseEventLog    twapi::ReadEventLog twapi::OpenBackupEventLog   twapi::OpenEventLog twapi::DeregisterEventSource    twapi::ReportEvent  twapi::RegisterEventSource  twapi::Twapi_StopServiceThread  twapi::Twapi_SetServiceStatus   twapi::Twapi_BecomeAService twapi::QueryServiceStatusEx twapi::CloseServiceHandle   twapi::EnumDependentServices    twapi::EnumServicesStatusEx twapi::EnumServicesStatus   twapi::ChangeServiceConfig  twapi::GetServiceDisplayName    twapi::GetServiceKeyName    twapi::QueryServiceConfig   twapi::QueryServiceStatus   twapi::ControlService   twapi::StartService twapi::DeleteService    twapi::CreateService    twapi::OpenService  twapi::QueryServiceLockStatus   twapi::UnlockServiceDatabase    twapi::LockServiceDatabase  twapi::OpenSCManager    twapi::SERVICE_STATUS   twapi::delete_SERVICE_STATUS    twapi::new_SERVICE_STATUS   twapi::SERVICE_STATUS_dwWaitHint_get    twapi::SERVICE_STATUS_dwWaitHint_set    twapi::SERVICE_STATUS_dwCheckPoint_get  twapi::SERVICE_STATUS_dwCheckPoint_set  twapi::SERVICE_STATUS_dwServiceSpecificExitCode_get twapi::SERVICE_STATUS_dwServiceSpecificExitCode_set twapi::SERVICE_STATUS_dwWin32ExitCode_get   twapi::SERVICE_STATUS_dwWin32ExitCode_set   twapi::SERVICE_STATUS_dwControlsAccepted_get    twapi::SERVICE_STATUS_dwControlsAccepted_set    twapi::SERVICE_STATUS_dwCurrentState_get    twapi::SERVICE_STATUS_dwCurrentState_set    twapi::SERVICE_STATUS_dwServiceType_get twapi::SERVICE_STATUS_dwServiceType_set twapi::Twapi_SHFileOperation    twapi::SHInvokePrinterCommand   twapi::Twapi_InvokeUrlShortcut  twapi::Twapi_ReadUrlShortcut    twapi::Twapi_WriteUrlShortcut   twapi::Twapi_ReadShortcut   twapi::Twapi_WriteShortcut  twapi::Twapi_GetShellVersion    twapi::TwapiThemeDefineValue    twapi::GetThemeFont twapi::GetThemeColor    twapi::GetCurrentThemeName  twapi::IsAppThemed  twapi::IsThemeActive    twapi::CloseThemeData   twapi::OpenThemeData    twapi::SHObjectProperties   twapi::SHGetPathFromIDList  twapi::SHGetSpecialFolderLocation   twapi::SHGetSpecialFolderPath   twapi::SHGetFolderPath  twapi::SystemTimeToVariantTime  twapi::VariantTimeToSystemTime  twapi::OleRun   twapi::CreateFileMoniker    twapi::CreateBindCtx    twapi::IEnumVARIANT_Next    twapi::IRecordInfo_GetFieldNames    twapi::GetRecordInfoFromGuids   twapi::GetRecordInfoFromTypeInfo    twapi::ITypeLib_GetLibAttr  twapi::QueryPathOfRegTypeLib    twapi::UnRegisterTypeLib    twapi::RegisterTypeLib  twapi::LoadRegTypeLib   twapi::LoadTypeLibEx    twapi::ITypeComp_Bind   twapi::ITypeInfo_GetNames   twapi::ITypeInfo_GetIDsOfNames  twapi::ITypeInfo_GetFuncDesc    twapi::ITypeInfo_GetVarDesc twapi::ITypeInfo_GetTypeAttr    twapi::ConvertToIUnknown    twapi::IDispatch_GetIDsOfNames  twapi::Twapi_GetObjectIDispatch twapi::IUnknown_QueryInterface  twapi::GetActiveObject  twapi::Twapi_CoCreateInstance   twapi::CLSIDFromString  twapi::ProgIDFromCLSID  twapi::CLSIDFromProgID  twapi::IIDFromString    twapi::GetOEMCP twapi::GetACP   twapi::GetLocaleInfo    twapi::GetThreadLocale  twapi::GetCurrencyFormat    twapi::GetNumberFormat  twapi::GetSystemDefaultUILanguage   twapi::GetUserDefaultUILanguage twapi::GetSystemDefaultLCID twapi::GetUserDefaultLCID   twapi::GetSystemDefaultLangID   twapi::GetUserDefaultLangID twapi::MonitorClipboardStop twapi::MonitorClipboardStart    twapi::RegisterClipboardFormat  twapi::IsClipboardFormatAvailable   twapi::GetClipboardOwner    twapi::GetClipboardFormatName   twapi::Twapi_EnumClipboardFormats   twapi::GetOpenClipboardWindow   twapi::GetClipboardData twapi::SetClipboardData twapi::EmptyClipboard   twapi::CloseClipboard   twapi::OpenClipboard    twapi::MapVirtualKey    twapi::GetKeyState  twapi::GetAsyncKeyState twapi::GetLastInputInfo twapi::GetDoubleClickTime   twapi::SetThreadDesktop twapi::GetThreadDesktop twapi::SwitchDesktop    twapi::CloseDesktop twapi::OpenInputDesktop twapi::CreateDesktop    twapi::OpenDesktop  twapi::EnumDesktops twapi::EnumDesktopWindows   twapi::EnumWindowStations   twapi::CloseWindowStation   twapi::CreateWindowStation  twapi::OpenWindowStation    twapi::SetProcessWindowStation  twapi::GetProcessWindowStation  twapi::SetLayeredWindowAttributes   twapi::CreateWindowEx   twapi::BlockInput   twapi::UnregisterHotKey twapi::RegisterHotKey   twapi::SetCursorPos twapi::GetCursorPos twapi::PlaySound    twapi::Twapi_SendUnicode    twapi::SendInput    twapi::ArrangeIconicWindows twapi::AttachThreadInput    twapi::SetCaretPos  twapi::GetCaretPos  twapi::ShowCaret    twapi::HideCaret    twapi::SetCaretBlinkTime    twapi::GetCaretBlinkTime    twapi::MessageBeep  twapi::Beep twapi::FlashWindow  twapi::UpdateWindow twapi::MoveWindow   twapi::InvalidateRect   twapi::WindowFromPoint  twapi::SetWindowPlacement   twapi::GetWindowPlacement   twapi::GetWindowInfo    twapi::GetWindowRect    twapi::GetClientRect    twapi::SetFocus twapi::PostMessage  twapi::SendNotifyMessage    twapi::SendMessageTimeout   twapi::IsChild  twapi::IsWindowEnabled  twapi::IsWindowUnicode  twapi::IsWindow twapi::IsWindowVisible  twapi::IsZoomed twapi::IsIconic twapi::DestroyWindow    twapi::CloseWindow  twapi::OpenIcon twapi::EnableWindow twapi::ShowOwnedPopups  twapi::ShowWindowAsync  twapi::ShowWindow   twapi::SetWindowText    twapi::GetWindowText    twapi::GetGUIThreadInfo twapi::GUITHREADINFO    twapi::delete_GUITHREADINFO twapi::new_GUITHREADINFO    twapi::GUITHREADINFO_rcCaret_get    twapi::GUITHREADINFO_rcCaret_set    twapi::GUITHREADINFO_hwndCaret_get  twapi::GUITHREADINFO_hwndCaret_set  twapi::GUITHREADINFO_hwndMoveSize_get   twapi::GUITHREADINFO_hwndMoveSize_set   twapi::GUITHREADINFO_hwndMenuOwner_get  twapi::GUITHREADINFO_hwndMenuOwner_set  twapi::GUITHREADINFO_hwndCapture_get    twapi::GUITHREADINFO_hwndCapture_set    twapi::GUITHREADINFO_hwndFocus_get  twapi::GUITHREADINFO_hwndFocus_set  twapi::GUITHREADINFO_hwndActive_get twapi::GUITHREADINFO_hwndActive_set twapi::GUITHREADINFO_flags_get  twapi::GUITHREADINFO_flags_set  twapi::GUITHREADINFO_cbSize_get twapi::GUITHREADINFO_cbSize_set twapi::GetWindowThreadProcessId twapi::SetWindowPos twapi::SetWindowLong    twapi::GetWindowLong    twapi::GetClassName twapi::RealGetWindowClass   twapi::FindWindowEx twapi::FindWindow   twapi::GetActiveWindow  twapi::SetActiveWindow  twapi::SetForegroundWindow  twapi::GetForegroundWindow  twapi::GetShellWindow   twapi::GetDesktopWindow twapi::GetWindow    twapi::GetAncestor  twapi::GetParent    twapi::EnumChildWindows twapi::EnumWindows  twapi::POINT    twapi::delete_POINT twapi::new_POINT    twapi::POINT_y_get  twapi::POINT_y_set  twapi::POINT_x_get  twapi::POINT_x_set  twapi::WINDOWPLACEMENT  twapi::delete_WINDOWPLACEMENT   twapi::new_WINDOWPLACEMENT  twapi::WINDOWPLACEMENT_rcNormalPosition_get twapi::WINDOWPLACEMENT_rcNormalPosition_set twapi::WINDOWPLACEMENT_ptMaxPosition_get    twapi::WINDOWPLACEMENT_ptMaxPosition_set    twapi::WINDOWPLACEMENT_ptMinPosition_get    twapi::WINDOWPLACEMENT_ptMinPosition_set    twapi::WINDOWPLACEMENT_showCmd_get  twapi::WINDOWPLACEMENT_showCmd_set  twapi::WINDOWPLACEMENT_flags_get    twapi::WINDOWPLACEMENT_flags_set    twapi::WINDOWPLACEMENT_length_get   twapi::WINDOWPLACEMENT_length_set   twapi::WINDOWINFO   twapi::delete_WINDOWINFO    twapi::new_WINDOWINFO   twapi::WINDOWINFO_wCreatorVersion_get   twapi::WINDOWINFO_wCreatorVersion_set   twapi::WINDOWINFO_atomWindowType_get    twapi::WINDOWINFO_atomWindowType_set    twapi::WINDOWINFO_cyWindowBorders_get   twapi::WINDOWINFO_cyWindowBorders_set   twapi::WINDOWINFO_cxWindowBorders_get   twapi::WINDOWINFO_cxWindowBorders_set   twapi::WINDOWINFO_dwWindowStatus_get    twapi::WINDOWINFO_dwWindowStatus_set    twapi::WINDOWINFO_dwExStyle_get twapi::WINDOWINFO_dwExStyle_set twapi::WINDOWINFO_dwStyle_get   twapi::WINDOWINFO_dwStyle_set   twapi::WINDOWINFO_rcClient_get  twapi::WINDOWINFO_rcClient_set  twapi::WINDOWINFO_rcWindow_get  twapi::WINDOWINFO_rcWindow_set  twapi::WINDOWINFO_cbSize_get    twapi::WINDOWINFO_cbSize_set    twapi::RECT twapi::delete_RECT  twapi::new_RECT twapi::RECT_bottom_get  twapi::RECT_bottom_set  twapi::RECT_right_get   twapi::RECT_right_set   twapi::RECT_top_get twapi::RECT_top_set twapi::RECT_left_get    twapi::RECT_left_set    twapi::SetFileTime  twapi::GetFileTime  twapi::MoveFileEx   twapi::GetFileType  twapi::Twapi_VerQueryValue_TRANSLATIONS twapi::Twapi_VerQueryValue_STRING   twapi::Twapi_VerQueryValue_FIXEDFILEINFO    twapi::VerLanguageName  twapi::Twapi_FreeFileVersionInfo    twapi::Twapi_GetFileVersionInfo twapi::UnregisterDirChangeNotifier  twapi::RegisterDirChangeNotifier    twapi::CreateFile   twapi::GetVolumePathName    twapi::GetVolumeNameForVolumeMountPoint twapi::DeleteVolumeMountPoint   twapi::SetVolumeMountPoint  twapi::FindVolumeMountPointClose    twapi::FindNextVolumeMountPoint twapi::FindFirstVolumeMountPoint    twapi::FindVolumeClose  twapi::FindNextVolume   twapi::FindFirstVolume  twapi::DefineDosDevice  twapi::QueryDosDevice   twapi::SetVolumeLabel   twapi::GetVolumeInformation twapi::GetLogicalDrives twapi::GetDriveType twapi::GetDiskFreeSpaceEx   twapi::Twapi_GetProcessList twapi::CommandLineToArgv    twapi::GetCommandLineW  twapi::GetExitCodeProcess   twapi::ReadProcessMemory    twapi::Twapi_NtQueryInformationThreadBasicInformation   twapi::Twapi_NtQueryInformationProcessBasicInformation  twapi::GetThreadPriority    twapi::SetThreadPriority    twapi::GetPriorityClass twapi::SetPriorityClass twapi::SuspendThread    twapi::ResumeThread twapi::CreateProcessAsUser  twapi::CreateProcess    twapi::WaitForInputIdle twapi::OpenThread   twapi::GetCurrentThread twapi::GetCurrentThreadId   twapi::EnumDeviceDrivers    twapi::EnumProcessModules   twapi::EnumProcesses    twapi::GetModuleInformation twapi::GetDeviceDriverBaseName  twapi::GetDeviceDriverFileName  twapi::GetModuleBaseName    twapi::GetModuleFileNameEx  twapi::TerminateProcess twapi::GetCurrentProcess    twapi::OpenProcess  twapi::Wow64RevertWow64FsRedirection    twapi::Wow64DisableWow64FsRedirection   twapi::Wow64EnableWow64FsRedirection    twapi::SystemTimeToFileTime twapi::FileTimeToSystemTime twapi::GetTickCount twapi::GetSystemTimeAsFileTime  twapi::GetProfileType   twapi::UnloadUserProfile    twapi::Twapi_LoadUserProfile    twapi::Twapi_SystemPagefileInformation  twapi::Twapi_SystemProcessorTimes   twapi::SystemParametersInfo twapi::GlobalMemoryStatus   twapi::GetPrivateProfileSectionNames    twapi::GetPrivateProfileSection twapi::WriteProfileString   twapi::WritePrivateProfileString    twapi::GetProfileString twapi::GetPrivateProfileString  twapi::GetProfileInt    twapi::GetPrivateProfileInt twapi::GetSystemInfo    twapi::FreeLibrary  twapi::LoadLibraryEx    twapi::FormatMessageFromString  twapi::FormatMessageFromModule  twapi::ExpandEnvironmentStrings twapi::AbortSystemShutdown  twapi::InitiateSystemShutdown   twapi::GetComputerNameEx    twapi::GetComputerName  twapi::GetVersionEx twapi::OSVERSIONINFOEXW twapi::delete_OSVERSIONINFOEXW  twapi::new_OSVERSIONINFOEXW twapi::OSVERSIONINFOEXW_wReserved_get   twapi::OSVERSIONINFOEXW_wReserved_set   twapi::OSVERSIONINFOEXW_wProductType_get    twapi::OSVERSIONINFOEXW_wProductType_set    twapi::OSVERSIONINFOEXW_wSuiteMask_get  twapi::OSVERSIONINFOEXW_wSuiteMask_set  twapi::OSVERSIONINFOEXW_wServicePackMinor_get   twapi::OSVERSIONINFOEXW_wServicePackMinor_set   twapi::OSVERSIONINFOEXW_wServicePackMajor_get   twapi::OSVERSIONINFOEXW_wServicePackMajor_set   twapi::OSVERSIONINFOEXW_szCSDVersion_get    twapi::OSVERSIONINFOEXW_szCSDVersion_set    twapi::OSVERSIONINFOEXW_dwPlatformId_get    twapi::OSVERSIONINFOEXW_dwPlatformId_set    twapi::OSVERSIONINFOEXW_dwBuildNumber_get   twapi::OSVERSIONINFOEXW_dwBuildNumber_set   twapi::OSVERSIONINFOEXW_dwMinorVersion_get  twapi::OSVERSIONINFOEXW_dwMinorVersion_set  twapi::OSVERSIONINFOEXW_dwMajorVersion_get  twapi::OSVERSIONINFOEXW_dwMajorVersion_set  twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_get twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_set twapi::Twapi_LsaQueryInformationPolicy  twapi::LsaGetLogonSessionData   twapi::LsaEnumerateLogonSessions    twapi::Twapi_LsaRemoveAccountRights twapi::Twapi_LsaAddAccountRights    twapi::Twapi_LsaEnumerateAccountsWithUserRight  twapi::Twapi_LsaEnumerateAccountRights  twapi::LsaClose twapi::Twapi_LsaOpenPolicy  twapi::GetUserNameEx    twapi::LockWorkStation  twapi::ExitWindowsEx    twapi::AllocateLocallyUniqueId  twapi::UuidCreateNil    twapi::UuidCreate   twapi::DuplicateTokenEx twapi::SetThreadToken   twapi::ImpersonateSelf  twapi::RevertToSelf twapi::ImpersonateLoggedOnUser  twapi::LogonUser    twapi::SetSecurityInfo  twapi::Twapi_GetSecurityInfo    twapi::SetNamedSecurityInfo twapi::Twapi_GetNamedSecurityInfo   twapi::IsValidSecurityDescriptor    twapi::IsValidAcl   twapi::Twapi_InitializeSecurityDescriptor   twapi::Twapi_NetLocalGroupDelMember twapi::Twapi_NetLocalGroupAddMember twapi::NetGroupDelUser  twapi::NetGroupAddUser  twapi::NetLocalGroupDel twapi::NetGroupDel  twapi::NetLocalGroupAdd twapi::NetGroupAdd  twapi::Twapi_AdjustTokenPrivileges  twapi::Twapi_PrivilegeCheck twapi::IsValidSid   twapi::LookupPrivilegeValue twapi::LookupPrivilegeDisplayName   twapi::LookupPrivilegeName  twapi::Twapi_NetUserSetInfo_home_dir_drive  twapi::Twapi_NetUserSetInfo_profile twapi::Twapi_NetUserSetInfo_country_code    twapi::Twapi_NetUserSetInfo_acct_expires    twapi::Twapi_NetUserSetInfo_full_name   twapi::Twapi_NetUserSetInfo_auth_flags  twapi::Twapi_NetUserSetInfo_script_path twapi::Twapi_NetUserSetInfo_flags   twapi::Twapi_NetUserSetInfo_comment twapi::Twapi_NetUserSetInfo_home_dir    twapi::Twapi_NetUserSetInfo_priv    twapi::Twapi_NetUserSetInfo_password    twapi::Twapi_NetUserSetInfo_name    twapi::NetLocalGroupGetInfo twapi::NetGroupGetInfo  twapi::NetUserGetInfo   twapi::NetGroupGetUsers twapi::NetLocalGroupGetMembers  twapi::NetUserGetLocalGroups    twapi::NetUserGetGroups twapi::NetLocalGroupEnum    twapi::NetGroupEnum twapi::Twapi_NetUserEnum    twapi::NetUserDel   twapi::NetUserAdd   twapi::Twapi_SetTokenOwner  twapi::Twapi_SetTokenPrimaryGroup   twapi::GetTokenInformation  twapi::LookupAccountSid twapi::LookupAccountName    twapi::TwapiGetSidStringRep twapi::OpenThreadToken  twapi::OpenProcessToken twapi::free twapi::malloc   twapi::CastToHANDLE twapi::CloseHandle  twapi::GlobalSize   twapi::GlobalUnlock twapi::GlobalLock   twapi::GlobalFree   twapi::GlobalReAlloc    twapi::GlobalAlloc  twapi::Twapi_WriteMemoryUnicode twapi::Twapi_WriteMemoryChars   twapi::Twapi_WriteMemoryBinary  twapi::Twapi_WriteMemoryInt twapi::Twapi_ReadMemoryUnicode  twapi::Twapi_ReadMemoryChars    twapi::Twapi_ReadMemoryBinary   twapi::Twapi_ReadMemoryInt  twapi::win32_error  twapi::Twapi_MapWindowsErrorToString    twapi::Twapi_AddressToPointer   twapi::ADDRESS_LITERAL2HANDLE   twapi::HANDLE2ADDRESS_LITERAL   SERVICE_STATUS  -dwWaitHint -dwCheckPoint   -dwServiceSpecificExitCode  -dwWin32ExitCode    -dwControlsAccepted -dwCurrentState -dwServiceType  GUITHREADINFO   -rcCaret    -hwndCaret  -hwndMoveSize   -hwndMenuOwner  -hwndCapture    -hwndFocus  -hwndActive POINT   -y  -x  WINDOWPLACEMENT -rcNormalPosition   -ptMaxPosition  -ptMinPosition  -showCmd    -flags  -length WINDOWINFO  -wCreatorVersion    -atomWindowType -cyWindowBorders    -cxWindowBorders    -dwWindowStatus -dwExStyle  -dwStyle    -rcClient   -rcWindow   -cbSize RECT    -bottom -right  -top    -left   OSVERSIONINFOEXW    -wReserved  -wProductType   -wSuiteMask -wServicePackMinor  -wServicePackMajor  -szCSDVersion   -dwPlatformId   -dwBuildNumber  -dwMinorVersion -dwMajorVersion -dwOSVersionInfoSize    userdefined record  lpwstr  lpstr   void    hresult uint    ui8 i8  ui4 ui2 i1  decimal ui1 iunknown    variant error   idispatch   bstr    date    cy  r8  r4  ptr i4  i2  No constructor available.   wrong # args.   -args   -this   swig: internal runtime error. No class object defined.  Type error. Expected a pointer  Type error. Expected    cget    NULL    Invalid method. Must be one of: configure cget -acquire -disown -delete Invalid attribute name. 0   1   configure   -thisown    -delete -disown -acquire    RtlNtStatusToDosError   ntdll.dll   Buffer too small    % s \ % s   Error looking up account name:  Unknown token information type  Unsupported token information type  Could not convert token source to LUID  Error getting security token information:   %.8x-%.8x    invalid     field.     user name   password    privilege level home directory  comment flags   script path Error adding user account:  Invalid or unsupported user or group information level specified    Could not retrieve global user or group information:    Internal error: bad type passed to TwapiNetUserOrGroupGetInfoHelper usri3_name  usri3_script_path   usri3_flags usri3_comment   usri3_home_dir  usri3_priv  usri3_password_age  usri3_password  usri3_code_page usri3_country_code  usri3_logon_server  usri3_num_logons    usri3_bad_pw_count  usri3_logon_hours   usri3_units_per_week    usri3_max_storage   usri3_acct_expires  usri3_last_logoff   usri3_last_logon    usri3_workstations  usri3_parms usri3_usr_comment   usri3_full_name usri3_auth_flags    usri3_password_expired  usri3_home_dir_drive    usri3_profile   usri3_primary_group_id  usri3_user_id   grpi3_name  grpi3_comment   grpi3_group_sid grpi2_group_id  grpi3_attributes    lgrpi1_comment  lgrpi1_name Could not allocate memory   Unsupported SECURITY_DESCRIPTOR version Could not allocate Tcl object   null    NULL ACE pointer    Could not enumerate account rights:     Could not enumerate accounts with specified privileges:     Could not add account rights:   Could not remove account rights:    Upn DnsDomainName   LogonServer LogonTime   Sid Session LogonType   AuthenticationPackage   LogonDomain UserName    LogonId Invalid or unsupported information class passed to Twapi_LsaQueryInformationPolicy  Access violation in FormatMessage. Most likely, number of supplied arguments do not match those in format string    Exception %x raised by FormatMessage    InterruptCount  InterruptTime   DpcTime UserTime    KernelTime  IdleTime    NtQuerySystemInformation    FileName    PeakUsed    TotalUsed   CurrentSize Wow64EnableWow64FsRedirection   kernel32.dll    Wow64DisableWow64FsRedirection  Wow64RevertWow64FsRedirection   ContextSwitchCount  WaitTime    WaitReason  State   StartAddress    Priority    ClientId.UniqueThread   ClientId.UniqueProcess  Threads IoCounters.OtherTransferCount   IoCounters.WriteTransferCount   IoCounters.ReadTransferCount    IoCounters.OtherOperationCount  IoCounters.WriteOperationCount  IoCounters.ReadOperationCount   VmCounters.PeakPagefileUsage    VmCounters.PagefileUsage    VmCounters.QuotaNonPagedPoolUsage   VmCounters.QuotaPeakNonPagedPoolUsage   VmCounters.QuotaPagedPoolUsage  VmCounters.QuotaPeakPagedPoolUsage  VmCounters.WorkingSetSize   VmCounters.PeakWorkingSetSize   VmCounters.PageFaultCount   VmCounters.VirtualSize  VmCounters.PeakVirtualSize  CreateTime  ThreadCount HandleCount ProcessName BasePriority    SessionId   InheritedFromProcessId  ProcessId   0x%X    error retrieving process/module/driver ids:     Invalid number of standard handles in STARTUPINFO structure _ _ n u l l _ _     Invalid number of list elements for STARTUPINFO structure   NtQueryInformationProcess   NtQueryInformationThread    dwFileDateLS    dwFileDateMS    dwFileSubtype   dwFileType  dwFileOS    dwFileFlags dwFileFlagsMask dwProductVersionLS  dwProductVersionMS  dwFileVersionLS dwFileVersionMS dwStrucVersion  dwSignature \   \ S t r i n g F i l e I n f o \ % s \ % s   %04x%04x    \VarFileInfo\Translation    Need to specify exactly 4 integers for a RECT structure Need to specify exactly 2 integers for a POINT structure    lfFaceName  lfPitchAndFamily    lfQuality   lfClipPrecision lfOutPrecision  lfCharSet   lfStrikeOut lfUnderline lfItalic    lfWeight    lfOrientation   lfEscapement    lfWidth lfHeight    Error sending input events:     Invalid value specified for virtual key code. Must be between 1 and 254 Invalid value specified for scan code. Must be between 1 and 65535  Missing field in event of type key  Missing field in event of type mouse    Unknown field event type    Invalid or empty element specified in input event list  input event type    mouse   key Invalid or unsupported VARTYPE token (%s)   <null pointer>  _p_%s   idldescType tdescAlias  wMinorVerNum    wMajorVerNum    wTypeFlags  cbAlignment cbSizeVft   cImplTypes  cVars   cFuncs  typekind    cbSizeInstance  lpstrSchema memidDestructor memidConstructor    dwReserved  lcid    guid    Internal error: ObjFromTYPEDESC: NULL TYPEDESC pointer  wVarFlags   varkind elemdescVar.paramdesc   elemdescVar.tdesc   oInst   lpvarValue  memid   lprgelemdescParam   lprgscode   elemdescFunc.paramdesc  elemdescFunc.tdesc  wFuncFlags  oVft    cParamsOpt  cParams callconv    invkind funckind    wLibFlags   syskind Internal error while constructing referenced VARIANT parameter  Insufficient memory Missing value and no default for IDispatch invoke parameter Unknown parameter modifiers out in  Unsupported or invalid type information format in parameter Invalid or unsupported VARTYPE (%d) funcdesc    vardesc typecomp    Unsupported ITypeComp desckind value    %u.%u.%u    shell32.dll SHGetSpecialFolderPathW SHGetFolderPathW    SHObjectProperties  Invalid theme symbol '  TMT_FONT    TMT_GLYPHTYPE   TMT_BLENDCOLOR  TMT_ACCENTCOLORHINT TMT_BORDERCOLORHINT TMT_FILLCOLORHINT   TMT_GLYPHTRANSPARENTCOLOR   TMT_GLYPHTEXTCOLOR  TMT_TEXTSHADOWCOLOR TMT_TEXTBORDERCOLOR TMT_GLOWCOLOR   TMT_SHADOWCOLOR TMT_GRADIENTCOLOR5  TMT_GRADIENTCOLOR4  TMT_GRADIENTCOLOR3  TMT_GRADIENTCOLOR2  TMT_GRADIENTCOLOR1  TMT_TRANSPARENTCOLOR    TMT_EDGEFILLCOLOR   TMT_EDGEDKSHADOWCOLOR   TMT_EDGESHADOWCOLOR TMT_EDGEHIGHLIGHTCOLOR  TMT_EDGELIGHTCOLOR  TMT_TEXTCOLOR   TMT_FILLCOLOR   TMT_BORDERCOLOR VTS_PUSHED  VTS_NORMAL  VTS_HOT VTS_DISABLED    WP_VERTTHUMB    VSS_PUSHED  VSS_NORMAL  VSS_HOT VSS_DISABLED    WP_VERTSCROLL   WP_SYSBUTTON    WP_SMALLMINCAPTION  WP_SMALLMAXCAPTION  WP_SMALLFRAMERIGHTSIZINGTEMPLATE    WP_SMALLFRAMERIGHT  WP_SMALLFRAMELEFTSIZINGTEMPLATE WP_SMALLFRAMELEFT   WP_SMALLFRAMEBOTTOMSIZINGTEMPLATE   WP_SMALLFRAMEBOTTOM WP_SMALLCLOSEBUTTON WP_SMALLCAPTIONSIZINGTEMPLATE   WP_SMALLCAPTION WP_RESTOREBUTTON    MNCS_INACTIVE   MNCS_DISABLED   MNCS_ACTIVE WP_MINCAPTION   WP_MINBUTTON    SBS_PUSHED  SBS_NORMAL  SBS_HOT SBS_DISABLED    WP_MDISYSBUTTON RBS_PUSHED  RBS_NORMAL  RBS_HOT RBS_DISABLED    WP_MDIRESTOREBUTTON MINBS_PUSHED    MINBS_NORMAL    MINBS_HOT   MINBS_DISABLED  WP_MDIMINBUTTON WP_MDIHELPBUTTON    WP_MDICLOSEBUTTON   MXCS_INACTIVE   MXCS_DISABLED   MXCS_ACTIVE WP_MAXCAPTION   MAXBS_PUSHED    MAXBS_NORMAL    MAXBS_HOT   MAXBS_DISABLED  HTS_PUSHED  HTS_NORMAL  HTS_HOT HTS_DISABLED    WP_HORZTHUMB    HSS_PUSHED  HSS_NORMAL  HSS_HOT HSS_DISABLED    WP_HORZSCROLL   HBS_PUSHED  HBS_NORMAL  HBS_HOT HBS_DISABLED    WP_HELPBUTTON   WP_FRAMERIGHTSIZINGTEMPLATE WP_FRAMERIGHT   WP_FRAMELEFTSIZINGTEMPLATE  WP_FRAMELEFT    WP_FRAMEBOTTOMSIZINGTEMPLATE    FS_INACTIVE FS_ACTIVE   WP_FRAMEBOTTOM  WP_DIALOG   CBS_PUSHED  CBS_NORMAL  CBS_HOT CBS_DISABLED    WP_CLOSEBUTTON  WP_CAPTIONSIZINGTEMPLATE    CS_INACTIVE CS_DISABLED CS_ACTIVE   WP_CAPTION  TREIS_SELECTEDNOTFOCUS  TREIS_SELECTED  TREIS_NORMAL    TREIS_HOT   TREIS_DISABLED  TVP_TREEITEM    GLPS_OPENED GLPS_CLOSED TVP_GLYPH   TVP_BRANCH  TNP_BACKGROUND  TNP_ANIMBACKGROUND  TRVS_NORMAL TKP_TRACKVERT   TRS_NORMAL  TKP_TRACK   TSVS_NORMAL TKP_TICSVERT    TSS_NORMAL  TKP_TICS    TUVS_PRESSED    TUVS_NORMAL TUVS_HOT    TUVS_FOCUSED    TUVS_DISABLED   TKP_THUMBVERT   TUTS_PRESSED    TUTS_NORMAL TUTS_HOT    TUTS_FOCUSED    TUTS_DISABLED   TKP_THUMBTOP    TUVRS_PRESSED   TUVRS_NORMAL    TUVRS_HOT   TUVRS_FOCUSED   TUVRS_DISABLED  TKP_THUMBRIGHT  TUVLS_PRESSED   TUVLS_NORMAL    TUVLS_HOT   TUVLS_FOCUSED   TUVLS_DISABLED  TKP_THUMBLEFT   TUBS_PRESSED    TUBS_NORMAL TUBS_HOT    TUBS_FOCUSED    TUBS_DISABLED   TKP_THUMBBOTTOM TUS_PRESSED TUS_NORMAL  TUS_HOT TUS_FOCUSED TUS_DISABLED    TKP_THUMB   TTP_STANDARDTITLE   TTSS_NORMAL TTSS_LINK   TTP_STANDARD    TTCS_PRESSED    TTCS_NORMAL TTCS_HOT    TTP_CLOSE   TTP_BALLOONTITLE    TTBS_NORMAL TTBS_LINK   TTP_BALLOON TP_SEPARATORVERT    TP_SEPARATOR    TP_SPLITBUTTONDROPDOWN  TP_SPLITBUTTON  TP_DROPDOWNBUTTON   TS_PRESSED  TS_NORMAL   TS_HOTCHECKED   TS_HOT  TS_DISABLED TS_CHECKED  TP_BUTTON   TBP_SIZINGBARTOP    TBP_SIZINGBARRIGHT  TBP_SIZINGBARBOTTOM TBP_BACKGROUNDTOP   TBP_BACKGROUNDRIGHT TBP_BACKGROUNDLEFT  TBP_BACKGROUNDBOTTOM    TDP_FLASHBUTTONGROUPMENU    TDP_FLASHBUTTON TDP_GROUPCOUNT  TTIRES_SELECTED TTIRES_NORMAL   TTIRES_HOT  TTIRES_FOCUSED  TTIRES_DISABLED TABP_TOPTABITEMRIGHTEDGE    TTILES_SELECTED TTILES_NORMAL   TTILES_HOT  TTILES_FOCUSED  TTILES_DISABLED TABP_TOPTABITEMLEFTEDGE TTIBES_SELECTED TTIBES_NORMAL   TTIBES_HOT  TTIBES_FOCUSED  TTIBES_DISABLED TABP_TOPTABITEMBOTHEDGE TTIS_SELECTED   TTIS_NORMAL TTIS_HOT    TTIS_FOCUSED    TTIS_DISABLED   TABP_TOPTABITEM TIRES_SELECTED  TIRES_NORMAL    TIRES_HOT   TIRES_FOCUSED   TIRES_DISABLED  TABP_TABITEMRIGHTEDGE   TILES_SELECTED  TILES_NORMAL    TILES_HOT   TILES_FOCUSED   TILES_DISABLED  TABP_TABITEMLEFTEDGE    TIBES_SELECTED  TIBES_NORMAL    TIBES_HOT   TIBES_FOCUSED   TIBES_DISABLED  TABP_TABITEMBOTHEDGE    TIS_SELECTED    TIS_NORMAL  TIS_HOT TIS_FOCUSED TIS_DISABLED    TABP_TABITEM    TABP_PANE   TABP_BODY   SP_GRIPPERPANE  SP_PANE SP_GRIPPER  SPP_USERPICTURE SPP_USERPANE    SPP_PROGLISTSEPARATOR   SPP_PROGLIST    SPP_PREVIEW SPP_PLACESLISTSEPARATOR SPP_PLACESLIST  SPS_PRESSED SPS_NORMAL  SPS_HOT SPP_MOREPROGRAMSARROW   SPP_MOREPROGRAMS    SPLS_PRESSED    SPLS_NORMAL SPLS_HOT    SPP_LOGOFFBUTTONS   SPP_LOGOFF  SPNP_UPHORZ SPNP_UP SPNP_DOWNHORZ   SPNP_DOWN   SZB_RIGHTALIGN  SZB_LEFTALIGN   SBP_SIZEBOX SBP_UPPERTRACKVERT  SBP_UPPERTRACKHORZ  SBP_THUMBBTNVERT    SBP_THUMBBTNHORZ    SBP_LOWERTRACKVERT  SCRBS_PRESSED   SCRBS_NORMAL    SCRBS_HOT   SCRBS_DISABLED  SBP_LOWERTRACKHORZ  SBP_GRIPPERVERT SBP_GRIPPERHORZ ABS_RIGHTPRESSED    ABS_RIGHTNORMAL ABS_RIGHTHOT    ABS_RIGHTDISABLED   ABS_LEFTPRESSED ABS_LEFTNORMAL  ABS_LEFTHOT ABS_LEFTDISABLED    ABS_UPPRESSED   ABS_UPNORMAL    ABS_UPHOT   ABS_UPDISABLED  ABS_DOWNPRESSED ABS_DOWNNORMAL  ABS_DOWNHOT ABS_DOWNDISABLED    SBP_ARROWBTN    RP_GRIPPERVERT  RP_GRIPPER  RP_CHEVRONVERT  CHEVS_PRESSED   CHEVS_NORMAL    CHEVS_HOT   RP_CHEVRON  RP_BAND PP_CHUNKVERT    PP_CHUNK    PP_BARVERT  PP_BAR  UPHZS_PRESSED   UPHZS_NORMAL    UPHZS_HOT   UPHZS_DISABLED  PGRP_UPHORZ UPS_PRESSED UPS_NORMAL  UPS_HOT UPS_DISABLED    PGRP_UP DNHZS_PRESSED   DNHZS_NORMAL    DNHZS_HOT   DNHZS_DISABLED  PGRP_DOWNHORZ   DNS_PRESSED DNS_NORMAL  DNS_HOT DNS_DISABLED    PGRP_DOWN   MDP_SEPERATOR   MDS_PRESSED MDS_NORMAL  MDS_HOTCHECKED  MDS_HOT MDS_DISABLED    MDS_CHECKED MDP_NEWAPPBUTTON    MP_SEPARATOR    MP_MENUITEM MP_MENUDROPDOWN MP_CHEVRON  MP_MENUBARITEM  MS_SELECTED MS_NORMAL   MS_DEMOTED  MP_MENUBARDROPDOWN  LVP_LISTSORTEDDETAIL    LIS_SELECTEDNOTFOCUS    LIS_SELECTED    LIS_NORMAL  LIS_HOT LIS_DISABLED    LVP_LISTITEM    LVP_LISTGROUP   LVP_LISTDETAIL  LVP_EMPTYTEXT   HSAS_SORTEDUP   HSAS_SORTEDDOWN HP_HEADERSORTARROW  HIRS_PRESSED    HIRS_NORMAL HIRS_HOT    HP_HEADERITEMRIGHT  HILS_PRESSED    HILS_NORMAL HILS_HOT    HP_HEADERITEMLEFT   HIS_PRESSED HIS_NORMAL  HIS_HOT HP_HEADERITEM   EBP_SPECIALGROUPHEAD    EBSGE_PRESSED   EBSGE_NORMAL    EBSGE_HOT   EBP_SPECIALGROUPEXPAND  EBSGC_PRESSED   EBSGC_NORMAL    EBSGC_HOT   EBP_SPECIALGROUPCOLLAPSE    EBP_SPECIALGROUPBACKGROUND  EBP_NORMALGROUPHEAD EBNGE_PRESSED   EBNGE_NORMAL    EBNGE_HOT   EBP_NORMALGROUPEXPAND   EBNGC_PRESSED   EBNGC_NORMAL    EBNGC_HOT   EBP_NORMALGROUPCOLLAPSE EBP_NORMALGROUPBACKGROUND   EBM_PRESSED EBM_NORMAL  EBM_HOT EBP_IEBARMENU   EBHP_SELECTEDPRESSED    EBHP_SELECTEDNORMAL EBHP_SELECTEDHOT    EBHP_PRESSED    EBHP_NORMAL EBHP_HOT    EBP_HEADERPIN   EBHC_PRESSED    EBHC_NORMAL EBHC_HOT    EBP_HEADERCLOSE EBP_HEADERBACKGROUND    ETS_SELECTED    ETS_READONLY    ETS_NORMAL  ETS_HOT ETS_FOCUSED ETS_DISABLED    ETS_ASSIST  EP_EDITTEXT EP_CARET    CBXS_PRESSED    CBXS_NORMAL CBXS_HOT    CBXS_DISABLED   CP_DROPDOWNBUTTON   CLS_NORMAL  CLP_TIME    BP_USERBUTTON   RBS_UNCHECKEDPRESSED    RBS_UNCHECKEDNORMAL RBS_UNCHECKEDHOT    RBS_UNCHECKEDDISABLED   RBS_CHECKEDPRESSED  RBS_CHECKEDNORMAL   RBS_CHECKEDHOT  RBS_CHECKEDDISABLED BP_RADIOBUTTON  PBS_PRESSED PBS_NORMAL  PBS_HOT PBS_DISABLED    PBS_DEFAULTED   BP_PUSHBUTTON   GBS_NORMAL  GBS_DISABLED    BP_GROUPBOX CBS_UNCHECKEDPRESSED    CBS_UNCHECKEDNORMAL CBS_UNCHECKEDHOT    CBS_UNCHECKEDDISABLED   CBS_MIXEDPRESSED    CBS_MIXEDNORMAL CBS_MIXEDHOT    CBS_MIXEDDISABLED   CBS_CHECKEDPRESSED  CBS_CHECKEDNORMAL   CBS_CHECKEDHOT  CBS_CHECKEDDISABLED BP_CHECKBOX -workdir    -showcmd    -path   -idl    -iconpath   -iconindex  -hotkey -desc   OpenThemeData   uxtheme.dll CloseThemeData  IsThemeActive   IsAppThemed GetCurrentThemeName #%2.2x%2.2x%2.2x    GetThemeColor   GetThemeFont    SHFileOperation failed  dwServiceFlags  dwProcessId dwWaitHint  dwCheckPoint    dwServiceSpecificExitCode   dwWin32ExitCode dwControlsAccepted  dwCurrentState  dwServiceType   Attempt to read more than 1024 console characters   C   error retrieving performance counter and instance names:    szCounterName   dwInstanceIndex szParentInstance    szInstanceName  szObjectName    szMachineName   Error (0x%x/0x%x) retrieving counter value:     Invalid PDH counter format value    0x%x    wRandomMinutesInterval  Reserved2   type    rgFlags MinutesInterval MinutesDuration wStartMinute    wStartHour  wEndDay wEndMonth   wEndYear    wBeginDay   wBeginMonth wBeginYear  Reserved1   Unknown TASK_TRIGGER field '    Invalid task trigger type format    Invalid TASK_TRIGGER format - must have even number of elements success disabled    notriggers  oneventonly Attributes  pServerName pPrinterName    pUserSid    pProcessName    Could not enumerate terminal server processes.  pWinStationName Could not enumerate terminal server sessions.   Could not query terminal session information.   ClientSiteName  DcSiteName  Flags   DnsForestName   DomainName  DomainGuid  DomainControllerAddressType DomainControllerAddress DomainControllerName    GetOwnerModuleFromTcpEntry  iphlpapi.dll    GetOwnerModuleFromUdpEntry  No adapter information exists for the local computer    No adapter information exists for the specified adapter GetExtendedTcpTable GetExtendedUdpTable AllocateAndGetTcpExTableFromStack   AllocateAndGetUdpExTableFromStack   \wship6 \ws2_32 ŒPZ€PÆ_pPRZfreeaddrinfo    getnameinfo getaddrinfo tcp udp %u  65535   Invalid network share current connections parameter Invalid network share path parameter    Invalid network share password parameter    Invalid network share security descriptor parameter Invalid network share parameter Invalid network share maximum connections parameter Invalid network share name parameter    Invalid network share type parameter    Invalid network share remark parameter  Invalid network share permissions parameter Invalid or unsupported share information level specified    Could not retrieve share information:   Invalid info level for SHARE_INFO structure lpProvider  lpComment   lpRemoteName    lpLocalName dwUsage dwDisplayType   dwType  dwScope ui2_domainname  ui2_username    ui2_usecount    ui2_refcount    ui2_asg_type    ui2_status  ui2_password    ui2_remote  ui2_local   Invalid level specified.    cname   user_flags  idle_time   time    num_opens   username    cltype_name transport   id  netname num_users   pathname    num_locks   permissions Invalid security handle format  Comment Name    cbMaxToken  wRPCID  wVersion    fCapabilities   Invalid SecBuffer format    ok  continue    complete    complete_and_continue   incomplete_message  Unsupported QuerySecurityContext attribute id   Too many random bytes requested.    NtQueryObject   NtQueryInformationFile  Could not get object name information:  Could not get object type information:  Could not get basic object information:     < u n k n o w n >   Error getting channel handle    Unknown channel o:twapi::HANDLE2ADDRESS_LITERALh    Wrong # args.    argument   %d  Wrong # args.   Searching %s
   o:twapi::ADDRESS_LITERAL2HANDLEaddr     l:twapi::Twapi_AddressToPointeraddr     l:twapi::Twapi_MapWindowsErrorToStringerror     l|s:twapi::win32_errorerror DEFAULT_EMPTY_STRING    oi:twapi::Twapi_ReadMemoryIntbufP offset    oii:twapi::Twapi_ReadMemoryBinarybufP offset len    oi|i:twapi::Twapi_ReadMemoryCharsbufP offset DEFAULT_MINUS_ONE  oi|i:twapi::Twapi_ReadMemoryUnicodebufP offset DEFAULT_MINUS_ONE    oiii:twapi::Twapi_WriteMemoryIntbufP offset buf_size val    oiio:twapi::Twapi_WriteMemoryBinarybufP offset buf_size BINLEN BINDATA  oiis|i:twapi::Twapi_WriteMemoryCharsbufP offset buf_size utf8 DEFAULT_MINUS_ONE     oiio|i:twapi::Twapi_WriteMemoryUnicodebufP offset buf_size ucs16P DEFAULT_MINUS_ONE     il:twapi::GlobalAllocuFlags dwBytes     oli:twapi::GlobalReAllochMem dwBytes uFlags     o:twapi::GlobalFreehMem     o:twapi::GlobalLockhMem     o:twapi::GlobalUnlockhMem   o:twapi::GlobalSizehMem     o:twapi::CloseHandleh   o:twapi::CastToHANDLEh  i|s:twapi::mallocsize DEFAULT_EMPTY_STRING  o:twapi::freevoid *     ol:twapi::OpenProcessTokenProcessHandle DesiredAccess   oll:twapi::OpenThreadTokenThreadHandle DesiredAccess OpenAsSelf     o:twapi::TwapiGetSidStringRepsidP   oo:twapi::LookupAccountNamelpSystemName lpAccountName   oo:twapi::LookupAccountSidlpSystemName sidP     Error looking up account SID:   oi:twapi::GetTokenInformationtokenH token_class     oo:twapi::Twapi_SetTokenPrimaryGrouptokenH sidP     oo:twapi::Twapi_SetTokenOwnertokenH sidP    oooloolo:twapi::NetUserAddservername name password priv home_dir comment flags script_path  oo:twapi::NetUserDelservername username     ol:twapi::Twapi_NetUserEnumserver_name filter   o:twapi::NetGroupEnumserver_name    o:twapi::NetLocalGroupEnumserver_name   oo:twapi::NetUserGetGroupsserver_name user_name     ool:twapi::NetUserGetLocalGroupsserver_name user_name flags     oo:twapi::NetLocalGroupGetMembersserver_name group_name     oo:twapi::NetGroupGetUsersserver_name group_name    ool:twapi::NetUserGetInfoservername username level  ool:twapi::NetGroupGetInfoservername groupname level    ool:twapi::NetLocalGroupGetInfoservername groupname level   ooo:twapi::Twapi_NetUserSetInfo_nameservername username name    ooo:twapi::Twapi_NetUserSetInfo_passwordservername username password    ool:twapi::Twapi_NetUserSetInfo_privservername username priv    ooo:twapi::Twapi_NetUserSetInfo_home_dirservername username home_dir    ooo:twapi::Twapi_NetUserSetInfo_commentservername username comment  ool:twapi::Twapi_NetUserSetInfo_flagsservername username flags  ooo:twapi::Twapi_NetUserSetInfo_script_pathservername username script_path  ool:twapi::Twapi_NetUserSetInfo_auth_flagsservername username auth_flags    ooo:twapi::Twapi_NetUserSetInfo_full_nameservername username full_name  ool:twapi::Twapi_NetUserSetInfo_acct_expiresservername username acct_expires    ool:twapi::Twapi_NetUserSetInfo_country_codeservername username country_code    ooo:twapi::Twapi_NetUserSetInfo_profileservername username profile  ooo:twapi::Twapi_NetUserSetInfo_home_dir_driveservername username home_dir_drive    oo:twapi::LookupPrivilegeNamelpSystemName lpLuid counted_outbuf_size    Invalid LUID format:    oo:twapi::LookupPrivilegeDisplayNamelpSystemName lpPrivName counted_outbuf_size     oo:twapi::LookupPrivilegeValuelpSystemName lpPrivName   o:twapi::IsValidSidpsid     ooi:twapi::Twapi_PrivilegeChecktokenH INPUT all_required    
Invalid LUID_AND_ATTRIBUTES:   olo:twapi::Twapi_AdjustTokenPrivilegestokenH disableAll INPUT   ooo:twapi::NetGroupAddservername groupname comment  ooo:twapi::NetLocalGroupAddservername groupname comment     oo:twapi::NetGroupDelservername groupname   oo:twapi::NetLocalGroupDelservername groupname  ooo:twapi::NetGroupAddUserservername groupname username     ooo:twapi::NetGroupDelUserservername groupname username     ooo:twapi::Twapi_NetLocalGroupAddMemberservername groupname membername  ooo:twapi::Twapi_NetLocalGroupDelMemberservername groupname membername  :twapi::Twapi_InitializeSecurityDescriptor  o:twapi::IsValidAclaclP     Internal error constructing ACL Invalid ACL format. Should be 'null' or have exactly two elements   Invalid ACE format. o:twapi::IsValidSecurityDescriptorsecdP     Invalid control flags for SECURITY_DESCRIPTOR   Invalid SECURITY_DESCRIPTOR format. Should have 0 or five elements  oii:twapi::Twapi_GetNamedSecurityInfoname type wanted_fields    oiioooo:twapi::SetNamedSecurityInfoname type set_fields owner group dacl sacl   oii:twapi::Twapi_GetSecurityInfoh type wanted_fields    oiioooo:twapi::SetSecurityInfoh type wanted_fields owner group dacl sacl    oooll:twapi::LogonUserlpszUsername lpszDomain lpszPassword dwLogonType dwLogonProvider  o:twapi::ImpersonateLoggedOnUserhToken  :twapi::RevertToSelf    i:twapi::ImpersonateSelflevel   oo:twapi::SetThreadTokenthread token    oloii:twapi::DuplicateTokenExhExistingToken dwDesiredAccess lpTokenAttributes ImpersonationLevel TokenType  Invalid SECURITY_ATTRIBUTES format. Should have 0 or 2 elements i:twapi::UuidCreatelocal_ok     :twapi::UuidCreateNil   :twapi::AllocateLocallyUniqueId il:twapi::ExitWindowsExuFlags dwReason  :twapi::LockWorkStation i:twapi::GetUserNameExformat counted_outbuf_size    ol:twapi::Twapi_LsaOpenPolicySystemName DesiredAccess   o:twapi::LsaCloseObjectHandle   oo:twapi::Twapi_LsaEnumerateAccountRightsPolicyHandle AccountSid    oo:twapi::Twapi_LsaEnumerateAccountsWithUserRightPolicyHandle UserRights    ooo:twapi::Twapi_LsaAddAccountRightsPolicyHandle AccountSid LSASTRINGARRAY LSASTRINGARRAYCOUNT  ooio:twapi::Twapi_LsaRemoveAccountRightsPolicyHandle AccountSid AllRights LSASTRINGARRAY LSASTRINGARRAYCOUNT    :twapi::LsaEnumerateLogonSessions   o:twapi::LsaGetLogonSessionDataluidP    oi:twapi::Twapi_LsaQueryInformationPolicylsaH infoclass     ol:twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_setself dwOSVersionInfoSize  o:twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_getself   ol:twapi::OSVERSIONINFOEXW_dwMajorVersion_setself dwMajorVersion    o:twapi::OSVERSIONINFOEXW_dwMajorVersion_getself    ol:twapi::OSVERSIONINFOEXW_dwMinorVersion_setself dwMinorVersion    o:twapi::OSVERSIONINFOEXW_dwMinorVersion_getself    ol:twapi::OSVERSIONINFOEXW_dwBuildNumber_setself dwBuildNumber  o:twapi::OSVERSIONINFOEXW_dwBuildNumber_getself     ol:twapi::OSVERSIONINFOEXW_dwPlatformId_setself dwPlatformId    o:twapi::OSVERSIONINFOEXW_dwPlatformId_getself  oo:twapi::OSVERSIONINFOEXW_szCSDVersion_setself szCSDVersion    o:twapi::OSVERSIONINFOEXW_szCSDVersion_getself  oh:twapi::OSVERSIONINFOEXW_wServicePackMajor_setself wServicePackMajor  o:twapi::OSVERSIONINFOEXW_wServicePackMajor_getself     oh:twapi::OSVERSIONINFOEXW_wServicePackMinor_setself wServicePackMinor  o:twapi::OSVERSIONINFOEXW_wServicePackMinor_getself     oh:twapi::OSVERSIONINFOEXW_wSuiteMask_setself wSuiteMask    o:twapi::OSVERSIONINFOEXW_wSuiteMask_getself    ob:twapi::OSVERSIONINFOEXW_wProductType_setself wProductType    o:twapi::OSVERSIONINFOEXW_wProductType_getself  ob:twapi::OSVERSIONINFOEXW_wReserved_setself wReserved  o:twapi::OSVERSIONINFOEXW_wReserved_getself     :twapi::new_OSVERSIONINFOEXW    o:twapi::delete_OSVERSIONINFOEXWself    o:twapi::GetVersionExlpVersionInformation   :twapi::GetComputerNamecounted_outbuf_size  i:twapi::GetComputerNameExnamefmt counted_outbuf_size   oolll:twapi::InitiateSystemShutdownlpMachineName lpMessage dwTimeout bForceAppsClosed bRebootAfterShutdown  o:twapi::AbortSystemShutdownlpMachineName   o:twapi::ExpandEnvironmentStringslpSrc malloc_outbuf_size   lollo:twapi::FormatMessageFromModuledwFlags hModule dwMessageId dwLanguageId argc argv  loo:twapi::FormatMessageFromStringdwFlags fmtString argc argv   ol:twapi::LoadLibraryExlpFileName dwFlags   o:twapi::FreeLibraryhModule     :twapi::GetSystemInfo   ooio:twapi::GetPrivateProfileIntlpAppName lpKeyName nDefault lpFileName     ooi:twapi::GetProfileIntlpAppName lpKeyName nDefault    oooo:twapi::GetPrivateProfileStringlpAppName lpKeyName lpDefault malloc_outbuf_size lpFileName  ooo:twapi::GetProfileStringlpAppName lpKeyName lpDefault malloc_outbuf_size     oooo:twapi::WritePrivateProfileStringlpAppName lpKeyName lpString lpFileName    ooo:twapi::WriteProfileStringlpAppName lpKeyName lpString   oo:twapi::GetPrivateProfileSectionlpAppName lpFileName  o:twapi::GetPrivateProfileSectionNameslpFileName    :twapi::GlobalMemoryStatus  iioi:twapi::SystemParametersInfouiAction uiParam pvParam fWinIni    :twapi::Twapi_SystemProcessorTimes  :twapi::Twapi_SystemPagefileInformation oloo:twapi::Twapi_LoadUserProfilehToken flags username profilepath  oo:twapi::UnloadUserProfilehToken hProfile  :twapi::GetProfileType  :twapi::GetSystemTimeAsFileTime :twapi::GetTickCount    o:twapi::FileTimeToSystemTimelpFileTime     o:twapi::SystemTimeToFileTimelpSystemTime   b:twapi::Wow64EnableWow64FsRedirectionenable_redirection    :twapi::Wow64DisableWow64FsRedirection  o:twapi::Wow64RevertWow64FsRedirectionaddr  lll:twapi::OpenProcessdwDesiredAccess bInheritHandle dwProcessId    :twapi::GetCurrentProcess   oi:twapi::TerminateProcesshProcess uExitCode    oo:twapi::GetModuleFileNameExhProcess hModule counted_outbuf_size   oo:twapi::GetModuleBaseNamehProcess hModule counted_outbuf_size     o:twapi::GetDeviceDriverFileNamelpBase counted_outbuf_size  o:twapi::GetDeviceDriverBaseNamelpBase counted_outbuf_size  EntryPoint  SizeOfImage lpBaseOfDll oo:twapi::GetModuleInformationhProcess hModule cb   :twapi::EnumProcesses   o:twapi::EnumProcessModulesphandle  :twapi::EnumDeviceDrivers   :twapi::GetCurrentThreadId  :twapi::GetCurrentThread    lll:twapi::OpenThreaddwDesiredAccess bInheritHandle dwThreadId  ol:twapi::WaitForInputIdlehProcess dwMilliseconds   oooollooo:twapi::CreateProcesslpApplicationName lpCommandLine lpProcessAttributes lpThreadAttributes bInheritHandles dwCreationFlags lpEnvironment lpCurrentDirectory lpStartupInfo     ooooollooo:twapi::CreateProcessAsUserhToken lpApplicationName lpCommandLine lpProcessAttributes lpThreadAttributes bInheritHandles dwCreationFlags lpEnvironment lpCurrentDirectory lpStartupInfo   o:twapi::ResumeThreadhThread    o:twapi::SuspendThreadhThread   ol:twapi::SetPriorityClasshProcess dwPriorityClass  o:twapi::GetPriorityClasshProcess   oi:twapi::SetThreadPriorityhThread nPriority    o:twapi::GetThreadPriorityhThread   o:twapi::Twapi_NtQueryInformationProcessBasicInformationprocessH    o:twapi::Twapi_NtQueryInformationThreadBasicInformationthreadH  oool:twapi::ReadProcessMemoryhProcess lpBaseAddress lpBuffer nSize  o:twapi::GetExitCodeProcesshProcess     :twapi::GetCommandLineW o:twapi::CommandLineToArgvcmdlineP  ii:twapi::Twapi_GetProcessListpid detail    o:twapi::GetDiskFreeSpaceExdir  o:twapi::GetDriveTyperootpath   :twapi::GetLogicalDrives    o:twapi::GetVolumeInformationlpRootPathName counted_outbuf_size counted_outbuf_size     oo:twapi::SetVolumeLabelrootpath vollabel   o:twapi::QueryDosDevicelpDeviceName     loo:twapi::DefineDosDevicedwFlags lpDeviceName lpTargetPath     :twapi::FindFirstVolumecounted_outbuf_size  o:twapi::FindNextVolumefindH counted_outbuf_size    o:twapi::FindVolumeClosefindH   o:twapi::FindFirstVolumeMountPointvolumeNameP counted_outbuf_size   o:twapi::FindNextVolumeMountPointfindH counted_outbuf_size  o:twapi::FindVolumeMountPointClosefindH     oo:twapi::SetVolumeMountPointvolptP volnameP    o:twapi::DeleteVolumeMountPointvolptP   o:twapi::GetVolumeNameForVolumeMountPointvolptP counted_outbuf_size     o:twapi::GetVolumePathNamevolptP counted_outbuf_size    ollollo:twapi::CreateFilelpFileName dwDesiredAccess dwShareMode lpSecurityAttributes dwCreationDisposition dwFlagsAndAttributes hTemplateFile   ollso:twapi::RegisterDirChangeNotifierpath subtree filter script argc argv  i:twapi::UnregisterDirChangeNotifierid  o:twapi::Twapi_GetFileVersionInfopath   o:twapi::Twapi_FreeFileVersionInfoverP  l:twapi::VerLanguageNamelangid counted_outbuf_size  o:twapi::Twapi_VerQueryValue_FIXEDFILEINFOverP  ooo:twapi::Twapi_VerQueryValue_STRINGverP lang_and_cp name  o:twapi::Twapi_VerQueryValue_TRANSLATIONSverP   o:twapi::GetFileTypeh   ool:twapi::MoveFileExlpExistingFileName lpNewFileName dwFlags   o:twapi::GetFileTimeh   oooo:twapi::SetFileTimeh NULL_OK NULL_OK NULL_OK    ol:twapi::RECT_left_setself left    o:twapi::RECT_left_getself  ol:twapi::RECT_top_setself top  o:twapi::RECT_top_getself   ol:twapi::RECT_right_setself right  o:twapi::RECT_right_getself     ol:twapi::RECT_bottom_setself bottom    o:twapi::RECT_bottom_getself    :twapi::new_RECT    o:twapi::delete_RECTself    ol:twapi::WINDOWINFO_cbSize_setself cbSize  o:twapi::WINDOWINFO_cbSize_getself  oo:twapi::WINDOWINFO_rcWindow_setself rcWindow  o:twapi::WINDOWINFO_rcWindow_getself    oo:twapi::WINDOWINFO_rcClient_setself rcClient  o:twapi::WINDOWINFO_rcClient_getself    ol:twapi::WINDOWINFO_dwStyle_setself dwStyle    o:twapi::WINDOWINFO_dwStyle_getself     ol:twapi::WINDOWINFO_dwExStyle_setself dwExStyle    o:twapi::WINDOWINFO_dwExStyle_getself   ol:twapi::WINDOWINFO_dwWindowStatus_setself dwWindowStatus  o:twapi::WINDOWINFO_dwWindowStatus_getself  oi:twapi::WINDOWINFO_cxWindowBorders_setself cxWindowBorders    o:twapi::WINDOWINFO_cxWindowBorders_getself     oi:twapi::WINDOWINFO_cyWindowBorders_setself cyWindowBorders    o:twapi::WINDOWINFO_cyWindowBorders_getself     oo:twapi::WINDOWINFO_atomWindowType_setself atomWindowType  o:twapi::WINDOWINFO_atomWindowType_getself  oh:twapi::WINDOWINFO_wCreatorVersion_setself wCreatorVersion    o:twapi::WINDOWINFO_wCreatorVersion_getself     :twapi::new_WINDOWINFO  o:twapi::delete_WINDOWINFOself  oi:twapi::WINDOWPLACEMENT_length_setself length     o:twapi::WINDOWPLACEMENT_length_getself     oi:twapi::WINDOWPLACEMENT_flags_setself flags   o:twapi::WINDOWPLACEMENT_flags_getself  oi:twapi::WINDOWPLACEMENT_showCmd_setself showCmd   o:twapi::WINDOWPLACEMENT_showCmd_getself    oo:twapi::WINDOWPLACEMENT_ptMinPosition_setself ptMinPosition   o:twapi::WINDOWPLACEMENT_ptMinPosition_getself  oo:twapi::WINDOWPLACEMENT_ptMaxPosition_setself ptMaxPosition   o:twapi::WINDOWPLACEMENT_ptMaxPosition_getself  oo:twapi::WINDOWPLACEMENT_rcNormalPosition_setself rcNormalPosition     o:twapi::WINDOWPLACEMENT_rcNormalPosition_getself   :twapi::new_WINDOWPLACEMENT o:twapi::delete_WINDOWPLACEMENTself     ol:twapi::POINT_x_setself x     o:twapi::POINT_x_getself    ol:twapi::POINT_y_setself y     o:twapi::POINT_y_getself    :twapi::new_POINT   o:twapi::delete_POINTself   :twapi::EnumWindows o:twapi::EnumChildWindowsparent_handle  o:twapi::GetParenthwndChild     oi:twapi::GetAncestorhwndChild flags    oi:twapi::GetWindowhwnd uCmd    :twapi::GetDesktopWindow    :twapi::GetShellWindow  :twapi::GetForegroundWindow o:twapi::SetForegroundWindowhWnd    o:twapi::SetActiveWindowhWnd    :twapi::GetActiveWindow oo:twapi::FindWindowlpClassName lpWindowName    oooo:twapi::FindWindowExhwndParent hwndChildAfter lpClassName lpWindowName  o:twapi::RealGetWindowClasshWnd counted_outbuf_size     o:twapi::GetClassNamehWnd counted_outbuf_size   oi:twapi::GetWindowLonghWnd nIndex  oil:twapi::SetWindowLonghWnd nIndex lValue  ooiiiii:twapi::SetWindowPoshWnd hWndInsertAfter x y cx cy uFlags    o:twapi::GetWindowThreadProcessIdhWnd   ol:twapi::GUITHREADINFO_cbSize_setself cbSize   o:twapi::GUITHREADINFO_cbSize_getself   ol:twapi::GUITHREADINFO_flags_setself flags     o:twapi::GUITHREADINFO_flags_getself    oo:twapi::GUITHREADINFO_hwndActive_setself hwndActive   o:twapi::GUITHREADINFO_hwndActive_getself   oo:twapi::GUITHREADINFO_hwndFocus_setself hwndFocus     o:twapi::GUITHREADINFO_hwndFocus_getself    oo:twapi::GUITHREADINFO_hwndCapture_setself hwndCapture     o:twapi::GUITHREADINFO_hwndCapture_getself  oo:twapi::GUITHREADINFO_hwndMenuOwner_setself hwndMenuOwner     o:twapi::GUITHREADINFO_hwndMenuOwner_getself    oo:twapi::GUITHREADINFO_hwndMoveSize_setself hwndMoveSize   o:twapi::GUITHREADINFO_hwndMoveSize_getself     oo:twapi::GUITHREADINFO_hwndCaret_setself hwndCaret     o:twapi::GUITHREADINFO_hwndCaret_getself    oo:twapi::GUITHREADINFO_rcCaret_setself rcCaret     o:twapi::GUITHREADINFO_rcCaret_getself  :twapi::new_GUITHREADINFO   o:twapi::delete_GUITHREADINFOself   lo:twapi::GetGUIThreadInfoidThread pGuiThreadInfo   o:twapi::GetWindowTexthWnd counted_outbuf_size  oo:twapi::SetWindowTexthWnd lpString    oi:twapi::ShowWindowhWnd flags  oi:twapi::ShowWindowAsynchWnd flags     ol:twapi::ShowOwnedPopupshWnd fShow     ol:twapi::EnableWindowhWnd bEnable  o:twapi::OpenIconhWnd   o:twapi::CloseWindowhWnd    o:twapi::DestroyWindowhWnd  o:twapi::IsIconichWnd   o:twapi::IsZoomedhWnd   o:twapi::IsWindowVisiblehWnd    o:twapi::IsWindowhWnd   o:twapi::IsWindowUnicodehWnd    o:twapi::IsWindowEnabledhWnd    oo:twapi::IsChildhwndParent hwndChild   oillii:twapi::SendMessageTimeouthWnd Msg wParam lParam fuFlags uTimeout     oill:twapi::SendNotifyMessagehWnd Msg wParam lParam     oill:twapi::PostMessagehWnd Msg wParam lParam   o:twapi::SetFocushWnd   o:twapi::GetClientRecthWnd  o:twapi::GetWindowRecthWnd  oo:twapi::GetWindowInfohwnd pwi     oo:twapi::GetWindowPlacementhWnd lpwndpl    oo:twapi::SetWindowPlacementhWnd lpwndpl    o:twapi::WindowFromPointPoint   ool:twapi::InvalidateRecthWnd RECT_NULL bErase  oiiiil:twapi::MoveWindowhWnd x y nWidth nHeight bRepaint    o:twapi::UpdateWindowhWnd   ol:twapi::FlashWindowhWnd bInvert   ll:twapi::BeepdwFreq dwDuration     i:twapi::MessageBeepuType   :twapi::GetCaretBlinkTime   i:twapi::SetCaretBlinkTimeuMSeconds     o:twapi::HideCarethWnd  o:twapi::ShowCarethWnd  :twapi::GetCaretPos ii:twapi::SetCaretPosx y    lll:twapi::AttachThreadInputidAttach idAttachTo fAttach     o:twapi::ArrangeIconicWindowshWnd   s:twapi::SendInputinput_str     s:twapi::Twapi_SendUnicodeutf8  ool:twapi::PlaySoundpszSound hmod fdwsound  :twapi::GetCursorPos    ii:twapi::SetCursorPosx y   iis:twapi::RegisterHotKeykeyModifiers vk script     i:twapi::UnregisterHotKeyid     l:twapi::BlockInputblock    looliiiioooo:twapi::CreateWindowExdwExStyle lpClassName lpWindowName dwStyle x y nWidth nHeight hWndParent hMenu hInstance lpParam  olbl:twapi::SetLayeredWindowAttributeshwnd crKey bAlpha dwFlags     :twapi::GetProcessWindowStation o:twapi::SetProcessWindowStationhWinSta     oll:twapi::OpenWindowStationlpszWinSta fInherit dwDesiredAccess     ollo:twapi::CreateWindowStationlpwinsta dwFlags dwDesiredAccess lpsa    o:twapi::CloseWindowStationhWinSta  :twapi::EnumWindowStations  o:twapi::EnumDesktopWindowshdesk    o:twapi::EnumDesktopshwinsta    olll:twapi::OpenDesktoplpszDesktop dwFlags fInherit dwDesiredAccess     ooollo:twapi::CreateDesktoplpszDesktop lpszDevice pDevmode dwFlags dwDesiredAccess lpsa     lll:twapi::OpenInputDesktopdwFlags fInherit dwDesiredAccess     o:twapi::CloseDesktophDesktop   o:twapi::SwitchDesktophDesktop  l:twapi::GetThreadDesktopdwThreadId     o:twapi::SetThreadDesktophDesktop   :twapi::GetDoubleClickTime  :twapi::GetLastInputInfo    i:twapi::GetAsyncKeyStatevkey   i:twapi::GetKeyStatevkey    ii:twapi::MapVirtualKeyuCode uMapType   |o:twapi::OpenClipboardHWND_NULL_DEFAULT    :twapi::CloseClipboard  :twapi::EmptyClipboard  io:twapi::SetClipboardDatauFormat hMem  i:twapi::GetClipboardDataclip_fmt   :twapi::GetOpenClipboardWindow  :twapi::Twapi_EnumClipboardFormats  i:twapi::GetClipboardFormatNameformat counted_outbuf_size   :twapi::GetClipboardOwner   i:twapi::IsClipboardFormatAvailableformat   o:twapi::RegisterClipboardFormatlpszFormat  s:twapi::MonitorClipboardStartscript    o:twapi::MonitorClipboardStophwin   :twapi::GetUserDefaultLangID    :twapi::GetSystemDefaultLangID  :twapi::GetUserDefaultLCID  :twapi::GetSystemDefaultLCID    :twapi::GetUserDefaultUILanguage    :twapi::GetSystemDefaultUILanguage  llloiiiooi:twapi::GetNumberFormatopts Locale dwFlags lpValue NumDigits LeadingZero Grouping lpDecimalSep lpThousandSep NegativeOrder    llloiiiooiio:twapi::GetCurrencyFormatopts Locale dwFlags lpValue NumDigits LeadingZero Grouping lpDecimalSep lpThousandSep NegativeOrder PositiveOrder lpCurrencySymbol     :twapi::GetThreadLocale ll:twapi::GetLocaleInfodwLocale dwLocaleType counted_outbuf_size    :twapi::GetACP  :twapi::GetOEMCP    o:twapi::IIDFromStrings     o:twapi::CLSIDFromProgIDlpszProgID  o:twapi::ProgIDFromCLSIDINPUT   o:twapi::CLSIDFromStringLPWSTR  oolos:twapi::Twapi_CoCreateInstanceINPUT pUnkOuter dwClsContext INPUT name  o:twapi::GetActiveObjectINPUT   oos:twapi::IUnknown_QueryInterfaceunkP INPUT nameP  o:twapi::Twapi_GetObjectIDispatchname   ool:twapi::IDispatch_GetIDsOfNamesidispP argc argv lcid     o:twapi::ConvertToIUnknowninterfaceP    o:twapi::ITypeInfo_GetTypeAttrITypeInfo *   oi:twapi::ITypeInfo_GetVarDesctiP index     oi:twapi::ITypeInfo_GetFuncDesctiP index    oo:twapi::ITypeInfo_GetIDsOfNamestiP argc argv  ol:twapi::ITypeInfo_GetNamestiP memid   oohl:twapi::ITypeComp_BindtcP nameP flags lcid  oi:twapi::LoadTypeLibExszFile regkind   ohhl:twapi::LoadRegTypeLibINPUT wVerMajor wVerMinor lcid    ooo:twapi::RegisterTypeLibptlib szFullPath szHelpDir    ohhli:twapi::UnRegisterTypeLibINPUT wVerMajor wVerMinor lcid syskind    ohhl:twapi::QueryPathOfRegTypeLibINPUT wVerMajor wVerMinor lcid     o:twapi::ITypeLib_GetLibAttrITypeLib *  o:twapi::GetRecordInfoFromTypeInfopTypeInfo     olllo:twapi::GetRecordInfoFromGuidsINPUT uVerMajor uVerMinor lcid INPUT     o:twapi::IRecordInfo_GetFieldNamesriP   ol:twapi::IEnumVARIANT_NextevP count    :twapi::CreateBindCtx   o:twapi::CreateFileMonikerpath  o:twapi::OleRuniunknown     d:twapi::VariantTimeToSystemTimevtime   o:twapi::SystemTimeToVariantTimesystemtime  oiol:twapi::SHGetFolderPathhwnd folder tok flags    oil:twapi::SHGetSpecialFolderPathhwndOwner nFolder fCreate  oi:twapi::SHGetSpecialFolderLocationhwndOwner nFolder   o:twapi::SHGetPathFromIDListpidl    oloo:twapi::SHObjectPropertieshwnd dwType szObject szPage   oo:twapi::OpenThemeDatawin classes  o:twapi::CloseThemeDataHTHEME   :twapi::IsThemeActive   :twapi::IsAppThemed :twapi::GetCurrentThemeName oiii:twapi::GetThemeColorhTheme iPartId iStateId iPropId    ooiii:twapi::GetThemeFonthTheme hdc iPartId iStateId iPropId    s:twapi::TwapiThemeDefineValuename  :twapi::Twapi_GetShellVersion   ooooohoioio:twapi::Twapi_WriteShortcutlinkPath objPath itemIds commandArgs desc hotkey iconPath iconIndex relativePath showCommand workingDirectory     oiol:twapi::Twapi_ReadShortcutlinkPath pathFlags hwnd resolve_flags     ool:twapi::Twapi_WriteUrlShortcutlinkPath url flags     o:twapi::Twapi_ReadUrlShortcutlinkPath  oolo:twapi::Twapi_InvokeUrlShortcutlinkPath verb flags hwnd     oiool:twapi::SHInvokePrinterCommandhwnd action buf1 buf2 modal  oiooho:twapi::Twapi_SHFileOperationhwnd op fromP toP flags progress_title   ol:twapi::SERVICE_STATUS_dwServiceType_setself dwServiceType    o:twapi::SERVICE_STATUS_dwServiceType_getself   ol:twapi::SERVICE_STATUS_dwCurrentState_setself dwCurrentState  o:twapi::SERVICE_STATUS_dwCurrentState_getself  ol:twapi::SERVICE_STATUS_dwControlsAccepted_setself dwControlsAccepted  o:twapi::SERVICE_STATUS_dwControlsAccepted_getself  ol:twapi::SERVICE_STATUS_dwWin32ExitCode_setself dwWin32ExitCode    o:twapi::SERVICE_STATUS_dwWin32ExitCode_getself     ol:twapi::SERVICE_STATUS_dwServiceSpecificExitCode_setself dwServiceSpecificExitCode    o:twapi::SERVICE_STATUS_dwServiceSpecificExitCode_getself   ol:twapi::SERVICE_STATUS_dwCheckPoint_setself dwCheckPoint  o:twapi::SERVICE_STATUS_dwCheckPoint_getself    ol:twapi::SERVICE_STATUS_dwWaitHint_setself dwWaitHint  o:twapi::SERVICE_STATUS_dwWaitHint_getself  :twapi::new_SERVICE_STATUS  o:twapi::delete_SERVICE_STATUSself  |ool:twapi::OpenSCManagerpszMachineName pszDatabaseName dwDesiredSCMAccess  o:twapi::LockServiceDatabasehSCManager  o:twapi::UnlockServiceDatabaseScLock    dwLockDuration  lpLockOwner fIsLocked   o:twapi::QueryServiceLockStatushSCManager   oo|l:twapi::OpenServicehSCManager pszInternalName dwDesiredServiceAccess    ooolllloooooo:twapi::CreateServicehSCManager lpServiceName lpDisplayName dwDesiredAccess dwServiceType dwStartType dwErrorControl lpBinaryPathName lpLoadOrderGroup lpdwTagId lpDependencies lpServiceStartName lpPassword  o:twapi::DeleteServicehService  oo:twapi::StartServicehService argc argv    olo:twapi::ControlServicehService dwControl lpServiceStatus     oo:twapi::QueryServiceStatushService lpServiceStatus    lpDependencies  lpDisplayName   lpServiceStartName  lpLoadOrderGroup    lpBinaryPathName    dwTagId dwErrorControl  dwStartType o:twapi::QueryServiceConfighService     oo:twapi::GetServiceKeyNamehSCManager name  oo:twapi::GetServiceDisplayNamehSCManager name  olllooooooo:twapi::ChangeServiceConfighService dwServiceType dwStartType dwErrorControl lpBinaryPathName lpLoadOrderGroup lpdwTagId lpDependencies lpServiceStartName lpPassword lpDisplayName  oll:twapi::EnumServicesStatushService dwServiceType dwServiceState  lpServiceName   oillo:twapi::EnumServicesStatusExhService infolevel dwServiceType dwServiceState groupname  Unsupported information level   ol:twapi::EnumDependentServiceshService dwServiceState  o:twapi::CloseServiceHandlehSCManager   oi:twapi::QueryServiceStatusExh infolevel   ols:twapi::Twapi_BecomeAServiceargc argv service_type script    slllll:twapi::Twapi_SetServiceStatusname state exit_code service_exit_code checkpoint waithint  s:twapi::Twapi_StopServiceThreadname    oo:twapi::RegisterEventSourceserverName sourceName  ohhlooo:twapi::ReportEventhEventLog wType wCategory dwEventID lpUserSid argc argv BINLEN BINDATA    o:twapi::DeregisterEventSourcehEventLog     oo:twapi::OpenEventLoglpUNCServerName lpSourceName  oo:twapi::OpenBackupEventLoglpUNCServerName lpFileName  oll:twapi::ReadEventLogevlH flags offset    o:twapi::CloseEventLoghEventLog     oo:twapi::BackupEventLoghEventLog lpBackupFileName  oo:twapi::ClearEventLoghEventLog lpClearFileName    o:twapi::GetNumberOfEventLogRecordshEventLog    o:twapi::GetOldestEventLogRecordhEventLog   o:twapi::Twapi_IsEventLogFullhEventLog  :twapi::AllocConsole    llol:twapi::CreateConsoleScreenBufferdwDesiredAccess dwShareMode lpSecurityAttributes dwFlags   ohlo:twapi::FillConsoleOutputAttributehConsoleOutput wAttribute nLength dwWriteCoord    Invalid Console coordinates format. Should have exactly 2 integer elements between 0 and 65535  oolo:twapi::FillConsoleOutputCharacterhConsoleOutput wChar nLength dwWriteCoord     o:twapi::FlushConsoleInputBufferhConsoleInput   :twapi::FreeConsole ll:twapi::GenerateConsoleCtrlEventdwCtrlEvent dwProcessGroupId  :twapi::GetConsoleCP    o:twapi::GetConsoleModehConsoleHandle   :twapi::GetConsoleOutputCP  o:twapi::GetConsoleScreenBufferInfohConsoleOutput   :twapi::GetConsoleTitlecounted_outbuf_size  :twapi::GetConsoleWindow    o:twapi::GetLargestConsoleWindowSizehConsoleOutput  o:twapi::GetNumberOfConsoleInputEventshConsoleInput     :twapi::GetNumberOfConsoleMouseButtons  l:twapi::GetStdHandlenStdHandle     i:twapi::SetConsoleCPwCodePageID    oo:twapi::SetConsoleCursorPositionhConsoleOutput dwCursorPosition   ol:twapi::SetConsoleModehConsoleHandle dwMode   i:twapi::SetConsoleOutputCPwCodePageID  oo:twapi::SetConsoleScreenBufferSizehConsoleOutput dwSize   oh:twapi::SetConsoleTextAttributehConsoleOutput wAttributes     o:twapi::SetConsoleTitlelpConsoleTitle  olo:twapi::SetConsoleWindowInfohConsoleOutput bAbsolute lpConsoleWindow     Need to specify exactly 4 integers for a SMALL_RECT structure   lo:twapi::SetStdHandlenStdHandle hHandle    ool:twapi::WriteConsolehConsoleOutput lpBuffer nNumberOfCharsToWrite    ooo:twapi::WriteConsoleOutputCharacterhConsoleOutput INPUT COUNT dwWriteCoord   o:twapi::SetConsoleActiveScreenBufferhHandle    oi:twapi::ReadConsoleconh numchars  si:twapi::RegisterConsoleEventNotifierscript timeout    :twapi::UnregisterConsoleEventNotifier  :twapi::PdhGetDllVersion    o:twapi::PdhConnectMachineszMachineName     ooll:twapi::PdhEnumObjectsszDataSource szMachineName dwDetailLevel bRefresh     oooll:twapi::PdhEnumObjectItemsszDataSource szMachineName szObjectName dwDetailLevel dwFlags    oooolol:twapi::PdhMakeCounterPathszMachineName szObjectName szInstanceName szParentInstance dwInstanceIndex szCounterName dwFlags   ol:twapi::PdhParseCounterPathszFullPathBuffer dwFlags   :twapi::PdhBrowseCounters   l:twapi::PdhSetDefaultRealTimeDataSourcedwDataSourceId  ol:twapi::PdhOpenQueryszDataSource dwUserData   o:twapi::PdhCloseQueryhQuery    ool:twapi::PdhAddCounterhQuery szFullCounterPath dwUserData     o:twapi::PdhRemoveCounterhCounter   o:twapi::PdhCollectQueryDatahQuery  ol:twapi::PdhGetFormattedCounterValuehCounter dwFormat  o:twapi::PdhValidatePathszFullCounterPath   ol:twapi::PdhLookupPerfNameByIndexszMachineName ctr_index   o:twapi::GetDChwin  o:twapi::GetWindowDChwin    oo:twapi::ReleaseDChwin hdc     oio:twapi::GetObjecthgdiobj cbBuffer lpvObject  oi:twapi::GetDeviceCapshdc index    ol|l:twapi::EnumDisplayDeviceslpDevice iDevNum DEFAULT_ZERO     ol:twapi::MonitorFromWindowhwnd dwFlags     ol:twapi::MonitorFromRectlprc dwFlags   ol:twapi::MonitorFromPointpt dwFlags    o:twapi::GetMonitorInfohMonitor     oo:twapi::EnumDisplayMonitorshdc RECT_NULL  ol|o:twapi::AddFontResourceExlpszFilename fl LPVOID_NULL_DEFAULT    ol|o:twapi::RemoveFontResourceExlpFileName fl LPVOID_NULL_DEFAULT   looo:twapi::CreateScalableFontResourcefdwHidden lpszFontRes lpszFontFile lpszCurrentPath    ol:twapi::IEnumWorkItems_NextewiP count     oooh:twapi::IScheduledWorkItem_GetRunTimesswiP beginP endP count    o:twapi::IScheduledWorkItem_GetWorkItemDataswiP     l:twapi::Twapi_EnumPrinters_Level4flags     l:twapi::ProcessIdToSessionIddwProcessId    o:twapi::WTSCloseServerHANDLE   oll:twapi::WTSDisconnectSessionhServer SessionId bWait  o:twapi::WTSEnumerateProcesseswtsH  o:twapi::WTSEnumerateSessionswtsH   oll:twapi::WTSLogoffSessionhServer SessionId bWait  o:twapi::WTSOpenServerserver_name   oli:twapi::WTSQuerySessionInformationhServer sess_id info_class     ololollll:twapi::WTSSendMessagehServer SessionId pTitle TitleLength pMessage MessageLength Style Timeout bWait  ooool:twapi::DsGetDcNamesystemnameP domainnameP INPUT_WITH_NULL sitenameP flags     bbb:twapi::SetSuspendStatehibernate forcecritical disablewakeevent  o:twapi::GetDevicePowerStatehDevice     s:twapi::Twapi_PowerNotifyStartscriptP  o:twapi::Twapi_PowerNotifyStophwin  :twapi::GetSystemPowerStatus    l:twapi::SetThreadExecutionStateesFlags     ooo|o:twapi::SetupDiCreateDeviceInfoListExINPUT_WITH_NULL parent MachineName LPVOID_NULL_DEFAULT    o:twapi::SetupDiDestroyDeviceInfoListDeviceInfoSet  oooloo|o:twapi::SetupDiGetClassDevsExINPUT_WITH_NULL Enumerator parent Flags DeviceInfoSet MachineName LPVOID_NULL_DEFAULT  olo:twapi::SetupDiEnumDeviceInfoDeviceInfoSet MemberIndex DeviceInfoData    oolol:twapi::SetupDiGetDeviceRegistryPropertyDeviceInfoSet DeviceInfoData Property PropertyBuffer PropertyBufferSize    ooolo:twapi::SetupDiEnumDeviceInterfacesDeviceInfoSet DeviceInfoData INPUT MemberIndex DeviceInterfaceData  ooolo:twapi::SetupDiGetDeviceInterfaceDetailDeviceInfoSet DeviceInterfaceData DeviceInterfaceDetailData DeviceInterfaceDetailDataSize DeviceInfoData    o|ooo:twapi::SetupDiClassNameFromGuidExINPUT counted_outbuf_size NULL_DEFAULT NULL_DEFAULT LPVOID_NULL_DEFAULT  ool|oo:twapi::SetupDiClassGuidsFromNameExClassName ClassGuidList ClassGuidListSize NULL_DEFAULT LPVOID_NULL_DEFAULT     oo|o:twapi::SetupDiGetDeviceInstanceIdDeviceInfoSet DeviceInfoData counted_outbuf_size NULL_DEFAULT     olololo:twapi::DeviceIoControlhDevice dwIoControlCode lpInBuffer nInBufferSize lpOutBuffer nOutBufferSize lpOverlapped  slo:twapi::Twapi_DeviceChangeNotifyStartscriptP type INPUT_WITH_NULL    o:twapi::Twapi_DeviceChangeNotifyStophwin   :twapi::GetNetworkParams    :twapi::GetAdaptersInfo o:twapi::GetAdapterIndexAdapterName     :twapi::GetInterfaceInfo    :twapi::GetNumberOfInterfaces   i:twapi::GetPerAdapterInfoadapter_index     i:twapi::GetIfEntryif_index     |i:twapi::GetIfTablesort_order_default_0    |i:twapi::GetIpAddrTablesort_order_default_0    |i:twapi::GetIpNetTablesort_order_default_0     |i:twapi::GetIpForwardTablesort_order_default_0     i:twapi::FlushIpNetTableif_index    ll:twapi::AllocateAndGetTcpExTableFromStacksorted flags     ll:twapi::AllocateAndGetUdpExTableFromStacksorted flags     o:twapi::SetTcpEntryrow     Invalid TCP connection format:  Invalid IP address format:  255.255.255.255 Invalid or non-integer port number specified    oi:twapi::getnameinfoINPUT flags    ssi:twapi::getaddrinfohostname svcname protocol     ss:twapi::Twapi_ResolveHostnameAsyncnameP scriptP   ss:twapi::Twapi_ResolveAddressAsyncaddrP scriptP    oo:twapi::GetBestRouteIPADDR IPADDR     o:twapi::GetBestInterfaceIPADDR     ollli:twapi::GetExtendedTcpTablebuf buf_sz sorted family table_class    oii:twapi::Twapi_FormatExtendedTcpTablebuf family table_class   ollli:twapi::GetExtendedUdpTablebuf buf_sz sorted family table_class    oii:twapi::Twapi_FormatExtendedUdpTablebuf family table_class   oololoo:twapi::NetShareAddserver_name net_name share_type remark max_uses path secd     :twapi::NetUseEnum  oo:twapi::Twapi_NetUseGetInfoUncServerName UseName  ool:twapi::NetShareDelserver_name net_name reserved     o:twapi::Twapi_NetShareEnumserver_name  oo:twapi::Twapi_NetShareCheckserver_name device_name    ool:twapi::NetShareGetInfoservername netname level  ooolo:twapi::NetShareSetInfoserver_name net_name remark max_uses secd   ool:twapi::NetConnectionEnumserver qualifier level  oool:twapi::NetFileEnumserver basepath user level   oll:twapi::NetFileGetInfoserver fileid level    ol:twapi::NetFileCloseservername fileid     oool:twapi::NetSessionEnumserver client user level  oool:twapi::NetSessionGetInfoserver client user level   ooo:twapi::NetSessionDelserver client user  olooooiol:twapi::Twapi_WNetUseConnectionwinH type localdeviceP remoteshareP providerP usernameP ignore_password passwordP flags     oll:twapi::WNetCancelConnection2lpName dwFlags fForce   o:twapi::WNetGetUniversalNamelocalpathP     o:twapi::WNetGetUserlpName  oo:twapi::NetGetDCNameservername domainname     ol:twapi::NetScheduleJobGetInfoservername jobid     oo:twapi::NetScheduleJobAddservername atP   AT_INFO list must have exactly 5 elements   oll:twapi::NetScheduleJobDelServername MinJobId MaxJobId    o:twapi::NetScheduleJobEnumservername   ool:twapi::Twapi_WNetGetResourceInformationremoteName provider resourcetype     olo:twapi::CreateMutexlpMutexAttributes bInitialOwner lpName    llo:twapi::OpenMutexdwDesiredAccess bInheritHandle lpName   o:twapi::ReleaseMutexhMutex     ollo:twapi::CreateSemaphorelpSemaphoreAttributes lInitialCount lMaximumCount lpName     llo:twapi::OpenSemaphoredwDesiredAccess bInheritHandle lpName   ol:twapi::ReleaseSemaphorehSemaphore lReleaseCount  oll:twapi::WaitForMultipleObjectsHANDLE_COUNT HANDLE_ARRAY bWaitAll dwMilliseconds  ooo:twapi::Twapi_Allocate_SEC_WINNT_AUTH_IDENTITYuser domain password   o:twapi::Twapi_Free_SEC_WINNT_AUTH_IDENTITYswaiP    :twapi::EnumerateSecurityPackages   ooloo:twapi::AcquireCredentialsHandlepszPrincipal pszPackage fCredentialUse LUID_WITH_NULL pAuthData    o:twapi::FreeCredentialsHandleINPUT     ooolllol:twapi::InitializeSecurityContextINPUT INPUT_WITH_NULL pszTargetName fContextReq Reserved1 TargetDataRep INPUT_WITH_NULL Reserved2  oooll:twapi::AcceptSecurityContextINPUT INPUT_WITH_NULL INPUT_WITH_NULL fContextReq TargetDataRep   o:twapi::DeleteSecurityContextINPUT     o:twapi::QuerySecurityContextTokenINPUT     o:twapi::ImpersonateSecurityContextINPUT    ol:twapi::QueryContextAttributesINPUT attr  olol:twapi::MakeSignatureINPUT qop BINLEN BINDATA seqnum    ool:twapi::VerifySignatureINPUT INPUT_WITH_NULL MessageSeqNo    olol:twapi::EncryptMessageINPUT qop BINLEN BINDATA seqnum   ool:twapi::DecryptMessageINPUT INOUT seqnum     ooll:twapi::CryptAcquireContextpszContainer pszProvider dwProvType dwFlags  o|l:twapi::CryptReleaseContexthProv DEFAULT_ZERO    ol:twapi::CryptGenRandomhProv dwLen     si:twapi::Tcl_GetChannelHandlechan_name direction   iiii:twapi::Twapi_GetHandleInformationpid skip_errors timeout_ms type   o:twapi::GetHandleInformationhObject    oll:twapi::SetHandleInformationhObject mask flags   ooolll:twapi::DuplicateHandlehSourceProcessHandle hSourceHandle hTargetProcessHandle dwDesiredAccess bInheritHandle dwOptions   o:twapi::IUnknown_ReleasepIUnknown  o:twapi::IUnknown_AddRefpIUnknown   o:twapi::IDispatch_GetTypeInfoCountpIDispatch   oil:twapi::IDispatch_GetTypeInfopIDispatch itinfo lcid  ool:twapi::IDispatchEx_GetDispIDpIDispatchEx INPUT grfdex   ol:twapi::IDispatchEx_GetMemberNamepIDispatchEx dispid  oll:twapi::IDispatchEx_GetMemberPropertiespIDispatchEx dispid grfdexFetch   o:twapi::IDispatchEx_GetNameSpaceParentpIDispatchEx     oll:twapi::IDispatchEx_GetNextDispIDpIDispatchEx grfdex id  oi:twapi::ITypeInfo_GetRefTypeOfImplTypepITypeInfo index    ol:twapi::ITypeInfo_GetRefTypeInfopITypeInfo hreftype   o:twapi::ITypeInfo_GetTypeComppITypeInfo    o:twapi::ITypeInfo_GetContainingTypeLibpITypeInfo   oi:twapi::ITypeInfo_GetDocumentationpITypeInfo index    oi:twapi::ITypeInfo_GetImplTypeFlagspITypeInfo index    oi:twapi::ITypeLib_GetDocumentationpITypeLib index  o:twapi::ITypeLib_GetTypeInfoCountpITypeLib     oi:twapi::ITypeLib_GetTypeInfoTypepITypeLib index   oi:twapi::ITypeLib_GetTypeInfopITypeLib index   oo:twapi::ITypeLib_GetTypeInfoOfGuidpITypeLib INPUT     ooo:twapi::IRecordInfo_GetFieldpIRecordInfo rec fieldname   o:twapi::IRecordInfo_GetGuidpIRecordInfo    o:twapi::IRecordInfo_GetNamepIRecordInfo    o:twapi::IRecordInfo_GetSizepIRecordInfo    o:twapi::IRecordInfo_GetTypeInfopIRecordInfo    oo:twapi::IRecordInfo_IsMatchingTypepIRecordInfo recinfoP   oo:twapi::IRecordInfo_RecordClearpIRecordInfo rec   ooo:twapi::IRecordInfo_RecordCopypIRecordInfo fromrec torec     o:twapi::IRecordInfo_RecordCreatepIRecordInfo   oo:twapi::IRecordInfo_RecordCreateCopypIRecordInfo fromrec  oo:twapi::IRecordInfo_RecordDestroypIRecordInfo rec     oo:twapi::IRecordInfo_RecordInitpIRecordInfo rec    oo:twapi::IMoniker_GetDisplayNamepIMoniker pbc  oo:twapi::IEnumVARIANT_ClonepIEnumVARIANT OUTPUT    o:twapi::IEnumVARIANT_ResetpIEnumVARIANT    ol:twapi::IEnumVARIANT_SkippIEnumVARIANT skipcount  oo:twapi::IConnectionPoint_AdvisepIConnectionPoint unkP     oo:twapi::IConnectionPoint_GetConnectionInterfacepIConnectionPoint OUTPUT   ol:twapi::IConnectionPoint_UnadvisepIConnectionPoint dwCookie   o:twapi::IConnectionPointContainer_EnumConnectionPointspIConnectionPointContainer   oo:twapi::IConnectionPointContainer_FindConnectionPointpIConnectionPointContainer INPUT     ol:twapi::IEnumConnectionPoints_NextpIEnumConnectionPoints celt     o:twapi::IEnumConnectionPoints_ResetpIEnumConnectionPoints  ol:twapi::IEnumConnectionPoints_SkippIEnumConnectionPoints celt     o:twapi::IProvideClassInfo_GetClassInfopIProvideClassInfo   ol:twapi::IProvideClassInfo2_GetGUIDpIProvideClassInfo2 guidkind    ooo:twapi::ITaskScheduler_ActivatepITaskScheduler nameP INPUT   ooo:twapi::ITaskScheduler_AddWorkItempITaskScheduler nameP wiP  oo:twapi::ITaskScheduler_DeletepITaskScheduler nameP    o:twapi::ITaskScheduler_EnumpITaskScheduler     ooo:twapi::ITaskScheduler_IsOfTypepITaskScheduler nameP INPUT   oooo:twapi::ITaskScheduler_NewWorkItempITaskScheduler nameP INPUT INPUT     oo:twapi::ITaskScheduler_SetTargetComputerpITaskScheduler nameP     o:twapi::ITaskScheduler_GetTargetComputerpITaskScheduler    o:twapi::IEnumWorkItems_ClonepIEnumWorkItems    o:twapi::IEnumWorkItems_ResetpIEnumWorkItems    ol:twapi::IEnumWorkItems_SkippIEnumWorkItems count  o:twapi::IScheduledWorkItem_CreateTriggerpIScheduledWorkItem    oh:twapi::IScheduledWorkItem_DeleteTriggerpIScheduledWorkItem trigger   oo:twapi::IScheduledWorkItem_EditWorkItempIScheduledWorkItem hwnd   o:twapi::IScheduledWorkItem_GetAccountInformationpIScheduledWorkItem    o:twapi::IScheduledWorkItem_GetCommentpIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetCreatorpIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetExitCodepIScheduledWorkItem  o:twapi::IScheduledWorkItem_GetFlagspIScheduledWorkItem     o:twapi::IScheduledWorkItem_GetIdleWaitpIScheduledWorkItem  o:twapi::IScheduledWorkItem_GetMostRecentRunTimepIScheduledWorkItem     o:twapi::IScheduledWorkItem_GetNextRunTimepIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetStatuspIScheduledWorkItem    oh:twapi::IScheduledWorkItem_GetTriggerpIScheduledWorkItem trigger  o:twapi::IScheduledWorkItem_GetTriggerCountpIScheduledWorkItem  oh:twapi::IScheduledWorkItem_GetTriggerStringpIScheduledWorkItem trigger    o:twapi::IScheduledWorkItem_RunpIScheduledWorkItem  ooo:twapi::IScheduledWorkItem_SetAccountInformationpIScheduledWorkItem nameP passwordP  oo:twapi::IScheduledWorkItem_SetCommentpIScheduledWorkItem commentP     oo:twapi::IScheduledWorkItem_SetCreatorpIScheduledWorkItem creatorP     oh:twapi::IScheduledWorkItem_SetErrorRetryCountpIScheduledWorkItem count    oh:twapi::IScheduledWorkItem_SetErrorRetryIntervalpIScheduledWorkItem interval  ol:twapi::IScheduledWorkItem_SetFlagspIScheduledWorkItem flags  ohh:twapi::IScheduledWorkItem_SetIdleWaitpIScheduledWorkItem idle deadline  Binary data exceeds MAXWORD oo:twapi::IScheduledWorkItem_SetWorkItemDatapIScheduledWorkItem BINLEN BINDATA  o:twapi::IScheduledWorkItem_TerminatepIScheduledWorkItem    o:twapi::ITask_GetApplicationNamepITask     o:twapi::ITask_GetMaxRunTimepITask  o:twapi::ITask_GetParameterspITask  o:twapi::ITask_GetPrioritypITask    o:twapi::ITask_GetTaskFlagspITask   o:twapi::ITask_GetWorkingDirectorypITask    oo:twapi::ITask_SetApplicationNamepITask nameP  ol:twapi::ITask_SetMaxRunTimepITask runtime     oo:twapi::ITask_SetParameterspITask params  ol:twapi::ITask_SetPrioritypITask priority  ol:twapi::ITask_SetTaskFlagspITask flags    oo:twapi::ITask_SetWorkingDirectorypITask dir   o:twapi::ITaskTrigger_GetTriggerpITaskTrigger   o:twapi::ITaskTrigger_GetTriggerStringpITaskTrigger     oo:twapi::ITaskTrigger_SetTriggerpITaskTrigger triggerP     o:twapi::IPersistFile_GetCurFilepIPersistFile   o:twapi::IPersistFile_IsDirtypIPersistFile  ool:twapi::IPersistFile_LoadpIPersistFile file mode     ool:twapi::IPersistFile_SavepIPersistFile filename remember     oo:twapi::IPersistFile_SaveCompletedpIPersistFile file  namespace eval twapi { }    twapi   2.1.6   8.1 Unknown or unsupported SHChangeNotify flags type    wEventID uFlags dwItem1 ?dwItem2?   Unknown or unsupported SHChangeNotify event type    õJ\KiK¶KÆKÎKÖKIID CMD Unable to allocate memory    Offending parameter index  wCode   scode   dwHelpContext   bstrHelpFile    bstrDescription bstrSource  Property put methods must have exactly one parameter    Invalid IDispatch prototype - must contain DISPID RIID LCID FLAGS RETTYPE ?PARAMTYPES?  IDISPATCH PROTOTYPE ?ARG1 ARG2...?  Could not console control event notification structures Could not initialize directory change notification structures   Could not initialize hotkey structures  Could not initialize callback structures    Could not initialize winsock    Twapi callback initialization already in failed state. Further calls will continue to fail. Bad Twapi callback initialization state.    "   
Error in callback script " start   stop    pause   interrogate Could not install console control handler.  No service names specified. Twapi_BecomeAService called multiple times  Could not start service control dispatcher. ::twapi::_service_background_error  Unknown service name.   ¼ë    .?AVexception@@ ¼ë    .?AVlogic_error@std@@   ¼ë    .?AVout_of_range@std@@  invalid vector<T> subscript Could not register hot key  TwapiHK%x%x devtyp_volume   devtyp_port devtyp_deviceinterface  deviceremovecomplete    devicearrival   devnodes_changed    Device interface must be specified on Windows 2000  Could not queue hostname resolution request.    fail    ŒPZ€PÆ_pPRZCould not queue address resolution request. 10022   Queue length empty even though semaphore acquisition succeeded  ctrl-c  ctrl-break  close   logoff  shutdown    Could not initialize directory change notification. Could not setup overlapped read for directory change notifications. Could not register directory change notification callback.  added   removed modified    renameold   renamenew   unknown  Last system error:     apmbatterylow   apmpowerstatuschange    apmoemevent apmresumeautomatic  apmresumesuspend    apmquerysuspendfailed   apmsuspend  apmresumecritical   Tcl This interpreter does not support stubs-enabled extensions. ¼ë    .?AVtype_info@@                                                                                                                             €                  0  €               	  H   ` è                  è4   V S _ V E R S I O N _ I N F O     ½ïş                                      F   S t r i n g F i l e I n f o   "   0 4 0 9 0 4 b 0   d   F i l e D e s c r i p t i o n     T c l   W i n d o w s   A P I   E x t e n s i o n   D L L   < 
  O r i g i n a l F i l e n a m e   t w a p i . d l l   D   C o m p a n y N a m e     A s h o k   P .   N a d k a r n i   ,   F i l e V e r s i o n     2 . 1 . 6   j #  L e g a l C o p y r i g h t   C o p y r i g h t   ©   2 0 0 9   A s h o k   P .   N a d k a r n i     T   P r o d u c t N a m e     T c l   W i n d o w s   A P I   E x t e n s i o n   :   P r o d u c t V e r s i o n   2 . 1 . 6   B e t a     D    V a r F i l e I n f o     $    T r a n s l a t i o n     	°                                                                                                                                                                                           T  00#0(0-0E0K0Y0^0d0n0w0}0”0›0 0¬0³0¸0Ä0Ë0Ğ0Ü0ã0è0ô0ş01111'1.131?1E1{1€1“1Ë1×1ú12&222^2„2­2Ì2ó2ù23$3,313E3L3b3m3®3Ğ3ó34474>4W4^4{4†4Ñ4á45t5¯5Ò5Ù5ï5ù56 6&6f6Š6§6î6=7C7L7R7Z7e7‹7¥7İ7+8E8]8d8…8˜8Î8í8979>9X9g9œ9¾9à9::$:5:S:}:¡:¼:Ğ:ê:ó:;	;;*;6;=;F;Ë;×;<<Y<z<<¡<¼<Î<é<(=3=:=[=f=n=ƒ=š=½=è=>2>e>|>˜>¥>Î>ç>??w?š?Ÿ?¸?Ó?      D  00&0,0?0D0h0ƒ0‰0 0¥0»0Ï0Õ0ã0é0÷0ı0E1f1x1–1£1¯1Õ1Ü1ò1 2	22-2?2Q2k2„2‘2­2Ñ2î2333 343:3K3i33”33±3Â3Ï3ß3ş34&444W4ƒ4›4¯4ó4ş455$525@5G5`5Ÿ5«5¶5Ú5í5 66&696L6^66¨68+8g8~8Å8Î8Ô8ò89%9s9‹9Ù9í9ú9::0:L:[:h:o:‰:–:°:¾:Ğ:ú:;F;b;v;…;Š;;´;Î;è;<-<W<€<š<Ø<õ<=3=T=y=€=•=²=Ú=û=#>*>P>–>¥>·>Ô>Ù>???*?8?Q?_?h?t?º?ä?   0     00$012 2¿2ì2õ2ş233#3*383M3T3e3‚3¶3Æ3Ò3Û3ó3ÿ34*404>4G4Q4c4k4|44£4´4Ä4Í4Ø4ú435O5^5p5w5‰5•5¦5õ56"676R6[6ä6ñ6ø677 757S7Ÿ7¥7Ñ7à7ú7<8c8z8µ8õ89G9L9R9o9w99š9¡9¨9¸9Ë9Ü9:3:D:K:Y:`:…:¥:¾:×:ë:; ;g;m;};™;Ÿ;W<c<i<u<3=A=f=s=„=±=Û=ò=¦>Ë>
?!?@?s?é?   @  H  P0”0¨0Ò0Ù0á0õ01,141D1L1s1…11›1É1Ø1Ş1ì122/2T2\2e2k2r2y2€2…2Š2‘2µ2à23I33˜3Ÿ3Ô3í3ô34L4d4k44ª4Ë4ã4ê45(555@5J5h5‰5¦5²5Ì5×5ü536E6N6e6o6€6‹6“6 6»6ë67-737¬7²7Ã7á78#8;8\8r8€8ª8¹8>9U9¥9®9Ø9Ş9ñ9:9:g:³:Ã:Ò:ò:;;+;M;q;ƒ;;¹;Ô;ò;<(<U<n<v<†<Œ<£<Ä<Ñ<Õ<Ù<İ<á<å<é<í<ñ<õ<ù<ı<===$=3=h=z=§=Õ=>+>K>c>u>‚>¨>°>×>ù>?-?N?j?s?Á? P  D  0%0Q0@2F2q2x22†22”2›2¥2«2°2ô2ş23
333353<3]3‡33¤3ä3ë344#4:4T4^44†4 4§4Ê4Ï4é4ğ45$5+5B5\5c5†5‹5¥5¬5Ï5Ô5î5õ56676>6_6d6~6…6œ6¶6½6×6ñ6ø67)737J7d7q7‚7œ7¦7½7Ù7à7÷78828L8S8t8z8”8›8²8Ì8Ó8í8
992979Q9X9o9‰99ª9Ä9Ë9î9ó9::7:<:V:]:t::•:¹:¿:Ü:ã:;;/;n;u;‘;°;É;Ü; <'<.<A<Q<X<€<…<§<®<Õ<Ú< =='=M=R=m=t=–=›=©?°?   `    l0w0©0Ü01 121X1h1o1°1Â12>2R2~2š2 2å2ì2ÿ213?3n3‡3§3¾3Ä3í3464<4R4s4‹4ª4Â4ä4ø405I5O5d5Å5Ğ566B6ƒ6·6¼6ã6û697w7|7£7Ù78:8A88–8õ8959ˆ9š9¡9º9Ö9İ9ó9::/:K:R:h:‡::§:À:Ç:à:
;;2;7;E;R;Y;r;™; ;¶;İ;ä;ú;!<(<><]<˜<Ÿ<ô<ú<Y=”=Ì=à=">'>j>s>–>¥>Õ>ß>í>ÿ>??"?‹?•?¦?·?È?Ù?ê?û? p  ˆ  0020@0j0ƒ00£0·0Ü0á0ù011+1W1Œ1›1ª1Ç1;2v2–2»2Ò2Ú2ö233:3_3f3‚3¤3«3Ê3ì3ó3414A4W4v4Ÿ4¯4¿4Ç4Ğ4Ö4İ4ä4ë4ğ4õ4.5h5Š5Ÿ5®5µ5Ñ5ğ5÷5656<6X6w6~66»6à6ğ6/7:7P7X7 7Ü788/8A8I8R8X8_8f8m8r8w8‰8™8¡8ª8°8·8¾8Å8Ê8Ï8á8ñ8ù899999"9'9d9£9Ã9ì9:$:+:A:h:o:…::¥:»:Ô:Ş:ô:;;4;[;b;x;‘;˜;®;Ç;Ñ;ê;<
<#<?<F<_<†<<£<¼<Ã<Ù<ò<ü<=+=2=H=a=k==š=¡=·=Ğ=Ú=ğ=	>>&>?>I>_>x>>•>®>¸>Î>ù>??(?D?K?g?†??©?Å?Ì?â? €  @  00*0F0M0l0–00³0Æ011<1C1d1ˆ11³1å1ì121282Y2}22¨2Ì2Ó2ô23(3C3u3|33Á3È3é34484_4f4‡4±4¸4Ù4515A5o5€56606K6s6’66§6À6Ô6Û6à6707{7Œ7¬7»78"8(8F8h8u88“8²8Ù89-9V9y9¢9Õ9:&:+:A:^:|:¦:½:Î:ß:ğ:;;K;¸;À;É;Ï;Ö;İ;ä;é;î;ú;<"<3<E<X<i<z<Œ<Ä<1=9=B=H=O=V=]=b=g=|==¤=»=é=ı=>->Q>f>›>Á>á>ì>ı>?)?;?T?‚?Ÿ?¨?°?Ë?Ş?ñ?     X  00(0@0G0`0|0ƒ0œ0µ0¼0Õ0ñ0ø01*111J1f1m1†1Ÿ1¦1¿1Û1â1û12242P2W2p2‰22©2Å2Ì2â2ş2*363_3–3©3Ö3â3ç3474C4_4‘4®4µ4Ô4ñ45+5F5]5n55‘5©5À5Ò5õ56686U6j66†6 6¹6À6×6ô6û67,737J7g7n7…7Ÿ7¦7Á7Ü7ã7ş78888S8Z8u88”8¯8Ê8Ñ8ì899&9A9H9c9{9‚9£9¨9Ş9ş9,:3:8:j:‰::š:¹:Ñ:ğ:ù:;2;H;Z;h;v;ˆ;˜;°;Ò;<#<*<T<<‡<¾<í<^==>>/>8>A>L>T>f>s>z>>›>Ó>é>??[?ä?ö?    (  11"1,1J1‚1·1ê1	22292Q2p2y2„2£2»2Ú2ã2í23*3C3U3`3z3…3ï34U4l44î45T5k555³5È5å5
656]6ƒ6¨6Ş67&777=7I7T7w7™7à788'8\8n8‚8§8æ8929H9b9…9Î9h:::»:Ì:Ğ:Ô:Ø:Ü:à:ä:è:ì:ğ:ô:ø:ü: ;;;;;;;; ;$;(;,;0;4;8;<;@;D;H;L;P;T;X;\;`;d;h;l;p;t;x;”;©;¾;Ë;ë;<E<p<†<Ä< =A=|=¾=>>U>[>”>Ğ>?E?ˆ??Ç? °  d  0C0…0”0¡0À0ô0ü01'1+1/13171;1?1C1G1K1O1S1W1[1_1c1g1k1o1s1w1{1—1º1Ã1İ1"2+2E2Ã2Ñ2æ2333`3‡3™3 3¹3Ñ3Ø3ñ344-4F4M4f4‚4‰4¢4Å4Ì4ó4ø4!5(5A5H5a5z55š5³5½5Ö5ñ5ø56,666O6j6q6Š6¥6¯6È6ã6ê677(7A7\7c7|7—7¡7×7é7ö7ı78@88…8¾8ğ8
9*99“9ó9::&:?:`:w:˜::Ï:Ö:;;4;K;R;n;;—;É;×;ä;ë;<+<8<?<[<z<<<Ù<=u==¤=«=Ä=å=ì=>*>1>M>l>s>>±>¸>Ô>õ>ü>?<?C?_?€??£?Ç?Î?   À  H   000"0T0b0o0”0È0Ï0î0û0G1w1‡1Â1É1â1=2R2t2Ÿ2Ì2383L3e3€3¾3Ğ3×3ğ344(4D4K4d4}4„44»4Â4Û4ö4ı45C5’5¼56&6P6{6§6¼6Í6ü67i7Ê7858n8’8›8Å89B9e99¢9®9Ã9Ø9÷9.:g:¬:ê:5;A;h;{;;ƒ;‡;‹;;“;—;›;Ÿ;£;§;«;¯;³;·;»;¿;Ã;Ç;Ë;Ï;Ó;×;Û;ß;ã;ç;ë;ï;ó;÷;û;ÿ;<<<<<<<<#<'<+</<E<Q<\<<­<ê<ñ<=
==.=C=J=k=Œ=“=´=İ=í=w>‚>°>¼>Ñ>á>ñ>h?{?•?Ä?Ò? Ğ  œ  00$0:0A0I0U0o0‹0“0œ0¢0©0°0·0¼0Á0Ö0ó0û01
1111$1)101?1\1b1k1w1“1›1¤1ª1±1¸1¿1Ä1É1Ğ1Ø1á1ç1î1ü122!2'2/2>2H2Z2d2v2€2’2œ2®2¸2Ê2Ô2æ2ğ2333(3:3D3V3`3r3|3‹3•3 3ª3µ3¿3Ê3Ô3ß3é3ø3444*444C4M4\4f4u444˜4§4±4À4Ê4Ù4ã4ò4ü455$5.5=5G5V5`5o5y5ˆ5’5¡5«5º5Ä5Ó5İ5ì5ö5666(676A6P6Z6i6s6‚6Œ6›6¥6´6¾6Í6×6æ6ğ6ÿ6	77"717;7J7T7c7m7|7†7•7Ÿ7®7¸7Ç7Ñ7à7ê7ù7888+858D8N8]8g8v8€88™8¨8²8Á8Ë8Ú8ä8ó8ı899%9/9>9H9W9a9p9z9‰9“9¢9¬9»9Å9Ô9Ş9í9÷9:::):8:B:Q:[:j:t:ƒ::œ:¦:µ:¿:Î:Ø:ç:ñ: ;
;;#;2;<;K;U;d;n;};‡;–; ;¯;¹;È;Ò;á;ë;ú;<<<,<6<E<O<^<h<w<<<š<©<³<Â<Ì<Û<å<ô<ş<==&=+=@=J=Y=c=r=|=‹= =ª=¹=Ã=Ò=Ü=ë= >
>>#>2><>K>`>j>y>ƒ>’>œ>«>À>Ê>Ù>ã>ò>ü>? ?*?9?C?R?\?k?u?„???§?¶?À?Ï?Ù?è?ò? à    000$030=0L0V0e0o0~0ˆ0—0¡0°0º0É0Ó0â0ì0û0111-171F1P1_1i1x1‚1‘1›1ª1´1Ã1Í1Ü1æ1õ1ÿ122'212@2J2Y2c2r2|2‹2•2¤2®2½2Ç2Ö2à2ï2ù233!3+3:3D3S3]3l3v3…333¨3·3Á3Ğ3Ú3é3ó3444%444>4M4W4i4s4…44¡4«4½4Ç4Ö4à4ï4ù455!5+5:5D5S5X5m5w5†55Ÿ5©5¸5Â5Ñ5æ5ğ5ÿ5	66"616;6J6_6i6x6‚6‘6›6ª6´6Ã6Ø6â6ñ6û6
77#7-7<7Q7[7j7t7ƒ77œ7¦7µ7Ê7Ô7ã7í7ü7888.888G8Q8`8j8y8ƒ8’8œ8«8µ8Ä8Î8İ8ç8ö8 999(929A9K9Z9d9s9}9Œ9–9¥9¯9¾9È9×9á9ğ9ú9	::":,:;:E:T:^:m:w:†::Ÿ:©:¸:Â:Ñ:Û:ê:ô:;;;&;5;?;N;X;g;q;€;Š;™;£;²;¼;Ë;Õ;ä;î;ı;<< </<9<H<R<a<k<z<„<“<<¬<¶<Å<Ï<Ş<è<÷<===)=3=B=L=[=e=t=~==—=¦=°=¿=É=Ø=â=ñ=û=
>>#>-><>F>U>_>n>x>‡>‘> >ª>¹>Ã>Ò>Ü>ë>õ>???'?6?@?O?Y?h?r??‹?š?¤?³?½?Ì?Ö?å?ï?ş? ğ  ˆ  00!000:0I0S0b0l0{0…0”00­0·0Æ0Ğ0ß0é0ø0111*141C1M1\1f1u111˜1§1±1À1Ê1Ù1ã1ò1ü122$2.2=2G2V2`2o2t2‰2“2¢2¬2»2Å2Ô2Ş2í2÷233343>3M3W3f3p33‰3˜3¢3±3»3Ê3ß3é3ø3444*444C4M4\4f4u4Š4”4£4­4¼4Æ4Õ4ß4î4ø455 555?5N5X5g5q5€5Š5™5£5²5¼5Ë5à5ê5ù5666,666E6O6^6s6}6Œ6–6¥6¯6¾6È6×6á6ğ6ú6	77#7-7<7F7U7j7t7ƒ77œ7¦7µ7¿7Î7Ø7ç7ñ7 8
88#828<8K8U8d8n8}8‡8–8 8¯8¹8È8Ò8á8ë8ú8999,969E9O9^9h9w999š9©9³9Â9Ì9Û9å9ô9ş9::&:0:?:I:X:b:q:{:Š:”:£:­:¼:Æ:Õ:ß:î:ø:;; ;*;9;C;R;\;k;u;„;;;§;¶;À;Ï;Ù;è;ò;<<<$<3<=<L<V<e<o<~<ˆ<—<¡<°<º<É<Ó<â<ì<û<===-=7=F=P=b=l=~=ˆ=—=¡=°=º=É=Ó=â=ì=ş=>>>1>;>J>T>f>p>>”>>­>·>É>Ó>â>÷>???,?6?H?M?b?l?{?…?”??­?·?É?Ó?â?ì?û?     H  000-070I0S0b0l0{0…0”00­0·0Æ0Ğ0ß0é0ø0111*141C1M1\1f1u11‘1›1ª1´1Ã1Í1Ü1æ1õ1ÿ12&202?2I2X2b2q2{2Š22¤2®2½2Ç2Ö2à2ï2ù233$3.3=3G3V3`3o3y3ˆ3’3¡3«3º3Ä3Ó3İ3ì3ö344$434=4L4V4e4o4~4ˆ4—4¡4°4º4É4Ó4å4ï4ş455!505:5I5S5b5l5{5…5”55­5·5É5Ó5å5ï5ş566!606:6I6S6b6l6{6„6–6›6¥6·6Á6Ğ6Ú6é6ş677$737=7L7a7k7}7‡7–7 7¯7¹7È7Ò7á7ë7ú7888,868E8O8^8h8w888š8©8³8Â8Ì8Û8å8ô8ş899&909?9I9X9b9q9{9Š9”9£9­9¼9Æ9Õ9ß9î9ø9:: :*:9:C:R:\:n:x:‡:‘: :ª:¹:Ã:Î:Ø:ç:ñ: ;
;;#;2;<;O;Y;n;x;;—;¬;¶;Ë;Õ;ê;ô;	<<(<2<G<Q<f<p<…<<¤<®<Ã<Í<â<ì<== =*=?=I=^=h=}=‡=œ=¦=»=Å=Ú=ä=ö= >>>.>8>J>T>e>…>>¥>«>é>ñ>÷>õ?    €  E0L0X0h0©0Ö0İ0ó0.151K1~1…1Ÿ1Ö1İ1ó122)2_2f2|2›2¾2Å2Û233+3`3g3}3Ÿ3ä3í3ó34e4l4x4ˆ4Ç4ê4$5-535E5È5Ğ5Ù5ß5æ5í5ô5ù5ş566&6,636:6A6F6K6a6i6r6x66†66’6—6­6µ6¾6Ä6Ë6Ò6Ù6Ş6ã6A7X7o7}7£7«7´7º7Á7È7Ï7Ô7Ù728>8C8i8q8z8€8‡88•8š8Ÿ8Í8Õ8Ş8ä8ë8ò8ù8ş89@9I9O9h9z9¢9Á9ï9ô9<:G:]:u:Œ:—:·:Ğ:×:î:;;);C;J;a;{;‹;œ;¶;½;Ô;î;ø;<)<0<G<a<k<‚<­<×<ğ<=&=S=n=µ=Ë=*>M>V>o>€>‘>¢>³>Ä>×>ê>ı>????G?›?¡?º?È?     P   00?0J0[0w0|00©0¿01‚1©1²1º1Â1Ê12&2Ç2×2 333-3i3p3(4M4S4Z4ğ4553585Q5X5}5‚5›5¢5Ç5Ì5å5ì566/666O6h6o6—6œ6µ6Ë6Ò6å677]7d7l7|77š7­7Ã7Ü7ã7î78>8Y8`8k8¹899+959D9L9e9o9„99£9­9Ê9Ô9é9ó9::3:=:R:\:q:{:–:ª:¾:Õ:ã:ş::;R;j;‡;£;¶;Ñ;<"<.<9<X<n<ƒ<Š<¤<À<Ç<â<ı<==7=>=Y=t={=–=®=µ=Ğ=ë=ò=>%>,>G>b>o>„>œ>£>º>×>Ş>õ>??-?J?~?’?¦?¿?Ù?í? 0 8  00!0?0c0j0…0 0§0Â0ø01W1h1o1¥1¬1Å1Ì1å1ì122(2/2K2R2n2u2‘2˜2´2»2Ô2Û2ô2û23,333O3V3r3}3£3Ì3a4Ü4â4ò4ù4ÿ4"525B55¯5Ì5×56‚6‹6”6™6«6³6Á6Ü677r7¬7Ù7ï78!8`8ˆ8—88Â8Ç8â8é899,939K9f9’9¥9ı9::;:b:q:x:”:¶:½:Ù:ÿ:;2;7;V;]; ;²;¹;Ø;<a<v<|<Ÿ<Ç<Ö<İ<ù<="=N=S=r=y=•=¸=è=%>P>’>˜>Ñ>÷>	??7?<?U?\??†?Ÿ?¦?¿?Ø?ß?ø?   @ 8  00@0E0^0e0Š00¨0¯0È0á0è011.151Z1_1x1›1Â1	202B2U2h2x2Ÿ2Ø2â2ó23!353P3d3x3Œ3¡3¶3Ë3Ü3ø34!464K4`4u4‰4«4Ä4Ü4595T5p5‚55½5Å5í56E6|6š6§6¬6½6×6ê6ò6û677777 7>7P7s7™7Ğ7î7û7 88+8=8E8N8T8[8b8i8n8s8}8¡8Ú8ş889d9 9Ä9ı9!:Z:~: ;•;¼;Ò;í;<<)<Q<g<{<”<ª<Á<Ø<ê<=-=A=R=`==¬=>>,>J>k>…>«>Â>Ö>ê>ş>?!?G?n??¢?ş? P (  F0t0Â0É0İ0ş01/1[1a1‹11¦1Í12212y2¨2­2Å2Ê2â2ç2ÿ233A3“3¯3À3Ñ3â3ó344&474H4Z4«4Î4Ö4ß4å4ì4ó4ú4ÿ45H5k5s5|5‚5‰55—5œ5¡5¼5â56+686=6b6|6˜6¨6°6¹6¿6Æ6Í6Ô6Ù6Ş6ù67C7h7u7z7Ÿ7¹7Õ7å7í7ö7ü78
8888*8:8`8…8™8§8Ö8Ş8å8ì8ó8ú899(9N9Z9l9w9…9©9Æ9Ô9ä9:::-:?:E:a:c;w; ;®;Ï;€<¸<=^=|==é=8>ö>G?[?Ğ? `   Z0e0{0‡00Ü0ö0191‚1—1°1Î1 222/2=2r222¾2333!3'3?3E3K3Q3W33»3Ğ3[4Î4ô45,5:5g5¡5¾5Í5Û5@6G6e6‘6˜6Ö6Ü67787I7Z7k7|7’7¤7¶7ñ7÷7l8»8ï8g9“9¥9À9Ó9å9”:±:¿:í:û:;;/;P;W;s;•;œ;¸;×;Ş;ú;<#<K<P<o<v<<£<Â<É<ñ<ö<==D=I=·=Û=õ=>/>v>£>¸>¿>è>í>??1?6?P?W?z??™? ?·?Ñ?Ø?ò? p 0  00*0D0N0e00Œ0§0­0Ç0Î0ï0ô0L11ô1$2;2N2a2t2†2Â2-3X3v3›3²3Ã3Ö3é3ü34C4J4€4š4å4ì4
535:5X55ˆ5¦5É5Ğ5î56676X6_6}6¡6¨6Æ6í6ô67A7H7^7„7‹7©7Ï7à7ô78&8=8«8Ø8ß89,9a9h9†9§9®9Ì9í9ı9:6:=:[:|:Œ:¤:Ç:Î:ì:; ;>;};„;º;Ô;<<-<N<U<s<”<¤<¼<ß<æ<=0=7=U=¾=à=÷=	>,>Q>n>>ˆ>>³>º>Ô>í>ô>?*?1?L?d?k?‚?Ÿ?¦?Ç?Í?ç?î?   € ü   00K0”0ù0%1D1˜1¹1À1ã12(262~2˜2²2ê233g3”33¦3®3³3Ş3ö34Q4]4§4à4é4ò4ú45535K5]5¢576~6Ä6 77"737D7V7n7‚77¯7À7Ñ7å7ü7'898T8b8~88Ê8İ8ã8/9¶9Ó9ç9ø9%:L:ù:q;…;™;ª;È;<5<<<]<i<‘<À<õ<="=b=o=w=€=†==”=›= =¥=Ü=ë=ó=ü=>	>>>>!>S>o>w>Œ>µ>é>b??»?Ú?       0–0£0µ0½0Ç0Ô0í0÷0 1J1[1n11“1§1¸1î122*2d2x2†22–2¦2¹2¿2ó233-3A3Z3o3t3ˆ3‘3½3Ü3444’4£4­4È4c5¦5¿506I6¥6­6Ã6Ê6Ğ6ğ6û677.7:7@7S7Y7p7‹7®7¾7Ó7Û7 88&8|88«8µ8Ì8Ò8İ89J9`9}9”99à9B:¬:;€;ë;'<t<ê<%=Z=z=ƒ=“=¨=±=ä=>!>*>:>O>W>~>>ç>?#?)?1?Y?x?¾?İ?ş?   ğ   020i0•0Ë0Ú0î0õ01)1_1h1—1Ù1õ1232H2P2g2—2´2Ø2í2õ23/3h3Œ3©3½3å34.4c4“4£4©4"5(595J5b5s55¦5Ó5ò526O6›6°6Ë6è647I7p7•7³7Ä7Ö7ú78d8‚8¡8Ş8949W9†9©9Ú9::F:m:‡:±:Ø:ò:;@;Z;…;¬;Æ;ô;<5<c<Š<¤<Ğ<ğ<==a==œ=°=õ=>2>t>”>¯>Ã>?%?@?T?™?·?Ö?   ° Ø   080S0g0¬0Ê0é0+1K1f1z1¿1İ1ü1A2_2~2À2à2û23Q3q3Œ3 3ê34Q4€4§4ê4ğ4ş4*5C5W5‹5Å5ê566/6Z6“6¢6¨6Í6ğ67_7l7¤7¸7v8Ÿ8É8á89'9‚9¢9½9Ò9$:D:_:t:Å:ã:;>;\;{;¸;Ø;ó;<H<h<ƒ<—<Ø<ø<='=i=‰=¤=¸=í=%>^>m>s>˜>¶>Å>å>??7?U?à?ï? À    0)080@0Y0{00¡0´0ø0%1F1`1Š1³1Ì1ó1ş12#272H2Z2q2v2Š2©2ğ2ö2<3T3Z3x3š3Á3454;4R4g4r4ˆ4³4¸4Ù4ğ4 5:5š5Í5à5ù5	66)676`6z6š6©6Ô6ä6717¥7½7ô7?8\8‰8˜8Ã8Ó8ü8#9Ÿ9·9î9;:T:j:Š:¦:¾:Å:Ü:;";>;Z;y;š;¹;ã; <<9<s<“<Ñ<ô<û<=T=u=¤=©=À=Ñ=Ö=÷=9>W>—>À>à>ü>$?D?[?‰?«?Æ?å? Ğ È   0P0¢0½0æ01(1=1E1l1‹1±1à1ı112`22›2É23+3v3ª3×3!474™4¹45,5a5³5Ò5646p66±6ã67?7^77³7Ò78.8Q8ƒ8¢8ß8ş8!9S9r9¯9Î9ñ9!:@:^:®:Ë:ê:õ:&;E;‡;¦;Í;<!<c<‚<©<Ş<ı<?=^=…=º=Ù=>8>^>“>²>ò>?7?]?ƒ?‰?‘?Á?à? à   00&0E0†0Æ01E11«1Î1ñ1292S2—2±2Æ2Ü2ï23<3[3ƒ3Æ3Ş304O4e4¨4À45 575B5Q5V5^5Š5©5Ç5ã5686M6]6r6x6©6Ä6Ø6ë6ñ6?7^7o7€7‘7¢7Á7Ç7æ7	8A8^8o8€8‘8­8³8Ñ8ò89*9@9L9Q9j9‹9¢9Ê9ç9ø9ı9:5:Y:€:›:´:ç:
;0;u;µ;Ñ;û;7<V<s<ˆ<Ê<ç<= =B=`=u=†=¬=Ï=Ô=ö=>>M>>–>Ç>û>?8?x?µ?¼?Ç?å?   ğ   0M0p0y0‰00§0Ê0æ0ï0ÿ011G1f1…1¶1Ó1í1*2k2ˆ2¢2ß2393s3²3Í34E4b4|4·4À4Ì4Ñ4á4ó4û4 55&5.5>5T5‡5¦5Ó5ı56$6I6e6n6~6“6œ6Ì6ï6ø677&7Q7p7Á7ì78\8i8s8Ÿ8í8$949F9Y9j9x9½9î9:9:[:©:¶:À:ì:=;t;„;–;©;º;È;<'<D<^<u<¡<¾<Ø<ï<=:=Y=‚=Ÿ=¹=Ï=û=>9>b>>™>²>Ú>ù>/?N?’?²?Ì?     0#000_0|0š0²0¿0ã0111F1f1‹1Ë1å1ÿ1212E2]2q2‰2ª2Ê2Ø2Ş2ş23%3X3r3¡3¹3Û3ï3û34%4C4O4j44µ4Î4ç45)5L55š5®5Á5ë566+6@6I6^66®6Ë6
7 7C7f7…7¡7Ğ7ê788848<8Q8t8¡8¾8ı8969Y9x9”9¹9Ô9è9ø9:::H:s::ª:Á:ı:;4;K;œ;¹;á;<<&<I<P<˜<·<Í<û<=Q=‰=¤=»=Ë=à=è=>->e>¦>İ>ü>5?T?q?…?­?Ì?  ì   0!0]0v0Š00Ê0ç01"181I1a1r1Š1¹1Ú12%2R2b2Œ2œ2¶2ä23?3^3€3²3Ñ34-4P4‚4¡4Ş4ı4 5R5q5®5Í5ğ5666<6D6t6“6´6Ä6İ6ü687W7y7¨7Ê7&8C8b8m8›8½8969U9`9‘9°9í9:/:a:€:½:Ü:ÿ:1;P;;¬;Ï;< <]<|<Ÿ<Ñ<ğ<-=L=o=Ÿ=¾=Ü=!>>>g>v>{>ƒ>µ>Ô>?2?V?|?Ÿ?¥?­?İ?ü?   $  0-0F0e0¡0À0â0131p11²1ä12@2_2‚2·2Ö2ô2@3]3|3‡3»3Ú3ø3D4a4€4‹4¹4Û475T5s5~5 5Ã5É5Ñ56 6A6Q6j6‰6Å6ä6787W7”7³7Ö7ù78"8*8Z8y8š8ª8±8ä89:9W9x99ˆ9“9¹9Ö9ú9:
::;:X:|:…:Œ:—:³:Ñ:Ú:á:ì:;%;.;5;@;[;y;‚;‰;”;²;Ï;ğ;ö;&<A<[<e<l<<”<Ÿ<º<Ø<á<è<ó<=7=Z=t=}=„==¸=Õ=÷=>A>a>j>q>|>§>Â>è>ı><?W?}?’?Ë?è? 0   00H0c0¡0®0ö01.1X11œ1¿1Å1Ş1ê1 2?2{2š2¼2î23J3i3Œ3¼3Û3÷364U4{4‚44³4Ò4î4-5L5r5y5„5ª5É5å5$6C6i6p6{6¡6À6Ü67:7`7g7r7˜7·7Ó7818W8^8i88®8Ê8	9(9N9U9`9…9§9: :?:J:l::•::Í:ì:;;6;U;};¬;Ç;<;<X<p<†<°<Í<ñ<÷<$=A=e=k=˜=µ=Ô=ı=>>>D>m>Š>¦>Ë>è>?)?F?b?‡?¤?Å?Ë?ô?   @   02080a0~0Ÿ0¥0Î0ë011;1X1y11¨1Å1æ1ì1272T2t2z2¾2Ù233+3c3€3¥3Ø3õ34B4_4€4‰44›4Á4Ü4ú45@5[5y55À5Ş5ú5!6N6l6ˆ6¯6Ü6ú67=7e7 7©7°7»7è78 8[8—8´8ß89!9=9f9ƒ9§9­9Ø9ú9:>:D:d:…:‹:²:Ñ:õ:;.;S;p;Œ;­;Í;ä;<4<_<‡<<¶<Ó<ô<ú<!=T=‘=²=Ğ=õ=û=!>A>X>†>¨>Ó>?@?›?¼?Í?ß?û? P 4  0t0}0„00¼0Ù0ş01;1D1T1i1r1˜1·1Ó12222;2K2`2h2Ÿ2¼2ë2ô23&3-3c3‚33º3í34B4a4§4Á4Ø4á4ñ455I5j5{5Œ5Ô5İ5ì566V6y6‚6’6§6°6×6ö6777V7r7™7¶7¿7Ï7ä7í7838O8k8Œ8’8·8Ş8õ89A9G9q9“9™9Ç9ì9ò9:@:]:z:™:³:Ò:ı:;7;@;P;e;m;–;³;¼;Ì;á;ê;<,<5<<<G<\<“<¾<Õ<	='=0=7=B=^=€=†=¯=Ë=Ù=ñ=>M>j>—>¸>À>à>?	?)?J?P?p?‘?—?º?Ö?ğ? ` ø   000J0–0±0Æ0Ö091T1i1y1Š1Ã1ä1ê12K2a2x2¤2Å2Ë2ë233>3Z3l3ˆ3¶3Ò3ä3 444O4`4r44¨4¯4µ4Ä4æ45505k5‹5š5Ä56:6K6^6w6~6•6Ç6ü67K7e7’7š7±7â7	8%8A8U8i8³8ü829A9U9\9‹9ª9é9:K:j:ª:Ï:ï:;;‚;¡;æ;<(<\<v<‹<¥<­<Ä<ú<7=Q=Y=p=˜=º=Ò=æ=ù=7>w>¸>õ>?-?F?e?¤?Á?ß?ù? p è   00N0k0z0‹0·0Ò0Ù0ğ01<1{1š1Ò1ò122,2S2m22™2¡2¸2à23B3j33´3è3 44R4m4‰4Ğ45.5l5¤5¿5à5 66@6v6‹6Å6â6ú67b77—7»7Ê7á7é7808[88¡8Ç8ç8(9G9œ9¹9Õ9:C:o:º:İ:ï:/;Q;s;“;¶;$<@<Q<–<¯<Ã<ÿ<=L=h=x=Š=æ=>>3>J>‚>£>È>Ô>Ù>?*?r?¡?À?ü?   €   0=0o00Ë0ê01?1^1›1º1İ12.2k2Š2­2ß2ş2;3Z3}3¯3Î34*4M444Û4ú45@5c5i5q5¡5À5á5ñ56A6i6Š6–6¤6»6Â6ñ67(747P7X7€7Ÿ7»7æ78*8A8O8V8r88—8¿8Ä8ã8ê89%979M9a9t9“9µ9Ù9ò9:::4:<:„:¨:Å:Ö:ç:ø:	;);6;@;p;;Ë;×;å;ÿ;<<5<K<j<†<±<×<û<B=h=ƒ=—=¸=Ø=ô=>?>_>{>˜>Â>ã>?"?0?7?S?q?x?”?¶?½?Ù?ø?ÿ?    (  0=0D0l0q00—0¿0Ä0ã0ê01161=1e1j1‰11É1Ö1å1ı12$2C2a2~2—2¶2Ê2ä23 393X3l3†3º3İ3ü344&4H4g4£4Â4á4585M5l5‹5ì5!6.6D6•6©6¶6Ï6Ö6ø6ı677?7D7^7e7|7–77·7Ñ7Ø7ï7	88*8D8Q8b8|8†88·8¾8Õ8919Q9`9g99£9å9:+:A:’:¦:³:È:Ï:ô:ù:;;;;@;z;™;õ;<"<Y<s<¡<³<Ë<ê<=/=N=”=»=æ=ü=M>Ÿ>×>õ>?#?0?>?U?\??Á?û?       D0g0§0È0ğ01+1S1q11Ÿ1¬1º1Ñ1Ø12"2A2P2]2k2‚2‰2»2Ú2363R3y3˜3³3Ä3ë3
4)4F4o4Œ4ª4Â4Ï4ı4585P5]5‹5¨5ß5ì56,6b66§6¶6Ù6à6*7~7–7£7Õ7ş78[8b88Á8ò8
99G9~9š9¹9Ş9 ::<:B:t:«:Ã:Ğ:ñ:;;L;ƒ;˜;ä;<1<D<V<w<Š<<°<Â<Ş<==U=o=z==£=ª=µ=Ù=>#>7>l>£>»>È>ğ>?#?4?`?†?–?«?´?Ù?ø? ° à   '0q00Ø0û01I1“1À1ú12;2I22Í2ú233<3Y3v3“3á34O44²4¿4ò4'5Z5r55¯5æ56k6›6Ì677=7[7Ÿ7½7à7888H8m88¯8Î8939Q9c9‡9¦9ß9ı9:U:k:}:Ï:í:(;/;F;j;‰;Ù;ö;<B<J<a<„<£<è<=P=o=§=Å=>$>[>v>>™>©>¾>Æ>ñ>?&?/???T?\?Š?¥?Á?ä?ê?   À ô   "0?0{00­0Ì0ğ0ö0/1\1‚1™1Ğ1ë122!262>2p2£2¬2¼2Ñ2Ù2
3?3H3X3m3u3£3Ç3å3ú3-4J4d4Ä4à45!5W5s5®5´5å5ş56#686h6‡6Ï6ï67{7˜7´7å78=8R8c88¬8é89N9m9£9Â9: :i:„:š:ª:¿:Ç:ö:;t;‘;§;»;ü;	<@<`<‚<¡<¿<ã<%=q==¬=Ä=Ñ=ù=.>K>~>º>Í>à>ó>??#?O?q?w?©?Í?î?   Ğ ä   0#0k0x0†00¤0Î0í0	1=1a1‚1›1º1Ü12P2]2k2‚2‰2¾2Ş2ú23Q3y3”3¯3İ3é34$404N4Z4˜4¿4ß4ù4
5&5M5‚5¬5Ì5è56.6;6\6w6ƒ6À6è6ù67=7ƒ7˜7İ78878w88œ8Õ8ü89:9f9{9È9ò9<:l:„:‘:Ç:ä:;?;\;‰;³;ê;<2<?<`<‘<È<Ù<=4=l=¤=Ü=>G>>Ë>?m??¥?Á?õ? à Ä   )0D0c0y0†00¥0İ0 111?1W1w1•1›1¿1ı182w2Û2*373x3ã3R4½4'5J5h5x5‰5ã56?6Y6…6£6Â6ş6!7R7y7“7¾7å7ÿ738V8t8„8ç89(9Y9{9›9¾9ÿ9":\:}:Ì:î:;1;q;‘;°;À;î;<.<Q<®<Ë<ø<=(=L=o=¦=Ù=õ=->M>n>>´>Ô>÷>-?P?‡?©? ğ ä   00F0K0i00Á0Ş0û0)1V1w1À1ã1232L22¿2Ó2Ü2ë233W3q3…333³3»3â344R4ƒ4š4£4²4Õ4Ü4585L5U5e5z5‚5±5Î5ï566P6o66Í6ä67+7?7P7f7n7Ÿ7¾7é7,8Q8o8€8Ş8÷89!999_9“9Ù9:E:¸:ç:e;™;É;ı;<<6<[<<¿<=V=–=ğ=>>Q>‰>É>2?H?\?h?¢?À?ã?     ø   00&0Z0y0˜0Á0à01a1¤1Á1ß1÷1272V2x2´2Ñ2ë2353P3W3b3†3È3ö384j4‡4£4¿4Ó455M5n5Š5¦5º5ï5÷56=6]6w6Œ6¾6Ë6ê67.7i7‡7¬7É7
88J8g8Ÿ8§8¾8ò89P9]9”9±9ï9ü93:P:‹:“:ª:Ö:ó:+;3;J;v;“;Ï;×;î;<<H<q<º<Ï<á<î<==,=D=[=‘=®=ì=ù=0>Y>¢>·>É>Ö>ë>??,?C?q??·?í?  Ü   
0H0U0Œ0©0ä0ì0101P1j1{1©1°1Ç1ø12#2S2„2«2Ë2è2 3X3u3­3Ë3è34@4M4€44Õ4İ4ô45B5^5†5·5Ú5B6h6è67*727d7Š7Û7â7888T8£8Æ8,9O9k9«9Ã9Ê9Ğ9ß9:*:F:‘:°:ÿ:;p;“;ç;ô;(<K<g<¶<Õ<'=D=|=„=›=È=è=>>A>H>_>>­>ì>ô>??+?]?|?Ë?ê?     ì   <0Y0‘0™0°0â0ÿ0:1o11¨1»1Ì1ı122I2p2‰2š2¹2	3(3C3‡3¤3Ü3ä3û3)4I4b4u4†4°4â45#565E5V5š5¡5¸5ä56%6t6‘6Ï6ğ67*7b7j77©7È7868ˆ8¥8Á899'9/9F9v9“9¯9ı9:9:S:£:À:Ü:;;;X;u;‘;Ï;ğ;<*<F<„<¥<Â<ß<û<6=C=v=“=¯=ê=÷=*>G>c>¤>±>Î>Ú>?/?K?ƒ?¸?Õ?ñ? 0 Ô   )0\0y0•0Ğ0İ0111M1ˆ11§1Ó1ğ12I2V22ª2Æ23(3E3b3~3Æ3ì3
4"464C4J4”4±4Í4æ4+5H5d5}5Ä5á5ı5P6m6‰6Ü6ù67l7‰7¥7ö7868P8i8o8·8Ô8ğ8<9Y9š9»9Ø9õ93:@:s::Ñ:ò:;,;j;w;ª;Ç;<<E<b<£<Ä<ß<ş<=`==Ò=ñ=>S>r>Ç>æ>9?X?s?¼?ß? @ è   0J0g0¥0Æ0ç01f1†1¯1Í1å1ì1ò1212P2w2«2Ê2å2+3M3l3¼3Û3ö334J4P4U4a4f4v4~44–4¤4­4¶4Ã4Ü4æ4ë4ò4ø455?5Q5x5…5Ç5Î5Ô5á576K6a6s66£67U7u7º8õ899›9 9Ç9::5:K:]:Ç:;*;;;«;ş;*<Y<m<„<˜<Ë<!=/=u=„=§=Ù=Ş=ı=>L>^>ˆ>È>Í>?2?F?g?ˆ?Ô?û?   P €  u0{0É0Û0r1•1İ1H2W2^2t2Œ2“2©2Ä2Ë2á2ù2 332393O3h3o3‰3¼3É3Ğ3Ü3î3:4G4N4Z4k4w4¶4¿4Ì4Ñ4ò4$585@5`5f5k5w5}5Œ5’5—5£5©5Á5Æ5Ñ5×5Ş5ë5ô5ú566'6,6C6[6i6Ÿ6´6Æ6Ï6ë6ò6ú6 747>7O7`7q7‚7Š7¤7©7Ä7Ö7ç7ı7F8P8U8a8n8s8ƒ8Œ8‘88¤8ª8é89/979L9Y9e9j9w9}9”9™9¹9Ê9Ø91:6:C:P:‰:¨:Á:Õ:ê:;+;B;_;€;‹;š;©;ã;ì;ù;<!<<<L<[<n<š<Ã<Ú<ì<û<===9=M=R=d=p=y=…=”=³=Î=Ø=>>%>6>>>J>P>W>\>l>s>€>‰>š>¦>®>½>Û>û>%?G?d?‘?¿?ã? `   040H0k0|0Š0§0°0Ê0Ø0á0	12191M1c1¹1÷3ş3444464;4A4H4V4\4b4’44©4²4Â4ó4ù4555)5.595?5D5U5c5t555»5Ê5Ï5Û5à5ê5ï5!6&636H6Q6m6x6’6 6²6ë6ú67777!7&71777<7S7a7•7³7Â7İ7ï7÷788(8.878=8T8Y8_8u8‚8‹8¨8º8Â8Ò8á8è8ğ8÷8 99F9O9l9}9¥9³9É9Î9à9å9÷9:!:@:N::—:É:Ó:é:ğ:;;W;ô?   p ¸   "050\0a0n0†0 0×0à011.1y1‚1Œ1¼1î112`2‘2š2Î23O3}3·3ù3 4R4\4‹4å4	5ù677*7;7@7E7\;j;–;Ö;ø;<<<F<c<t<œ<®<¸<Ä<è<==#=O=‡=›=±=Ó=Ø=å=ù=	>R>X>l>¡>®>è>??-?V?k?w?„?—?¯?¿?Ô?Ú?é?ó?   € ¨   0	0020I0w0Œ0Ì0Ú0ğ011%1q11”1¦1Ğ1ù12:22¡2à23J3P3X3^3h3¶3494Y4415`5¦6á67>7D7L7S7_7h7|7‚9Æ9: :h:ˆ:–:²:ì:;X;;;ü;<*<J<P<³<Ó<Ø<ê<
=%=K=ı=>$>K?l?Â?é?    0  0'0,090I00ˆ0µ0Ş0ù0ÿ0b1Š1ª1ù12!2H2a2p2€2¢2å2ñ233$313U3[3p3‡3’33Ë3Ñ3ß3ÿ3404B4N4h4s4‰4”4¡4°4ñ455(555A5J5e5}5‚5”5¿5ß5ñ566B6Q6ˆ66œ6¼6Ã6å6ğ6ÿ6-7?7c7p7ƒ77š7ª7Ï7Ø7ğ78S8b88 8Õ8ã8ù89ä9ò9ú9:+:8:O:`:|:–:Ô<ë<û<=/=>=C=x==§=¼=í=ı=>>.>4>:>I>ƒ>‰>>>®>·>Å>ğ>÷>ş>???/?A?Q?V?d?„??§?¶?È?×?        	00060<0A0M0S0b0h0m0y000˜0¤0À0Å01%1I1X1i11Ç1Ì1Û1222h2‹2¢2±2É2â2ç2÷23B3T3r3’3¢3§3Â3ù344-4:4I4Q4W4o4Œ4ª4Æ4Ô4Ú4ô45'535a5¨5İ5ì5616y6‡6¥6å67&757A7R7\7k7r77œ7Ë7ô7!8&848C8˜8Ö8ß8è8ñ8ú89/9J9Ÿ9®9Á9Ë93:?:r:Ÿ:µ:í:ö:;-;6;W;\;i;x;ˆ;;Ÿ;À;Õ;<<,<:<³<Å<=2=G=U==“=›=¡=«=?œ?ù? °   000?0€001@1`1–182g2­3ß3ı344:4B4I4U4^4r4x6¼6ò6.737@7R7o7¾7Ş7ì78J8j8x8”8È8è89K9Æ9x::Ÿ:¯;ó;W<^<|<<<¶<½<Ä<Ğ<ç<î<õ<ü<C=R=„==§=Ä=Õ=ü=)>E>`>p>}>‰>‘>—>>Å>â>è>î>ô>ú> ??????$?*?0?6?<?B?H?N?T?Z?`?f?l?r?x?~?„?Š??–?œ?¢?¨?®?´?º?À?Æ?Ì?Ò?Ø?Ş?ä?ê?ğ?ö?ü? À °  00000 0&0,02080>0D0J0P0V0\0b0h0n0t0z0€0†0Œ0’0˜00¤0ª0°0¶0¼0Â0È0Î0Ô0Ú0à0æ0ì0ò0ø0ş01
1111"1(1.141:1@1F1L1R1X1^1d1j1p1v1|1‚1ˆ11”1š1 1¦1¬1²1¸1¾1Ä1Ê1Ğ1Ö1Ü1â1è1î1ô1ú1 222222$2*20262<2B2H2N2T2Z2`2f2l2r2x2~2„2Š22–2œ2¢2¨2®2´2º2À2Æ2Ì2Ò2Ø2Ş2ä2ê2ğ2ö2ü233333 3&3,32383>3D3J3P3V3\3b3h3n3t3z3€3†3Œ3’3˜33¤3ª3°3¶3¼3Â3È3Î3Ô3Ú3à3æ3ì3ò3ø3ş34
4444"4(4.444:4@4F4L4R4X4^4d4j4p4v4|4‚4ˆ44”4š4 4¦4¬4²4¸4¾4Ä4Ê4Ğ4Ö4Ü4â4è4î4ô4ú4 555555$5*50565<5B5H5N5T5Z5`5f5l5r5x5~5„5Š55–5œ5¢5¨5®5´5º5À5Æ5Ì5Ò5Ø5Ş5ä5ê5ğ5ö5ü566666 6&6,62686>6D6J6P6V6\6b6h6n6t6z6€6†6Œ6’6˜66¤6ª6°6¶6¼6Â6È6Î6Ô6Ú6à6æ6ì6ò6ø6ş67
7777"7(7.747:7@7F7L7R7X7^7d7j7p7v7|7‚7ˆ77”7š7 7¦7¬7²7¸7¾7Ä7Ê7Ğ7Ö7Ü7â7è7î7ô7ú7 888888$8*80868<8B8H8N8T8Z8`8f8l8r8x8~8„8Š88–8œ8¢8¨8®8´8º8À8Æ8Ì8Ò8Ø8Ş8ä8ê8ğ8ö8ü899999 9&9,92989>9D9J9P9V9\9b9h9n9t9z9€9†9Œ9’9˜99¤9ª9°9¶9¼9Â9È9Î9Ô9Ú9à9æ9ì9ò9ø9ş9:
::::":(:.:4:::@:F:L:R:X:^:d:j:p:v:|:‚:ˆ::”:š: :¦:¬:²:¸:¾:Ä:Ê:Ğ:Ö:Ü:â:è:î:ô:ú: ;;;;;;$;*;0;6;<;B;H;N;T;Z;`;f;l;r;x;~;„;Š;;–;œ;¢;¨;®;´;º;À;Æ;Ì;Ò;Ø;Ş;ä;ê;ğ;ö;ü;<<<<< <&<,<2<8<><D<J<P<V<\<b<h<n<t<z<€<†<Œ<’<˜<Ò<Ø<Ş<ä<ê<ğ<ö<ü<=>>>>>">(>.>4>:>@>F>L>R>X>^>d>j>w>~>ƒ>¨>®>Ö>Ü>â>è>î>ö> ?.?6?<?G?T?\?j?o?t?y?„?‘?›?°?¼?Â?ä?ö?   Ğ ô   R0n0t0z0‡0”0¢0¨0®0´0º0À0Æ0Ì0Ò0Ø0Ş0ä0ê0ğ0ö0ü011111 1&1,121W1h1m1}1‚1—1°1µ1Ğ1Õ1å1ê1ù12222/2L2e2j22†2¥2ª2Ã2Õ2é2ı23%353:3I3V3h3m33•3¥3ª3µ3Á3Í3é3ù34454:4Y4^4u4z44¥4¹4É4Î4İ4æ4ë4ù455.5=5B5\5a5u5…55£5±5º5Ó5Ø5é5î5666)6A6F6   à ¼   Ô:Ø:à:ä:è:ì:ğ:ô:ø:ü: ;;;;;;;; ;$;(;,;0;¸;¼;À;Ø;ì;ü; <<,<4<<<H<d<p<x<”<°<Ä<Ğ<ì<ø<==(=D=L=X=t=€=œ=¤=¬=¸=Ô=à=ü=>$>,>8>T>\>h>„>Œ>˜>´>¼>Ä>Ğ>ì>ø>? ?<?H?d?p?Œ?˜?´?¼?Ğ?Ü?ğ?ü?   ğ à   00 0$0,040@0\0h0„0Œ0˜0´0À0Ü0è011,181@1p1„11˜1È1Ü1è1ğ1 242@2\2d2p2Œ2”2œ2¨2Ä2Ğ2ì2ô2 33$3,383T3\3h3„33¬3¸3Ô3à3ü34$4,484T4\4d4l4t4|4ˆ4¤4°4Ì4Ô4à4ü45$5,545<5D5P5l5t5|5„5Œ5”5 5¼5È5ä5ğ5ø5(6<6H6P6€6”6 6¨6Ø6ì6ø677   @   0000000 0$0(0ì5ô5ü566668888$8,848<8D8L8T8\8d8l8t8|8„8Œ8”8œ8¤8¬8´8¼8Ä8Ì8Ô8Ü8à8ä8è8ì8ğ8ô8ø8ü8 99999999 9$9(9,9094989<9@9D9H9L9P9T9X9\9`9p9t9x9|9€9„9ˆ99”9˜9œ9 9¤9¨9¬9°9´9¸9¼9Ğ9Ô9Ø9Ü9à9ä9è9ğ9ô9ø9ü9 :::::::: :$:(:,:0:4:8:<:@:D:H:L:P:T:X:\:`:d:x:|:€:„:ˆ:Œ::˜:œ: :¤:¨:¬:°:´:¸:¼:À:Ä:È:Ì:Ğ:Ô:Ø:Ü:ğ:ô:ø:ü: ;;;;;;; ;$;8;<;@;D;H;L;P;X;\;`;d;h;l;p;t;x;|;€;„;ˆ;Œ;;”;˜;œ; ;¤;¨;¬;°;´;¸;¼;À;Ğ;Ô;Ø;Ü;à;ä;è;ğ;ô;ø;ü; <<<<<<<< <$<(<,<0<4<8<<<@<P<T<X<\<`<d<h<p<t<|<€<ˆ<Œ<”<˜< <¤<¬<°<¸<¼<Ä<È<Ğ<Ô<Ü<à<è<ì<ô<ø< ======$=(=0=4=<=@=H=L=T=X=`=d=l=p=x=|=„=ˆ==”=œ= =¨=¬=´=¸=À=Ä=Ì=Ğ=Ø=Ü=ä=è=ğ=ô=ü= >>>>> >$>,>0>8><>D>H>P>T>\>`>h>l>t>x>€>„>Œ>>˜>œ>¤>¨>°>´>¼>À>È>Ì>Ô>Ø>à>ä>ì>ğ>ø>ü>????? ?(?,?4?8?@?D?L?P?X?\?d?h?p?t?|?€?ˆ?Œ?”?˜? ?¤?¬?°?¸?¼?Ä?È?Ğ?Ô?Ü?à?è?ì?ô?ø?   P l   000000$0(00040<0@0H0L0T0X0`0d0l0p0x0|0„0ˆ00”0œ0 0¨0¬0´0¸0À0Ä0Ì0Ğ0Ø0Ü0ä0è0ğ0ô0ü0 11111 1$1,10181<1D1H1P1T1\1`1h1l1t1x1€1„1Œ11˜1œ1¤1¨1°1´1¼1À1È1Ì1Ô1Ø1à1ä1ì1ğ1ø1ü122222 2(2,2024282@2D2L2P2X2\2d2h2p2t2|2€2ˆ2Œ2”2˜2 2¤2¬2°2¸2¼2Ä2È2Ğ2Ô2Ü2à2è2ì2ô2ø2 333333$3(30343<3@3H3L3T3X3`3d3l3p3x3|3„3ˆ33”3œ3 3¨3¬3´3¸3À3Ä3Ì3Ğ3Ø3Ü3ä3è3ğ3ô3ü3 44444 4$4,40484<4D4H4P4T4\4`4h4l4t4x4€4„4Œ44˜4œ4¤4¨4°4´4¼4À4È4Ì4Ô4Ø4à4ä4ì4ğ4ø4ü455555 5(5,54585@5D5L5P5X5\5d5h5p5t5|5€5ˆ5Œ5”5˜5 5¤5¬5°5¸5¼5Ä5È5Ğ5Ô5Ü5à5è5ì5ô5ø5 666666$6(60646<6@6H6L6T6X6`6d6l6p6x6|6„6ˆ66”6œ6 6¨6¬6´6¸6À6Ä6Ì6Ğ6Ø6Ü6ä6è6ğ6ô6ü6 777777 7$7,70787<7D7H7P7T7\7`7h7l7t7x7€7„7Œ77˜7œ7¤7¨7°7´7¼7À7È7Ì7Ô7Ø7à7ä7ì7ğ7ø7ü788888 8$8(8,84888@8D8L8P8X8\8d8h8p8t8|8€8ˆ8Œ8”8˜8 8¤8¬8°8¸8¼8Ä8È8Ğ8Ô8Ø8Ü8à8è8ì8ô8ø8 999999$9(9,90949<9@9H9L9T9X9`9d9l9p9x9|9„9ˆ99”9œ9 9¨9¬9´9¸9À9Ä9Ì9Ğ9Ø9Ü9ä9è9ğ9ô9ü9 ::::: :$:,:0:8:<:D:H:P:T:\:`:h:l:t:x:€:„:Œ::˜:œ:¤:¨:°:´:¼:À:È:Ì:Ô:Ø:à:ä:ì:ğ:ø:ü:;;;;;; ;(;,;4;8;@;D;L;P;X;\;d;h;p;t;|;€;ˆ;Œ;”;˜; ;¤;¬;°;¸;¼;Ä;È;Ğ;Ô;Ü;à;è;ì;ô;ø; <<<<<<$<(<0<4<<<@<H<L<T<X<`<d<l<p<x<|<„<ˆ<<”<œ< <¨<¬<´<¸<À<Ä<Ì<Ğ<Ø<Ü<ä<è<ğ<ô<ü< ===== =$=,=0=8=<=D=H=P=T=\=`=h=l=t=x=€=„=Œ==˜=œ=¤=¨=°=´=¼=À=È=Ì=Ô=Ø=à=ä=ì=ğ=ø=ü=>>>>> >(>,>4>8>@>D>L>P>X>\>d>h>p>t>|>€>ˆ>Œ>”>˜> >¤>¬>°>¸>¼>Ä>È>Ğ>Ô>Ü>à>è>ì>ô>ø> ??????$?(?0?4?<?@?H?L?T?X?`?d?l?p?x?|?„?ˆ??”?œ? ?¨?¬?´?¸?À?Ä?Ì?Ğ?Ø?Ü?ä?è?ğ?ô?ü?   ` `   00000 0$0,00080<0D0H0P0T0\0`0h0l0t0x0€0„0Œ00˜0œ0¤0¨0°0´0¼0À0È0Ì0Ô0Ø0à0ä0ì0ğ0ø0ü011111 1(1,14181@1D1L1P1X1\1d1h1p1t1|1€1ˆ1Œ1”1˜1 1¤1¬1°1¸1¼1Ä1È1Ğ1Ô1Ü1à1è1ì1ô1ø1 222222$2(20242<2@2H2L2T2X2`2d2l2p2x2|2„2ˆ22”2œ2 2¨2¬2´2¸2À2Ä2È2Ì2Ğ2Ø2Ü2ä2è2ğ2ô2ü2 33333 3$3,30383<3D3H3P3T3\3`3h3l3t3x3€3„3Œ33˜3œ3¤3¨3°3´3¼3À3È3Ì3Ô3Ø3à3ä3ì3ğ3ø3ü344444 4(4,44484@4D4L4P4X4\4d4h4p4t4|4€4ˆ4Œ4”4˜4 4¤4¬4°4¸4¼4Ä4È4Ğ4Ô4Ü4à4è4ì4ô4ø4 555555$5(50545<5@5H5L5T5X5`5d5l5p5x5|5„5ˆ55”5œ5 5¨5¬5´5¸5À5Ä5Ì5Ğ5Ø5Ü5ä5è5ğ5ô5ü5 66666 6$6,60686<6D6H6P6T6\6`6h6l6t6x6€6„6Œ66˜6œ6¤6¨6°6´6¼6À6È6Ì6Ô6Ø6à6ä6ì6ğ6ø6ü677777 7(7,74787@7D7L7P7X7\7d7h7p7t7|7€7ˆ7Œ7”7˜7 7¤7¬7°7¸7¼7Ä7È7Ğ7Ô7Ü7à7è7ì7ô7ø7 888888$8(80848<8@8H8L8T8X8`8d8l8p8x8|8„8ˆ88”8œ8 8¨8¬8´8¸8À8Ä8Ì8Ğ8Ø8Ü8ä8è8ğ8ô8ü8 99999 9$9,90989<9D9H9P9T9\9`9h9l9t9x9€9„9Œ99˜9œ9¤9¨9°9´9¼9À9È9Ì9Ô9Ø9à9ä9ì9ğ9ø9ü9::::: :(:,:4:8:@:D:L:P:X:\:d:h:p:t:|:€:ˆ:Œ:”:˜: :¤:¬:°:¸:¼:Ä:È:Ğ:Ô:Ü:à:è:ì:ô:ø: ;;;;;;$;(;0;4;<;@;H;L;T;X;`;d;l;p;x;|;„;ˆ;;”;œ; ;¨;¬;´;¸;À;Ä;Ì;Ğ;Ø;Ü;ä;è;ğ;ô;ü; <<<<< <$<,<0<8<<<D<H<P<T<\<`<h<l<t<x<€<„<Œ<<˜<œ<¤<¨<°<´<¼<À<È<Ì<Ô<Ø<à<ä<ì<ğ<ø<ü<===== =(=,=4=8=@=D=L=P=X=\=d=h=p=t=|=€=ˆ=Œ=”=˜= =¤=¬=°=¸=¼=Ä=È=Ğ=Ô=Ü=à=è=ì=ô=ø= >>>>>>$>(>0>4><>@>H>L>T>X>`>d>l>p>x>|>„>ˆ>>”>œ> >¨>¬>´>¸>À>Ä>Ì>Ğ>Ø>Ü>ä>è>ğ>ô>ü> ????? ?$?,?0?8?<?D?H?P?T?\?`?h?l?t?x?€?„?Œ??˜?œ?¤?¨?°?´?¼?À?È?Ì?Ô?Ø?à?ä?ì?ğ?ø?ü? p „  00000 0(0,04080@0D0L0P0X0\0d0h0p0t0|0€0ˆ0Œ0”0˜0 0¤0¬0°0¸0¼0Ä0È0Ğ0Ô0Ü0à0è0ì0ô0ø0 111111$1(10141<1@1H1L1T1X1p1x1Œ1È1Ğ1Ô1ä1 2(2<2X2t22¬2è2ğ23@3H3\3˜3 3´3ğ3ø34H4P4d4 4¨4¼4ø4 555P5X5l5¨5°5Ä5à5ü5646p6x6Œ6È6Ğ6ä6 7(7<7x7€7”7Ğ7Ø7ì7(808D8€8ˆ8œ8Ø8à8ô80989L9ˆ99¤9à9è9ü98:@:T::˜:¬:è:ğ:;@;H;\;˜; ;¤;´;ğ;ø;<(<D<€<ˆ<œ<Ø<à<ô<0=8=L=ˆ==¤=à=è=ü=8>@>T>>˜>¬>è>ğ>?@?H?\?˜? ?´?ğ?ø? €    0H0P0d0 0¨0¼0ø0 11P1X1l1¨1°1Ä1 22282T2p2Œ2È2Ğ2ä2 3(3<3x3€3”3Ğ3Ø3ì3(404D4€4ˆ4œ4Ø4à4ô40585L5ˆ55¤5à5è5ü586@6T66˜6¬6è6ğ67@7H7\7˜7 7´7ğ7ø78H8P8d8 8¨8¼8ø8 99P9X9l9¨9°9Ä9 :::X:`:t::¬:è:ğ:;@;H;\;˜; ;´;ğ;ø;<H<P<d< <¨<¼<ø< ==P=X=l=¨=°=Ä= >>>X>`>t>°>¸>Ì>??$?`?h?|?¸?À?Ô?    ,  00,0h0p0„0À0È0Ü01 141p1x1Œ1È1Ğ1ä1 2(2<2x2€2”2Ğ2Ø2Ü2ì2(303D3€3ˆ3œ3Ø3à3ô30484L4ˆ44¤4à4è4ü485@5T55˜5¬5è5ğ56@6H6\6˜6 6´6ğ6ø6ü67H7P7d7 7¨7¬7¼7Ø7888,8H8€8ˆ8œ8Ø8à8ô80989L9h9„9 9¼9ø9 ::P:X:l:ˆ:¤:À:Ü:; ;4;p;x;Œ;È;Ğ;ä; <(<<<x<€<”<Ğ<Ø<ì<(=0=D=€=ˆ=œ=Ø=à=ô=0>8>L>ˆ>>¤>à>è>ü>?4?p?x?|?Œ?È?Ğ?ä?   h   0(0<0x0€0”0Ğ0Ø0ì0(101D1€1ˆ1œ1Ø1à1ô10282L2ˆ22¤2à2è2ü283@3T33˜3¬3è3ğ34<4@4D4H4L4P4T4X4\4`4d4h4l4p4t4x4|4€4„4ˆ4Œ44”4˜4œ4 4¤4¨4¬4°4´4¸4¼4À4Ä4È4Ì4Ğ4Ô4Ø4Ü4à4ä4è4ì4ğ4ô4ø4ü4 55555555 5$5(5,5054585<5@5D5H5L5P5T5X5\5`5d5h5l5p5t5x5|5€5„5ˆ5Œ55”5˜5œ5 5¤5¨5¬5°5´5¸5¼5À5Ä5È5Ì5Ğ5Ô5Ø5Ü5à5ä5è5ì5ğ5ô5ø5ü5 66666666 6$6(6,6064686<6@6D6H6L6P6T6X6\6`6d6   P    X0\0`0d0h0l0 ğ    €;„;ˆ;Œ;;”;˜;p?ˆ?¨?      è0ì0ğ0ô0ø0ü0€3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          NB10    ¸‘J   C:\Documents and Settings\ashok\My Documents\src\twapi\twapi\base\build\release\twapi.pdb 