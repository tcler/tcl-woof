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
MZ�       ��  �       @                                     � �	�!�L�!This program cannot be run in DOS mode.
$       �c����������ϩ�����Q����Ͻ����Ͻ����Ͻ����������τ����ϰ������������ϩ ���!������!����������-"�����Rich���        PE  L ��J        � !  �  �     ��     �                         �    �u                        : [    � �    H                     �_  ��                                             � �
                          .text   O�     �                   `.rdata  {Z   �  \   �             @  @.data   D�  @  �  (             @  �.rsrc   H        �             @  @.reloc  na      b   �             @  B                                                                                                                                                                                                                                                                                                                �V�t$WV�4 3�Y;��<  �d	h�	h�	h�	h�	��d  V�|F ����uGh�����u?jW�(�h�	��	�   � ���u�d	Wh�@V���  ��jX��   �d	WWhW h�@V���  �d	WWh[ h�@V���  �d	WWhP h�@V���  �d	WWh�# h�@V���  �d	��PWWh�Nht@V���  �d	WWh�Mh`@V���  �d	WWh#GhH@V���  �d	Wh  ��|  ��D3�_^�U���@  SVWjX3�9E�u��u��E����}8�d	h�B�uj�u��(  �d	j���  �!  P�u����	  9E�}�]�E���   �E��4��d	��X  Ph�B趺 ����u�E�   �   �E��4��d	��X  Ph�B臺 ����u	�E�   �U�E��4��d	��X  Ph�B�[� ������   �E�@;E�E���   �M�Q�4��d	S���   ������   �E��E�;E�A����d	h   V�wS��  ��;��$  �M�Q�M�QP�d	S���   �����  �E�P�E�P�d	�wS���   ������  �}�   ��   �d	VhlBS���  �d	j���  �0   PS����  VhLB�VhB�d	S���  ���+�M��d	j hB�4���   ��X  YPh�AS����d	j���  ��  PS����=  9u�u�:  �������}�E�P�E�P�E��4��d	�u���   �����  �E��^S�0�d	���   �3��F   �F�Fj.�F�6�d	��(  ��������   +G��:�Auh�AW�r� Y��Yu	�F   �n�:�Auh�AW�N� Y��Yu!F�N�:�Auh�AW�.� Y��Yu	�F   �*�:�A��  h�AW�� Y��Y�~  �F   �}�~�E��}��H�N~�@�F�E���E;E������3��d	VV���   �Eܡd	VV���   ��9u�E�u��  �E���E�P�E����4�d	���   ��YY�?-��  �G�_����  <-u
� ��  3�9M�M��  �U��I��J9�����u"�M�IQS�������d	���  �M�����t	A;M�M�|�;M���   �I����������   �d	j���   Y�M��I���������   �Mԡd	j hB�4���   ��X  YPh�A�u��d	j���  �<  P�u��� �  �d	j hBWh�A�u��   �ËM�I9M��   �M��E�L�������e�}� ��   �E��4�d	�u��u���   �E��H9E}8�E��t�d	��X  �8-Yt �E�E�M�4��d	�u��u���   ���E�E;E��6���3�9]��9  �������F��t�M�Q�M�QP�u�d	���   ��3�9u�~t�F�;�u	9M���  ��F+��4  H��   HtVH��   �~  j hBWh�A�j hBWhlA�u�d	��   �d	j���  ��  P�u��� �  �;�u�d	j ���   Y���M�QP�u�d	���  ������  3�9~��   9}��}���   �E�P�E��4��d	�u���  ������  �E�;E�u�E�;E���   G;}��}�|��   �;�uj �"�M�QP�u�d	���   ������  �u��d	���   �e� Y��`9u�d	j h����   Y�Y�~ tR3�9}��}�~6�6�d	��X  YP�E��4��d	��X  YP�� Y��Yt	G;}��}�|ʃ~ t�E�9E��*  �v��d	�v􍸸   ���   P�u��u��6�d	�u��u���   �� C��;]�������M�E+�9M��&  �d	j���  �  P�u��d	j hDA�u���  �M�E����h@AQ�M�+�Q�u�d	���  YP��
  ���  �[��������������������h4A�B�[��������������������hA� �[��������������������hA�u��   ���   �[��������������������hA�u��   �d	j h�@�u��   �� h�@�u��u�����;E�}#�u�E��4��d	�u��u���   ��F;u�|��Eh   �u�j �p�d	�u��  ����u;�E܅�t��8 P�d	���   Y�E��t��8 P�d	���   YjX��u�d	�u���  Y3�Y_^[��U��d	VWj h����   Y���d	Yj h�B�u�pD��X  YPh�B�uW��u�d	�uW�PH�d	jhBW�PH�d	W�u���  ��8_^]�U���$S�]V��W��  ���   ��  ������$��� �ۋ�~�M��+ϋӋ4�0��Ju��e� j^�};���   �E�   �E�   �_�3�d	��X  Ph�C趰 ����u�E�;E�1  �E������E��I�3�d	��X  Ph�C�{� �����1  �E�;E��   �}� �  �E��u�F��F�E�;u�s����]�d	j �wS���  �����E�{  P�d	j h�CS���  �����\  �M�Q�M�QP�d	S���   �����<  �}� ���E��E�~/�E��0�d	��X  �}�Y�E�~�E��p�d	��X  Y�E��EjY���;��M�E���  �w�E;E�ux�M���(  �u�d	��l  �d	�$|C�uj�u��(  ��jX��  �u�d	��l  �d	Yj h<C�7��   ��X  YPh C�u���뾍EP�E�P�d	�6S���   ����u�9E���   �E�0�d	��X  P�u��Ʈ ����uu�}���   �E�p�d	��X  P�u�蛮 ����tb�E�P�E�p�d	S���   ����u-�E��8 t%�E�P�E��p�d	S���   ����u�E�;E�t�E���E;E���   �����d	S�p|���  P���S��d	��l  S��  �����EtH�d	h   Vj hCS���  ����u�E   �}t�Ej �t��d	S���  ���E��> �d	V���   Y�}� tL�uS�  ��d	S��l  �E�j �t��d	S���  �����EVSu	�[  YY�
�<  Y�EY�E�e�_^[��U��Q�}SVW��   �}��   �]�E�P�EP�d	�s�u���   ������   �EtP�d	hD�u���  ���   �s�d	��X  3�Y9u��~,�E��4��d	��X  Y�:uPW諬 Y��Yt$FF;u|ԃ}u �s�u�d	���  Y3�Y�G�E��t���d	j h�CWh�C�u��   ����d	h�C�uj�u��(  ��jX_^[��U���8�d	SV�u�p|���  P��؍EȾ@@P�d	V�u���  ����uP�d	h\D�u��   ���   �d	W���WV���   �E�d	WhC���   �E�d	WhPD���   �E�d	Wh�C���   �� �E�M�j_�׋�� Ju��E�PW�u�u��Ũ��E��u�}�����8 P�d	���   Y��M�u�}�_u��; �d	S���   YjX��d	S�u���  Y3�Y^[��U����=�	��   �=�	��   �d	S�]VWS��   �x|�����  P�j�E�d	j hPDS���  ���E���u�d	���   �E�d	jj h�CS���  ���E��u�d	���   �E��d	V���   �u�E��d	���   �E��E�P�d	j���   ��� _^[���u�d	�u��d  YY��U����=�	��   �=�	��   SV�u�EWP�E�3�P�d	VS���   ����u@�}�u:�E�P�E�p�d	S���   ����u�E�P�E�p�d	S���   ����t�d	hxD�PY�E�}j�p�d	Sh�CW���  �Ej�p�d	ShPDW���  �E�0�d	W���  �E���0	�   �9�d	V���   Y�E�_^[���u�d	�u��h  YY�Ã=�	u"�=�	u�D$��8 P�d	���   Y��t$�d	��l  Yád	j j ���   P�d	�t$���  ��3��U���P�u�$�Y�M���t3��Ã} t:�u�E�h�DjPP�(�j �E��uP�d	�u��   j j�u��  ��,h ���jX��U��QQW�u�n� 3�Y9}�E�~OSV�u�E�P�d	�6���   Y�؅�Y~�u��d	�u�u�PH���u��d	S�u�PH��G��;}|�^[�E_��SV�t$�t$�f �f �f �   �F   ���؅�th�DS����tV��S��^[�W�|$��t�d	VW���  �0�PW�YY^_ád	j h����   YY_�U���P�EP�d	�u�u���   ����uO�E;E|;E�M��t�3��Ã} t/�u�uPh�D�E�jPP�(��E�jP�d	�u���  ��$jX��U���V�u�P�d	���   �E��FP�d	���   �E��FP�d	���   �E��FP�d	���   �E��F
P�d	���   �E��FP�d	���   �E��FP�d	���   �E��E�P�d	j���   ��$^��U��QQSV�E�WP�E�P�d	�u�u���   �����Z  �}��}}W���E�3�3�+�f�_
f�_f�_�<  H�  H��   H��   H��   HtYHt,�EP�E�hkx  S�0�u�U���������   f�Ejf�^�EP�E�jj�4��u�*���������   f�EFf�G�EP�E�jS�4��u����������   f�EFf�G�EP�E�h�  S�t��u���������unf�Ef�G�EP�E�j<S�t��u��������uIf�Ef�G�EP�E�j;S�t��u��������u$f�Ef�G
�EP�E�jS�4��u�f�������tjX�
f�Ef�G3�_^[�ËD$�p�0�d	���  YY�U��QQ�E�P�d	�u�u���  ����tjX�ËE��t�M���M��H3��ËD$�p�0�d	���  YY�U��QQ�E�P�d	�u�u���  ����tjX�ËE��t�M���M��H3���U��QV�E�3�PVV�u�u��\���t�d	Vh����   YY��u��0���Y���u��X���^��U����EV3�;�u�E�P�d	VVV�u���  YYP�`�;�}9utVP�u��  ��jX�3�^�ËT$V���J�2���t�4��H����+�@@P�d	R���   YY^�U��EVP�d	�u���   �}YY��}�E�  �W�Ί��u8Qt�A����U���;�8)E����u�,��M���u9Et2PhE��uVP����3��j h�D�u�d	���  ��jX^]Ã|$ t
�t$�0��U���P�} t&�E�j(P�u�4���t�E�j�P�d	���  ��d	j h����   YY��U��EP�u�����t3�]ád	Vj��u���   Y��Y�EP�����^]��t$�d	�t$��X  YP�����u�j P�t$�(
  ��jXËD$���Q�p�d	���  YY�U����   ��,���VP�d	���  ��,���P�u�u�%   ������u��,���P�d	�u���  YY��^��U��Q�u�d	���  Y�E�P�u�p���u59Et+P�d	h0E�u���  ��j ���P�u�b	  ��jX�ád	j��u��u���  ���u�� �3���U����   ��,���VP�d	���  ��,���P�u�u�V���������u-�d	j���,������   �M���,���P�d	���  ����^��U����ESVW3��]�8�EP�d	W3��u�}�S���   ������   9}t2�u�d	���  �M�F�D�E��EP�d	V�uS���   �����E��E�P�E��PWS�1�������uo�u�EP�}�W�u�d	S���   ����tC9}tM�E�P�d	�u���  Y;�Yt�E��M��QPV���E����4F�E��EP�u���u���YjX��Mf�>�E�3�_^[��U��Q�d	SV3�WVV���   �}Y;�Y�E�tYf97tTW���ءd	SW���  ��V�u���d	�u���   ����t(��> �d	V���   Yf�|_ �|_u��E�_^[����> �d	V���   Y�u��0  Y3���U��EP�d	�u�u���   ����u(�E�  ��t#�} t�d	j hPE�u���  ��jX]ËMf�3�]�U��SV�5��W�}j W��jW�E��jW�����u3�;��u�uWt9P�u�Ӄ��}��u09ut�u�d	��h  YVV�5��W��j jW��������_��^[]� U���4SV3�Wf95��xEu=j0�E�[SVP�� ���Ẻ]̉u�P�E�   �E�I. �}����f;�f��tVVVVVVVVVVWV���;ƉE�uV���P�u��  ���   �u�d	��,  YV���u�=��V�u��׋����u�Ӆ�u(�uj�u��ׅ�u�Ӆ�u�uj�u��ׅ�u(�Ӆ�t"V��P�u�W  �u�d	��h  ��jX��E;�t�M��VVh �  �u����3�_^[��U��� S3�V�uW�]�]��]�� �j_98~�jP��YY�����	�A����tF�̊<-uF�}��<+uF�M��u6�>0u%�FF<xt<Xt�}��E   �8F�E   �   �E
   �   ��u�>0��   �~x��   FF��ud�>��0����  �E�jY���� j�E�Y�U��� ;E���  ;���  3�}�]�}�;]���  w	;}���  �E�   F뜃�
ug�>��0��	�Q  j j
S�u��T� j j
RP�E��U��ӛ ;E��X  ;��P  3�}�]�}�;]��<  w	;}��1  �E�   F뙃�ut���0��J��   ���E����   �E�jY���8� j�E�Y�U��
� ;E���   ;���   3�}�]�}�;]���   w	;}���   �E�   F댃�|{��$v���0��Jwk��M���E;�s[��S�u�RP�E��U��W� �u�E��U��u�RP�Ԛ ;E�u];�uY3�}�]�}�;]�rIw;}�rB�FF��0��J�E�   v�3�9M�t�E���ىE���9M�u�u�E;�t�0�E��_^[�����M� "   ��t���0��Jw���E;EsF��1�������U���   �M��|��s9��Eu	���E�3Ҹ�E9t��B= Fr�����E��uQ�E�h�FP������E�j�P�d	���   YY��U����d	jh G���   �u�E��d	���   �u�E��Z����E��E�P�d	j���   ����U���`VWj �u�  ��Y��Yur�}4  �5��r6�}�  w-����ujPh�G�օ���tP�u��  ��Y��Yu-����ujPh�G�օ���tP�u�  Y��Y��t���5�}xuh0G���Y�!�u�E�hGj0P����E�P�����_^��U���8�d	Vjh�G���   �u�E�d	���   �u�E�����������t#V��P�d	V���  V�E������+�u�E�h�Gj(P�(��E�j�P�d	���   ���E��E�M�Q3Ʌ����E��d	��Q���   YY^��U��W�}��ujX�   S�u�u�0����؍EP�d	jSj ���   ����u\9EtW�d	VW���  ��d	V���  Y��Yt�d	jh�GV��  ���u�d	V���  �d	VW���  ��^�d	SW���  YYjX[_]�U��QQSV�u3�WP�E�P�E��   ��PS�u��uf�� ���   ��   V�������~�u�V���Y�E�V�Ij �E�j PS�u�uV�����3�;�~1�w�6P�$�;�Y�E�tEVf��u�V�u�SS����u�� ��E���t"��~f�|x�
uO��~	f�|x�uOf�$x �E�_^[��U���
  V��  9uu$������h   P������h   P�E�P�� �E�j �u�u�;�����9uui�}� uc�u�d	���  ��d	jh�GV��  ������j�P�d	V��  �d	jh�GV��  ������j�P�d	V��  ��4jX^��U��} t�d	j�u�u���  ��j �u�u������jX]�U����ESVWj3�^;��M�M��M��u�u�d	Qh�u���  ������  �}�@;��u�E���   �d	Q�v���   ��ESP訔 ����uj�]h�u萔 Y��Y��   ��u�E�E�   �E��   ����   �Ej �v�E��d	���   SP�I� ����urjX;��  �4��d	�e� �P|�}� Y��uj �d	V���   Y�E�Y�]j�C�0�E�PV�u�4  ����ur��> ��   �d	V���   Y��   �E�   3�9]���   �E�+���QW�uS�U���;���   �d	�u�p|���  P�9]�YY���u���S�^���j�$���Y�7��E�_�G�E���Gt	�u��O   Y�d	h�< WhH= �u��u���  ���G3��#j h��Sh��u�d	���  ��jX_^[��U��Q�=@ V�Pu�d	jV���  Y�@   Y�E�P�uV����^��U���u�d	�u�uj �u���   YYP�u�   ��]�U���\SV�uW3��>_�#  �Eh�V�8�n� Y��Y��  �d	j�V���   �E��d	j�h����   �E��d	j�h���   �E��E�]W� �E�� �E�� �E�P�d	jS���  ���E��(��E�98P�d	���   Y�E���E�98P�d	���   Y�E���E�98P�d	���   Y;���   �d	�MQS���   ���  YP�YY�M��P��   AQP�E�P���d	S�u���l  ���}�_�����jF�uV�@  �u��;�t{VP�{   ��Y;�YuO�Et'�d	Wht�u���  �6�d	�u��  ��jX�<�Et��d	WhTS���  �����E�ut�6�   Y�6S�q   Y�Y3�_^[��VW�|$��tW�w�t$�6諐 Y��Yt�v��t<;wt7��;wt,�F�N�H�F��t�N�H�G�F�G��t�p�w�~���3�_^ËD$��t�@��t�t$��YËD$Ã=@ t&�t$hP�|Y��YtP�d	���  YjX�3��SV�t$W�|$V2��B� Y�L$�	;�|N��~J�F��0|
��9�����a|��f	�����F��0|	��9,0���a|	��f,W
؈GIu���_^[�V�t$��t#�~ t�v�D�����Yt�F�@��t�v��Y����8 P�d	���   YV��Y^�U���   SVWjX3�9E�]��E�}Sh���  �}�d	S�w���   ��h,V�u��� ����u�E�p�@   �����Y�_  h$V�ێ Y��Yu�u9^t	�v����Y�^�5  hV豎 Y��Yu�E�p�d	�u���  Y먋u��������������F�]��������������E��M����	t$�I����t�E@�E���E���]�����Ѕ�u�M��m���}� �]���  볋I@�ɉ�Mt$��M�	��t�u�Q�� Y��Y��  �Eu�h��u��� Y��Y��   �}P������w�d	���   �E�EY� Y�X��t#���t�uP衍 Y��Yu	9C�`  ��u�h�u耍 Y��Y��  h�u�i� Y��Y��  �]������h�u��J� Y��Y������}��  jX9E�E�������_�d	j �3���   �E�EY� Y�@���E�tt��E� ��ti�uP�� Y��YuT�M�9AtL��E����� �C�Pj�uV�Q�E�E��������8 P�d	���   Y�E����  �E��E�u��E����E�;E�V���������_W�G�u��u� �EV�P�E�_�����6�> �d	V���   Y�E��^  �GW�E��j�G�u�� V�S�؋E��G�����6�> �d	V���   Y���  �d	�6���  �P|P�u����M�v��   Y��j th �h��u�d	���  ��j �q���h�u�蕋 Y��Yu�E9E�|3��   h��u��s� Y��Yuj h��u�d	���  ���|�d	3�Sh��u���  �F��;�t\�x��tE�? t@�u�d	���  Y�7j:P���YYP���Y��Yu�7�d	�u��  YY��u��F�@�����u�jX_^[�Ã=@ u3���t$hP�|��Y�Y��ád	Vj���  j����t$�d	V��P  �d	V��P  ��^ËL$��t�����d	Q���   Y��   �t$��t����m� Ã=4 u.����uhP������th8P���4�4������ujWXj P�t$�e�����ËL$�T$�d	V�4
���  ���   P�t$���3�^ËL$�T$�d	V�t$э��  R���   P�t$���3�^ËL$�T$�d	V�t$э��  R���   P�t$���3�^ËD$���;�t��ȋT$�d	VQ�L$���  �R���  P�t$���3�^�U��E�H;Mv7�d	Vj���  ����P�u��d	j h\�u���  ��jX^]ËU�M�3�]�U��E�M�;U~7�d	Vj���  �`���P�u��d	j h\�u���  ��jX^]�Q�M�u�Q����3�]�U��VW�u讈 �} Y��|9}s�}�u�D7;Ev5�d	j���  �����P�u��d	j h\�u���  ��jX�S�]W�u�3P������$7 3�[_^]�U���u���} Y|9Es�E�MV�TA;Uv5�d	j���  �j���P�u��d	j h\�u���  ��jX� �UW�< W�4
�uV��f�$7 ��3�_^]��t$�����t3�������t$�����t����3�ËD$ËD$�U��QSV�E�WP�d	�u���   3�Y9]�Yu�E��~�u�d	��X  P�   �uY;�Y�u_����E�E�P�d	�u���   �}�YY��r>W����t3W��;E�u'V�u�S�u��������u'�u�W�6����3��9]tS�u�u�������jX_^[��U��V�EWP�u3�����u!E�-�u����V�$���Y��uj^��uWV����u.������} t	�u� ���tW��YV��3���u� ���_^]�SV�t$3�;�t"9U�-�vW�~�7��C��;Yr�_V��Y]^[�U���(SVW3��}؋5h�����E�3�P�E�P�E�WPW�E�   �u�}��}��u�օ�u:�����;�t.��zt)�d	Wh|�u���  WS�u�������jX�l  �]�E�P�E��PWS���������,  �E�P�u�WS�q��������  �E�P�E�P�E��u�P�u��u�u�օ�u+�d	Wh|S���  ��W���PS�?�������   �}�uh�u�5����u�ЉU��֋M�t�EP�6PWS�����������   �u�uhpV�u����u�uS�����u�E�����$�\�E�P�u�S������;ǉE�uE�d	j��u����  �u�Eܡd	���   �E�d	�M�Qj���  ���   PS����}�9}�t
�u���Y9}�t
�u���Y�E�_^[��U��QVW�}�EP�7�v��   Pj j �
�������t3��h�E�0�M3�9E���A��N��t$�v�N���T8�uI�|0�򥥃����ɥw�E�P�u�u�l�����t�E�M���u��Y��_^��U��QQSVW�}3ۃ��]��E�   t��tW�u�  Y��Y�Cj�MXQ�EP�EPW�u� ���t$�d	�u���  ���   P�u���3���  3�;�u2�d	Sh�u���  ��S���P�u������jX��  �G��}���m  �$��L VW�  Y;�Y�E���  ��   �d	SS���   Y�E��]9Yv1�E�D�PW��  Y;�YtP�d	�u�W���   ���E�E;rϋE;�&  �   VW��  닍E�P�6W�/������E���  �d	SS���   �E��d	jV���   P�d	�u�W���   �FP�   �� ;�tP�d	�u�W���   ���Sh�W�d  �6�d	���   Y�E��]��u  �d	SS���   V�E���  ��;��h  P�d	�u�W���   �FP�  ��;��D  P�d	�u�W���   �v�d	�v���   ���  P�u�W��d	�v���   ���   P�u�W��d	�v���   ���   P�u�W��d	��@�v ���   ���   P�u�W��d	�v$���   ���   P�u�W��d	�v(���   ���   P�u�W��d	�v,���   ���   P�u�W���@�F0P�   ��Yt^P�d	�u�W���   ���e� �3Sh��u�d	���  ���.�d	Sh�W���  ��9]�u�u��d	W���  Y�3�9]�t	�u��^���YV���E�Y_^[��J 8J �J �J �J lL �J K K *K 8J �L lL lL U����E�0�p�E�h4jP�(��e� �E�j�P�d	���   ����U��QQV�u�E�P�6�u�}�������t3��%�v�d	���   �E��E�P�d	j���   ��^�ËD$�0��P�t$�   ���U��d	SVW3�WW���   9}YY��~.�uV�u�4   Y��Yt#P�d	S�u���   ��G��;}|Ջ�_^[]�S�"���Y3���U��QQV�uV�����j �E��v�d	���  �E��E�P�d	j���   ��^��U��QSVW�E�3��5 �PWW�}��u�u�օ�u<����؃�zu3��tW��Yj[�u��$���Y��t �E�P�u�W�u�u뾋����tW��YS��3�_^[��U��E��u]ÉE�EjPj�u�d�]�U��E��u]ÉE�EjPj�u�d�]ÍD$P�t$�t$�t$�`��U��EP�EP�u�u�u�\�]�U��    �`} V�EWP�� ����5X�Ph    �u�u�u�օ�u
P���P�'����  ;�u*j j �� ���j P�u�u��j W�u�m�����jX_^�Í� ���P�u�����Y��Yt�P�d	�u���  Y3�Y��U��V3�9ut%�}�   u�u�Vx V�u�u������jX�g�d	SWVV���   �؋EY;�Y~/�}�E�d	j��7���   ���  PS�u�}���Mu���}�d	S�u���  YYW��w _3�[^]�U��Q�E�j P�EP�Ej�P�uj �u�w j�u�uP�u�4�������U��QQ�E�j P�EP�E�j�Pj �u�w j�u�u�P�u���������U��QQ�E�j P�EP�E�j�Pj �u�_w j�u�u�P�u���������U��Q�E�P�EP�Ej�Pj �u�u�0w j�u�uP�u��������U��EP�EP�Ej�P�uj �u�u��v j�u�uP�u�^�����]�U��Q�E�j P�EP�Ej�Pj�u�u��v j�u�uP�u�'�������U��Q�E�j P�EP�Ej�Pj �u�u�v j�u�uP�u���������U��� �EV�E��E�E�E�E�E�E��E �E�E$�E��E(�E��EWP�E�3�Pj�u�u��Dv ��;�u3��   �d	Vh��u���  �E��+�t=Ht3HHt(HtHtHt
HuP���(���!�������p��d��X;�tVhLP�d	h@�u��   ��VW�u�C�����jX_^��U��}VW��   �E�� t*HtHtj hD�   �����\ �����+[ �
�|���S �MQ�u�u�u�Ћ���t%�d	j h�u���  j V�u�������C�u�d	�u���  �u��P�u����u��t 3��j h��u�d	���  ��jX_^]ád	SUVW3�WW���   �\$���D$$Y+ǋ|$Y�  H�4  H�G  H�A  �d	jh����   ���   PVS�U �d	�w`���   ���   PVS�U �d	jhx���   ���   PVS�U �d	�wd���   ���   PVS�U �d	��Hjhh���   ���   PVS�U �Gh������u���d	j�Q���   ���  PVS�U �d	jhP���   ���   PVS�U �Gl��(����u���d	j�Q���   ���  PVS�U �d	jh8���   ���   PVS�U �d	�wp���   ���   PVS�U ��8�d	jh$���   ���   PVS�U �d	�w ���   ���   PVS�U �d	jh���   ���   PVS�U �G$��8����u���d	j�Q���   ���  PVS�U �d	jh ���   ���   PVS�U �G(��(����u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �G,��(����u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �O0��(��u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �d	�w4���   ���   PVS�U �d	jh����   ���   ��@PVS�U �d	�w8���   ���   PVS�U �d	jh����   ���   PVS�U �d	�w<���   ���   PVS�U �d	��@jh����   ���   PVS�U �d	�w@���   ���   PVS�U �d	���   jhx���   PVS�U �d	�wD���   ���   PVS�U �d	��Hj�hd���   ���   PVS�U �d	j�wH���   ���   PVS�U �d	jhP���   ���   PVS�U �d	�wL���   ���   ��@PVS�U �d	jh<���   ���   PVS�U �d	�wP���   ���   PVS�U �d	jh(���   ���   PVS�U �GT��D��u���d	j�P���   ���  PVS�U �d	jh���   ���   PVS�U �d	�wX���   ���   PVS�U �d	jh���   ���   ��@PVS�U �d	�w\���   ���   PVS�U ���d	jh����   ���   PVS�U �O����u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �d	�w���   ���   PVS�U �d	j
h����   ���   ��@PVS�U �d	�w���   ���   PVS�U �d	jh����   ���   PVS�U �G��0����u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �G��(����u���d	j�Q���   ���  PVS�U �d	jh����   ���   PVS�U �d	�w���   ���   PVS�U �d	jh����   ���   ��@PVS�U �G����u���d	j�P���   ���  PVS�U ���d	j
h����   ���   PVS�U �?����u���d	j�W���   ���  PVS�U ����_^][�U��d	SVWj j ���   �u�]���EY��Y�Q  ����   ��  ����  �d	jh����   �M���   P�EWS��d	�v���   �M���   P�EWS��d	��$�}���   j��Mu7h����   P�EWS��d	�v���   �M���   P�EWS���$�Qh����   P�EWS��EP�vS������ ��t�d	j�h����   Y�EY�u�d	WS���   ���d	jh����   �M���   P�EWS��F������u���d	j�Q���   �U���  P�EWS����d	j
h����   �M���   P�EWS��6������u���d	j�Q���   ���  PWS�����_^[]�U��d	Sj j ���   �؋EYHY��   �d	VWjh ���   ���   PS�u��}�������u���d	j�Q���   ���  PS�u��d	jh����   ���   PS�u����(��u���d	j�W���   ���  PS�u���_^��[]�j �t$�t$�t$�t$��������U��Ej �E�EPj �u�u�j ]�U��Ej �E�EPh�  �u�u�wj ]�U��Ej �E�EPh�  �u�u�Vj ]�U��Ej �E�EPh�  �u�u�5j ]�U��Ej �E�EPh�  �u�u�j ]�U��Ej �E�EPh�  �u�u��i ]�U��Ej �E�EPh�  �u�u��i ]�U��Ej �E�EPh�  �u�u�i ]�U��Ej �E�EPh�  �u�u�i ]�U��Ej �E�EPh�  �u�u�oi ]�U��Ej �E�EPh   �u�u�Ni ]�U��Ej �E�EPh  �u�u�-i ]�U��Ej �E�EPh  �u�u�i ]�j�t$�t$�t$�t$�9������U��}t�d	j h��u���  ��jX]�jj�u�u�u�������]�U��QQ�Ej �E��E�E��E�Pj�u�h ��U��QQ�Ej �E��E�E��E�Pj�u�zh ��U��Ej�E�EPj�u�u�bh ]�U��Ej�E�EPj�u�u�Jh ]�U����E�jP�T���uP���P�u��������E�P�E�P�u�#   ����tjX���u��d	�u���  Y3�Y��U���,SVW3�9}�}ԉ}؉}܉}��}�u�d	WW���   YY�M�3�_^[�ÍE�P�E�P�u�@����9  �}�t9}��  Wh(�u�s  �E�P�d	���   �];�Y�E��I  �E�P�E�P�u�D�����   9}���u�d	j�V���   Y;�Y�E��  ��E�P�u�S�>��������
  �E�P�E�P�u�H�����   9}�u�d	j�V���   Y;�Y�E���   ��E�P�u�S�����������   �E�P�E�P�E�P�u�L���t<9}�u�}��u�S�   Y;�Y�E���   �E�P�E�P�E�P�u�P���u��];�t^W���PS�����K9}�u�}��u�S�^   Y;�Y�E�t4�E�P�d	j���   Y;�Y�V���;�tWhS�d	���  ���}��E��t���b����E��}�Yr�jX�#���U���SVW3�9}�}�}�u�d	j�hp���   YY�  �58�j�E�jP�u�օ���   j�E�jP�u�օ���   �u��d	���   �E��d	WW���   �]��9}�E�t`;�t\3�9}�v>�EPV�u�<���tp�uS�   Y;�YtMP�d	�u�S���   ����u6F;u�rE�P�d	j���   Y;�Yu[;�t�d	WhPS���  ���u��D����u��<���YY�,;�t�W���PS������9}tW���P�u�������3�_^[��U��QSV�u3�;�W�]�u%9]�S  �d	Shx�u���  ���7  �d	SS���   �}Y;�Y�E��   �P�d	���   ;�Y�E���   P�d	�uW���   ������   �FP�d	���   ;�Y�E���   P�d	�uW���   ������   �>wJ�v�d	���   ;�Y�E�tNP�d	�uW���   ����ui�E���PVW�]���������uQ�u��6�FP�d	V���   Y;�Y�E�u;�t.�d	ShPW���  ���P�u�d	W���   ����t�u������u����YY3���E_^[��U��QQ�} u�E   �EP�EP�EP�E�P�E�P�u�u�u�4���tP��3��ËE��U��QQ�} u�E   �EP�EP�EP�E�P�E�P�u�u�u�0���tP��3��ËE�ÍD$P�t$�t$�ne ����t$���=   u	�|$ t3��U��Ef�8 u3��MQ�u�uP��\ ��tP����YP���e �E]�U��QSVWj^�EP�EP�u�u�\ ��3�;�St,�d	h��u���  ��SW�i���YP�u�0������f�d	S���   Y3�9]Y�E�v/�d	���   �E��P�����P�u��u�����;�uG;}r��u�\ ;�u�u��d	�u���  YY��_^[��U��QQSVWj[�EP�EP�u�u��[ ��3�;�Vt,�d	h��u���  ��VW����YP�u�p������u�d	V���   Y3�9uY�E�v>�E�P�E�4��u�
����؃�;�u#�u��d	�u��u���   �؃�;�uG;}r��u�H[ ;�u�u��d	�u���  YY_��^[��U��V�u�u�u�u�'[ ����t2�d	j h��u���  ��j V�����YP�u������jX�3�^]�U��V�u�u�u�u�u��Z ����t2�d	j h�u���  ��j V����YP�u�U�����jX�3�^]�U��QQ�E�VP�E�P��b 3�;�tVP�W���YP�u�������\�d	SVV���   9u�YY��v)W�d	���   �E���P�����PS�u���F;u�r�_�d	S�u���  YY�u��_b 3�[^��U��EP�u�Vb 3�;�tQP�����YP�u������]�9Mu3�]ád	SVWQQ���   ��d	jh����   ���   �}PVW��d	���   �E��P�9���PVW��d	jh����   ���   PVW��d	��@���   �E��P�����PVW��d	jh����   ���   PVW��d	���   �E��P����PVW��d	jhx���   ���   PVW��d	��H���   �E��P�k���PVW��d	j	hl���   ���   PVW��M�d	�q$���   ���   PVW��d	jhd���   ���   PVW��M�d	��H�q(���   ���   PVW��E�p,�t  �E�d	jh`���   ���   PVW��E��(��uP�d	h����   YYP�d	VW���   �d	j	hT���   ���   PVW��M�d	�q4���   �q0���  PVW��E��4�88v<�d	jhH���   ���   PVW��d	���   �E��8P� ���PVW���$�E�8@v<�d	jh8���   ���   PVW��d	���   �E��@P�ܾ��PVW���$�E�8Hv<�d	jh4���   ���   PVW��d	���   �E��HP蘾��PVW���$�d	VW���  YY�u�9_ _^3�[]�U��EP�uj �K�������u�E]ád	j h����   YY]�U����EWP�u�u�V 3�;�tWP�l���YP�u�3�������   �}V��   �}t�d	Wh��u���  ��j_�   �u�ҽ���E�E��P�ý���E��E��P贽���E�E��P�6����E��E�p(�%����E��d	�M�Qj���  ���   P�u���$�9�u�j����E�E�p������E�d	�M�Qj���  ���   P�u����u�U ��^_�ÍD$P�t$���ÍD$P�t$�t$����U��E� $  ��t� &  �u%�   ��uj j �uP�u�   ��]�U��j�h��h �d�    Pd�%    ��hSVW�e��E�   �M3��}��u �u�E�P�u�u�u�u�����t0�d	���  j��u����  P�u����u�� ��}��   W���P�u�[������x�E� � �E�jXËe�}�  �t+�u�hx�E�P���j�E�P�u�d	���  ���3j�d	���  �u�d	��8  j h�u�d	���  ���M���E�M�d�    _^[��U��E� (  ��t� *  �u %�   ��u�u�u�uP�u������]�U���L�E�VP����E�P�d	���   �u��E��d	���   �u�E��d	���   �u�E��d	���   �u�E��d	���   �u��Eġd	���   �u�Eȡd	���   �u��E̡d	���   �E��E�P�d	���   �E��E�P�d	���   �Eءd	�M�Qj
���  ���   P�u���83�^���t$����U���p�E�VP�E�@   �����tD�u��d	�u����  �u��E�d	�u����  �u��E��d	�u����  �u��E��u��M�E��E�    P����d	3�V�u����  V�E��uܡd	���  V�E��u�d	���  V�E��u�d	���  �E��d	�M�Qj���  ���   P�u���03�^��U��QVW�=��@  �E�PVj �u脲������ut9Et&9Et�uV�u��u����V�u��u�����uV�u�����N�;�r
�u���Y�롅�t�u��d	�u���  �v���P�u����u���Y3�_^���t$�t$�t$�P�������t$j �t$�=������U���8SVW�  3��E�;�uVj�u�P�E�P����E܋]�<@�E���PWVS蜱������u/�E�PW�u�j�U���;�t$�u���YVW����YPS������jX�#  �d	VV���   9u�YY�E��u���  �u��3��d	VV���   �M����E�jh��4�d	���   �M���   P�EWS��d	�v�6���   �M���  P�EWS��d	j
h����   �M���   P�EWS��d	��D�v���   �v�M���  P�EWS��d	jh����   �M���   P�EWS��d	�v�v���   �M���  P�EWS��d	jh����   �M���   ��DP�EWS��d	�v�v���   �M���  P�EWS��d	jh����   �M���   P�EWS��d	�v$�v ���   �M���  P�EWS��d	��H���   jh��M���   P�EWS��d	�v(���   �M���   P�EWS��d	W�u�S���   �E�0��0�E�E�;E������u�d	S���  �u�����3�_^[�Ã=� u.����uhP������th�P�������U���SVW����3��E�;�uWj�u�`�]��  �}�9}�t
�u���Y�E�PVWS贮������u;�E�PV�u�j�U��=  ��Et�;�t&�u���YW�u�����YPS菿����jX�p  �d	WW���   �u�YY�E��d	WW���   ���d	jh, ���   �M���   P�EWS��d	�v���   �M���   P�EWS��d	j	h  ���   �M���   P�EWS��d	��@�v���   �M���   P�EWS��d	jh ���   �M���   P�EWS��d	�v���   �M���   P�EWS��d	jh ���   �M���   P�EWS���H�d	�   �E�FP�:���P�EWS��d	W�u�S���   �����t	�3�������u��d	S���  �u�����3�_^[��U��� Vj ^�E�Vj P��U �E���E�E�E�E�P�u��u�T���uP���P�u�ƽ����jX�&�d	j �5����  �u��   P�u���3�^��U���   �u�� ����u�uP�   �� ���j�P�d	���   ����U��} t#�E�MjQ� _@P�!   �M�1P�PV ��]�h��u�>V YY]ËD$V�t$W�|$��~!��у������G����G@�@FOu�_^��   ��uj��2���L$Q��Ã= u.����uhX ������th8 P������   ��uj��2���t$��Ã=� u.����uhX ������thh P��������   ��uj��2���t$��Ã=� u.����uhX ������th� P������Ã� SUVW����3�D$ ;�u	Uj�t$<�g�t$4�P�  �l$9l$t�t$��Y�D$PWUV�}�������u=�D$,PW�t$j�T$0�����  �t�;�t%�t$��YUS����YPV�V�����jX��  �d	UU���   �|$YY�D$ �D$8���t	;GD�r  �d	�wD���   ���   P�t$(V���9l$<�B  �d	UU���   ��d	j	h�#���   ���   PUV��d	�wD���   ���   PUV���,�D$<��   �d	jh�#���   ���   PUV��d	�wH���   ���   PUV��d	j	h�#���   ���   PUV��d	�wP���   ���   PUV��d	��Hjhx#���   ���   PUV��d	�w@���   ���   PUV���$�D$<t9�d	jhl#���   ���   PUV��d	���   �G8P襯��PUV���$�D$<�   �d	jh`#���   ���   PUV��d	�wL���   ���   PUV��d	jhT#���   ���   PUV��d	�w���   ���   PUV��d	��Hj
hH#���   ���   PUV��w$�d	�w ���   ���  PUV��d	jh����   ���   PUV��w,�d	�w(���   ���  ��DPUV��d	j
h����   ���   PUV��w4�d	�w0���   ���  PUV���4�D$<�g  �d	jh,#���   ���   PUV��d	�wX���   ���   PUV��d	jh#���   ���   PUV��d	�w\���   ���   PUV��d	��Hjh�"���   ���   PUV��d	�w`���   ���   PUV��d	jh�"���   ���   PUV��d	�wd���   ���   PUV��d	��Hjh�"���   ���   PUV��d	���   �wh���   PUV��d	j"h�"���   ���   PUV��d	�wl���   ���   PUV��d	��Hjhx"���   ���   PUV��d	�wp���   ���   PUV��d	j%hP"���   ���   PUV��d	�wt���   ���   PUV��d	��Hj!h,"���   ���   PUV��d	�wx���   ���   PUV��d	jh"���   ���   PUV��d	�w|���   ���   PUV��d	��Hjh�!���   ���   PUV��d	���   ���   ���   PUV���$�D$<��  �=�	��  �d	jh�!���   ���   PUV����   �d	���   ���   ���  PUV��d	jh�!���   ���   PUV����   �d	���   ���   ���  ��DPUV��d	jh�!���   ���   PUV����   �d	���   ���   ���  PUV��d	jhp!���   ���   PUV��d	��H���   ���   ���   ���  PUV��d	jhP!���   ���   PUV����   �d	���   ���   ���  PUV��d	jh0!���   ���   ��DPUV����   �d	���   ���   ���  PUV��� �D$< ��  �d	jh(!���   ���   PUV��d	j j ���   ���=�	�D$���   s���   �d$ � �@  �D$<%�   �D$$�D$<��@�D$(�d	j j ���   �s$�D$�d	���   �L$@���   P�D$D�t$,V��d	jh!���   �L$T���   P�D$X�t$4V��d	�s ���   �L$d���   P�D$h�t$DV��d	jh� ���   �L$x���   ��DP�D$8�t$V��d	�s$���   �L$D���   P�D$H�t$$V����|$$ ��  �d	jhx#���   �L$<���   P�D$@�t$V��d	�s,���   �L$L���   P�D$P�t$,V��d	jh� ���   �L$`���   P�D$d�t$@V��d	�s(���   �L$p���   P�D$t�t$PV��d	��H���   jh� �L$<���   P�D$@�t$V��d	�s���   �L$L���   P�D$P�t$,V��d	jh� ���   �L$`���   P�D$d�t$@V��d	�s4���   �L$p���   P�t$P�D$xV��d	��H���   j
h� �L$<���   P�D$@�t$V��d	�s8���   �L$L���   P�D$P�t$,V���$�|$( ��  �d	jh� ���   �L$<���   P�D$@�t$V��d	�s���   �L$L���   P�D$P�t$,V��d	jh� ���   �L$`���   P�D$d�t$@V��d	�s0���   �L$p���   P�D$t�t$PV��d	��H���   j
hH#�L$<���   P�D$@�t$V��d	�s�s���   �L$P���  P�D$T�t$0V��d	jh����   �L$d���   P�D$h�t$DV��d	�s�s���   �L$x���  ��DP�D$8�t$V��d	j
h����   �L$H���   P�D$L�t$(V��d	�s�3���   �L$\���  P�D$`�t$<V���4�t$�d	�t$ V���   ���D$�D$��@;G������t$�d	UV���   ���d	U�t$$V���   ��3�|$8�u�;�t��o����t$ �d	V���  �t$����3�_^][�� �U���  S�]V��X���W�E���  �E�   �E3�+�t'HtHu0�E�PW�u��QB ��E�PW�u��u�9B ��E�PW�u��$B ��;�t5�E�;�rF��X����ǐ  9E�Wu�$��
�u����Y;�Yti�E��V���P�u�Ю������   �����d	VV�u����   Y;�Y����   �u��}�} u\�d	�6���   ���   PS�u����o�d	���  ���0��d	Yj �u��   ��8  YPh�#�u����O�6�E�h�#P����d	�M�j�Q���   ���   PS�u��� ���M�`����d	S�u���  YY��X���_9E�^[t
�u���Y�E���j j �t$�J�������t$j�t$�7������j j�t$�&������U��V�u�u�����t7=  t!�5���օ�t$j ��P�u�j�����jX�-�d	j ���  ��d	j���  ���   P�u���3�^]�U���SV�uWjD3�_WSV� E �E�>�}P�E�P�d	�uW���   ������  �}�t�d	Sh@$W���  ���y  �E�P�E�p$�d	W���   �����X  �E��F,�E�0�d	��   �$,$P�F���Y��Yu�^�E�p�d	��   �E�Y�FtN�E�P�E�p�d	W���   ������   �E��F�E�P�E�p�d	W���   ������   �E��F�E�tJ�E�P�E�p�d	W���   ������   �E��F�E�P�E�p�d	W���   ����uu�E��F�E�tF�E�P�E�p�d	W���   ����uL�E��F �E�P�E�p�d	W���   ����u)�E��F$�E�t+�E�P�E�p �d	W���   ����tjX��   �E��F(j[�]�t)�E�P�E�p(�d	W���   ������   f�E�f�F0�E���   �EP�E�P�E�p,�d	W���   ����uv�}�tP�d	h�#W���  ���YS�F8�5�P�E�0W脯������u<S�F<�5�P�E�pW�f�������u�ES�5���@V�pW�H�������t���3�_^[��U����d	V�u�6���   �v�E�d	���   �v�E�d	���   �v�E�d	���   �v�E��d	���   �v�E��d	���   �E��E�P�d	j���   �� ^��U����E�jPj �u�u�2   ����tjX�ád	V���  �E�P�u�=���P�u���3�^��U��Q�=   ��uPj� �M�Q�u�u�u�u�Ѕ�}j P蜶��YP�u�c�����jX��3��Ã=@ u.����uhP������th|$P���@�@�U��� �d	V�u�v���   �v�E��d	���   �6�E��d	���   �v�E�d	���   �E�E�P�d	j���   �v�E�d	���   �v�E�d	���   �v�E�d	���   �E�E�P�d	j���   ��,^��U����E�jPj �u�u�2   ����tjX�ád	V���  �E�P�u����P�u���3�^��U��Q�=   ��uPj� �M�Q�u�u�u�u�Ѕ�}j P�#���YP�u������jX��3��Ã=� u.�D��uhP�����Dth�$P�������U��QQS�EWP�u�����3�;߉]�Wu���P�u�r�����jX�`�d	W���   9}YY�E�~,V�d	j��3���   ���  P�u��u���G��;}|�^�u��d	�u���  YY�u����3�_[��V�t$W�t$V�t$�������u9D$~f!�����t������_^�V�t$W�t$V�t$�������u9D$~f!�����t������_^�U�� @  �> SVW�� ����    SW�u�������vf�|w� uf�|w� ��   �;�w:�����zuuہ� � }a�� ���;�tW��Y�P�$���Y��tH�jz��j ���P�u�������j^��t�� ���;�tW��Y��_^[��jz3�����t�W�u����Y��Yt�P�d	�u���  Y3�Y�U��QV�E�WP�u�; ����t5W�$���Y��t'VWj �u�; ��u���V����YW��3����_^�Ã|$ t�t$��Y�U��Q�E�P�EPh|%�u�D; ��u�ád	SVWj j ���   ��d	jhp%���   ���   �}PVW��M�d	�1���   ���   PVW��d	jh`%���   ���   PVW��M�d	��@�q���   ���   PVW��d	jhP%���   ���   PVW��M�d	�q���   ���   PVW��d	jh@%���   ���   PVW��M�d	��H�q���   ���   PVW��d	jh,%���   ���   PVW��M�d	�q���   ���   PVW��d	jh%���   ���   PVW��M�d	��H�q���   ���   PVW��d	jh%���   ���   PVW��M�d	�q���   ���   PVW��d	jh�$���   ���   PVW��M�d	��H�q���   ���   PVW��d	jh�$���   ���   PVW��M�d	�q ���   ���   PVW��d	j
h�$���   ���   PVW��M�d	��H�q$���   ���   PVW��d	jh�$���   ���   PVW��M�d	�q(���   ���   PVW��d	jh�$���   ���   PVW��M�d	��H�q,���   ���   PVW��d	jh�$���   ���   PVW��d	�M���   �q0���   PVW��d	VW���  ��<3�_^[��U���   �u�� ����uh�%h   P������EP�EP�� ���P�u��7 ��t+�} t%�d	Vj��u���  ���  P�u���3�^��3���U����EP�E�Ph�%�u�7 ��u�ád	SVj j ���   �u��؋EYY�D�;�wNW�FP�Ph�%�E�j
P�(��d	�M�jQ���   ���   PS�u��E�M�����(�D�;�v�_�d	S�u���  Y3�Y^[��W�t$�������u�����tWP�t$跠����jX_ád	VW���  ���   P�t$���3�^_�U��V�EW�}P�EP�d	�uW���   ����t�}t�d	j h�%W���  ��jX_^]Ëu�EV�0�d	W���   ����uݍFP�E�p�d	W���   ����u��FP�E�p�d	W���   ����u��E��V�p�d	W���   ����u��U����d	V�u�6���   �v�E�d	���   �v�E��d	���   �v�E��d	���   �E��E�P�d	j���   ��^��U��QQ�d	V�u�6���   �v�E��d	���   �E��E�P�d	j���   ��^��U��V�EW�}P�EP�d	�uW���   ����t�}t�d	j h&W���  ��jX_^]Ëu�EV�0�d	W���   ����u݋E��V�p�d	W���   ����u����d	SUV3�WSS���   ��d	jh�&���   ���   PVS��|$0�d	�7���   ���   PVS�U �d	jh�&���   ���   PVS�U �d	��@�w���   ���   PVS�U �d	jh�&���   ���   PVS�U �d	�w���   ���   PVS�U �d	jh�&���   ���   PVS�U �d	��H�w���   ���   PVS�U �d	jh�&���   ���   PVS�U �d	�w���   ���   PVS�U �d	jh�&���   ���   PVS�U �O�d	��HQ���   ���   PVS�U �d	jh�&���   ���   PVS�U �O�d	Q���   ���   PVS�U �d	jh�&���   ���   PVS�U �O�d	��HQ���   ���   PVS�U �d	j	h�&���   ���   PVS�U �O�d	Q���   ���   PVS�U �d	jh�&���   ���   PVS�U �O�d	��HQ���   ���   PVS�U �d	jht&���   ���   PVS�U �O�d	Q���   ���   PVS�U �d	j	hh&���   ���   PVS�U �O�d	��HQ���   ���   PVS�U �d	jhT&���   ���   PVS�U �O�d	Q���   ���   PVS�U �d	j
hH&���   ���   PVS�U ����H;�u���d	j�W���   ���  PVS�U ����_^][�VW�t$�@+ ����u!�5���օ�tW��P�t$������jX��d	W���  ���   P�t$���3�_^�U���V�E��uh�#P����d	�M�j�Q���   ���   P�E�p�0��� jX^�� U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph� �X���uP���PV�h����u��q�����jX��u��d	V���  Y3�Y^��U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph� �u�T���u-�����t#��t��~tj PV�����u��������jX��u��d	V���  Y3�Y^��j ���t$�t$�t$�P���tjX�������@�j ���t$�t$�t$����L$���u�����t3��jX�U���PSV�d	Wj^j��u��u���   �}�M�Q�E�P�d	W���   ����u�E3�P�E�k�PSW���������t����  9]��]���  �E�3�P�d	�u��E�l(�E�d(�u��u�W���   �����s  9u���  �E�P�d	V�u�W���   �����K  9u���  �E�Pj�E�hP(P�d	�u�W���   �����  �E�+���   H�{  �E�   �|5��d	W�u��u��u���   ������  �?���N  �D5�P�d	W�u���   ������  �E�����|��M��M�UȉT�M�ỦT�M�UЉT�M�UԉT�M�D�M�D�   �E�   �|5��d	W�u��u��u���   �����<  �?����   �D5�P�d	W�u���   �����  �E�����|�9E���   �}��   ��   9E�|~�}���  u�uЋE��u�P�  �Ef�M̃�f�L�E�}�E��;E������E�;E�tHj h(W�d	���  ���   Vh�'��j h�'�j h�'�u��Phl'��Ph$'���t<j�uP�L����E�u)�����d	j h'W���  j VW�x�������d	�u����  ���   PW����e� �}� t	�u��W���Y�} t
�u��Y�E�_^[��U��� SV�d	Wj_j��}��u���   �E�P�d	���  �����u����%�   ���EP����   k�83�PS�u贄��������   ;�]���  3��u��d	�u����  ���Ej�j P�  �E��jj f�|�E�CP��  �E�� Cf�|���E��E�;E�|��R  i�  3�PS�u�.�������t���  ;�]��h  3��u��d	�u����  YYP�H�3Ɋ�%�   �E������M�f���E�t�Ej_�j jPC��d  ���j_�E��f���E�t�Ej �jPC��<  ���E��f���E�t�Ej �jPC��  ���Ej �u��C�P�  �Ej�u��C�P��   ��f�}� t�Ej�jPC���   ��f�}� t�Ej�jPC��   ��f�}� t�Ej�jPC��   ���E��E�;E��������t=j�uS�L���u/���j h'�u��d	���  j V�u�̓�����"3��d	P���  ���   P�u����e� �}� t	�u�訠��Y�} t
�u��Y�E�_^[�ËD$f�L$�T$f�H3��    f�H�P�H�Hád	Vj��t$���   ���  P�D$�p�0���jX^� U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph�� �D���uP���PV�����u�������jX��u��d	V���  Y3�Y^��U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph�� �u�@���uP���PV�~����u�臟����jX��u��d	V���  Y3�Y^��U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph� �u�����u(�����t��tj PV�
����u�������jX��u��d	V���  Y3�Y^�ád	SUVW3�WW���   �\$��d	US���  ��W�P�����t�d	W���   ���   PUS����������t�d	S��l  j VS�t�����jX�3�_^][�U���S3��EVWt�]�*�E�E�E �E�E$�E��E(�E�E,�E��E0�E��E�ESS�u�5���u�u�u�֋�;�u9]t.S���P�u���������EP�D?PS�u��������tjX�ZW�u�u�u�u�u��;�uS���P�u諐����j[� �d	HP�u���  ���  P�u����u��Y��_^[��U��� S3��EVWt�]�6�E�E��E �E�E$�E�E(�E�E,�E��E0�E�E4�E��E8�E��E��ESS�u�5���u�u�u�֋�;�u9]t.S���P�u���������EP�D?PS�u��~������tjX�ZW�u�u�u�u�u��;�uS���P�u謏����j[� �d	HP�u���  ���  P�u����u��Y��_^[��j �5��t$��������j �5��t$�������j�5��t$�t$�t$��������j�5��t$�t$�t$�ۓ�����U����E�VP�d	�uj ���   ����u�Ef�M�f�3���   �u�d	V�u��X  YP�u�   ����t֍E�P�E�P�d	�uj ���   ����u{�}�|u�E�P�E��0�d	j ���   ����u�E��E��'�E�P�E��0�d	��X  YPj �9   ����u,�E�f= tf= tf= u�uf��d	��l  Y�<���jX^��U���PSVW�}��t(3۾H��:uWP�|% Y��YtL��C���Hr߃} t2��u��(Whp(�E�jPP�(��E�jP�d	�u���  ��jX_^[�ËE��tf�� Hf�3���U��� SV�u3�;�u�E�P�d��u�f��� t��@t�F�0��  ��v��f=@u�N;�tQ����Y��  ����WP�d	���   Y�E�f��]�����$��   t+�������  �$�̪ S�5��v�  S�5���F�];��q  �N;��f  ��}WQP�RD���S  S�5t�v����S�E��5@�u������E�E�P�d	j���   �� �  �������  �$�$� f��u�F��F� P�  f����  �v�  f��u�F��F� �d	QQ�$���   �  f���   f��u����vV�F���  �d	f�����  u�v�0�P�v��X  �F�0�0�P�F�0��F� P��QS�5��jf��
�V���f��u�F��F� P�d	���   �  f��u�F�C����F� �9���f��t�vV��~����   �F� P��QS�5��F�0��������   f��u	�F������F� ����f��u	�F�����F� ����f��u	�F�����F� ����f���@f��u�F�v��N��qVP�<f����f���f����F�0V�d	���   �4f��u�v��F�0��   �tSV�d	���  Y��d	V���   Y�E��E�P3�9]���@P�d	���   YY_^[�ë� è ը �� � �� � � h� q� �� $� �� �� � �� � 2� 8� R� X� t� �� è ը �� � �� � T� h� q� �� �� �� �� � �� � 2� 8� R� X� t� U���$S�]Vj^�E�PS�u��T����[  �E��� P�d	���   �E�Y�E�PS�l����E  �d	W3�WW���   f9;YY�E��}�v]���d	�s���   �M����   P�E��u�W��d	�3���   �M����   P�E��u�W���� ���E�E���� 9E�|��d	WW���   �E�Y�E����Y���E�   ��  �$�'� ;��}��p  �M�U��d	�QQ���   ���   P�u�W����E�9u�|��=  ;��}��2  �M�U��d	�4����   ���   P�u�W����E�9u�|��  ;��}���  �M�U��d	Q��Q���   �$���   P�u�W����E�9u�|���  ;��}���  �M�U��d	Q��Q���   �$���   P�u�W����E�9u�|��  ;��}��t  �d	�M����   �E��P��z��P�u�W����E�9u�|��C  ;��}��8  �M�U��d	Q��Q���   �$���   P�u�W����E�9u�|��  ;��}���  �E�M����d	Q�M����   �  �E��0�P�E��u��P�u�W����E�9u�|��  ;��}���  �E�M�W���5��d	P���   ����P�u�W����E�9u�|��m  ;��}��b  �M�U��d	�4����   ���   P�u�W����E�9u�|��1  ;��}��&  �M�U��d	�QQ���   ���   P�u�W����E�9u�|���  ;���  3ۉu��E�d	�P���   �b���P�u�W������M�u��  ;���  3ۉu�d	���   �E��P�Vy��P�u�W������M�u��~  ;��}��s  �E�M�W���5��d	P���   �����P�u�W����E�9u�|��:  ;��}��/  �M�U��d	�
Q���   ���   P�u�W����E�9u�|���   ;��}���   �M�U��d	�
Q���   ���   P�u�W����E�9u�|��   ;��}���   �M�U��d	�QQ���   ���   P�u�W����E�9u�|��   3�;�~z�E���   �tWP�d	���  Y�P�d	���   YP�d	�u�W���   ��C;�|��63�;�~0�d	���   �M��M��t��4����  P�E��u�W���C;�|��u�h�_��d	h    ���   Y�E܍E�P�d	�u����   YY^[��t� �� � /� p� �� � >� �� �� �� q� 7� � �� � 1� o� �� �� �� o� U���l�EP�u�u�u�u�8���}j P�u�c�����jX��V�E��uh�(jPP�(�j�E�j P�  �E�j �E�d	���  �E�P�u����P�u���03�^��U���l�E�UR�u�P���|OV�E��uh�(jPP�(�j�E�j P� �E�j �E�d	���  �E�P�u����P�u���03�^��=@ �u3���j P�u莂������U��QV�u�E�WP����3�PW�u�Qq������tjX�   �ES�u��]��uVShx�P�Q;�W|v�d	W���   Y;�Y�E~J�d	j��4����   ���  P�u�u��M��d	�4����   ���   P�u�u���$G;}|�3��u�d	�u���  Y3�Y�P�u辁����j^9}�[t
�u���Y��_^��U��Q�E�U�RP��Q3�;���  �d	SVWQQ���   ��d	jh�)���   ���   �}PVW��d	�u����   �jv��PVW��d	jh�)���   ���   PVW��M��d	��@�q���   ���   PVW��d	j
hx)���   ���   PVW��M��d	�q���   ���   PVW��d	jhd)���   ���   PVW��M��d	��H�q���   ���   PVW��d	jhT)���   ���   PVW��M��d	�q���   ���   PVW��E���4�x  �d	jhH)���   t=���   PVW��E����@ ����u���d	j�Q���   ���  PVW����+���   PVW��d	j h����   ���   PVW���(�d	jh8)���   ���   PVW��M��d	�q$���   ���   PVW��d	jh,)���   ���   PVW��M��d	�q(���   ���   PVW��d	��Hjh$)���   ���   PVW��M��d	�I,Q���   ���   PVW��d	jh)���   ���   PVW��M��d	�I.Q���   ���   PVW��d	��Hj
h)���   ���   PVW��M��d	�I0Q���   ���   PVW��d	j	h)���   ���   PVW��M��d	�I2Q���   ���   PVW��d	��Hjh�(���   ���   PVW��M��d	�I4Q���   ���   PVW��d	j
h�(���   ���   PVW��M��d	�I6Q���   ���   PVW��d	��Hjh�(���   ���   PVW��M��d	�I8Q���   ���   PVW��d	jh�(���   ���   PVW��M��d	�I:Q���   ���   PVW��d	��Hj
h�(���   ���   PVW��E����x(u�u��<PW�   ����u�d	j j ���   YYP�d	VW���   �d	jh�(���   ���   PVW��M��d	�IHQ���   ���   PVW��E��0�u��P�QL�d	VW���  Y3�Y_^[��QP�u�|����jX��U���SV�u3�;�Wu9]tj�d	Sh�)�u���  ���Q�F����   ����   ��t����   �6�d	���   Y�E��   �u�6�u������;ÉE�u3��   �d	SS���   Y�E�Y�f9YvL�d	�t����   ���   P�u��u���d	�t����   ���   P�u��u���� C�A;�|�j�!�u�6�u������;ÉE��t���j�j�F_P�d	���   �E�E�P�d	W���   ��_^[��U��V�u�MW�Q�uV�P��}j P�u�C{����jX_^]�V�u�u�'   ������uV�PT��tۡd	W�u���  Y3�Y��U��d	SVWj j ���   ���d	jh *���   ���   �]PWS��d	�u�6���   �M���   P�EWS��d	��,�~ ���   j�MhH)tC���   P�EWS��F������u���d	j�Q���   �U���  P�EWS����4���   P�EWS��d	j h����   �M���   P�EWS���(�F ����   ��~F��t��t<��d	j
h*���   �M���   P�EWS��d	�v�   �E�:����:�d	jh*���   �M���   P�EWS��d	�v���   �M���   P�EWS���$�d	jh�)���   �M���   P�EWS��u�FPS������ ��uPP�d	���   YYP�d	WS���   �d	jh�)���   �M���   P�EWS��u�FPS�   ��,��uPP�d	���   YYP�d	WS���   �d	jh�)���   �M���   P�EWS��d	�v ���   �M���   P�EWS��d	j	h�)���   �M���   P�EWS��d	��D���   �M�NQ���   P�EWS�����_^[]�U��QQV�u�FP�d	���   �e� �E�f�FY�t� t�6��t��V�|���Y�E��E�P3�9E���@P�d	���   YY^��U��V�u�MW�Q�uV�P��}j P�u��w����jX_^]�V�u�u�'   ������uV�PP��tۡd	W�u���  Y3�Y��U����d	SVWj j ���   �ءd	jh *���   ���   �}PSW��d	�u�6���   �M���   P�ESW��d	jh�*���   �M���   P�ESW��d	��@�v���   �M���   P�ESW��d	jh�*���   �M���   P�ESW��d	�v���   �M���   P�ESW��d	jh�*���   �M���   PSW�E��d	��H�v���   �M���   P�ESW��d	jh�*���   �M���   P�ESW��d	���   �M�NQ���   P�ESW��d	j
h�*���   �M���   P�ESW��d	��H���   �M�NQ���   P�ESW��d	jh�*���   �M���   P�ESW��d	���   �M�NQ���   P�ESW��d	���   j
ht*�M���   P�ESW��d	��H���   �M�N0Q���   P�ESW��d	jh`*���   �M���   P�ESW��u�F PW�q�����0��uPP�d	���   YYP�d	SW���   �d	jhH*���   �M���   P�ESW��u�F(PW������,��uPP�d	���   YYP�d	SW���   �d	j j ���   �E�3���9Ft=f9F�E~4�d	�U���   �M�N�4����   P�ESW��F���E9E|̡d	j	h<*���   �M���   P�ESW��u��d	SW���   �d	j j ���   �E�3���(9F��   f9F�E��   �E��E��uFPW�-������E���uPP�d	���   Y�E�Y�F�M��u�DPW�`������E��uPP�d	���   Y�E�Y�d	���   �M�M�Qj���   P�E�u�W��F�E����E9E�i����d	jh(*���   ���   PSW��u��d	SW���   �� ��_^[��U��QV�u�E�WP����3�PW�u��a������tjX�   �ES�u��]�VSP�Q(;�W|v�d	W���   Y;�Y�E~J�d	j��4����   ���  P�u�u��M��d	�4����   ���   P�u�u���$G;}|�3��u�d	�u���  Y3�Y�P�u�Rr����j^9}�[t
�u���Y��_^��U���   V3�h�   ��|���VP��	 �E���U��R��|���j R�uP�Q;�V|}�d	V���   9u�YY�E�u~MSW��|����d	�6���   ���  �0�P�6�P�u�u����6�X��& �E�E��;E�|�_[�u�d	�u���  Y3�Y�P�u�qq����^��U��Q�E�U�RP��Q3�;���  �d	SVWQQ���   ��d	jh�)���   ���   �}PVW��d	�u����   �{f��PVW��d	jh�)���   ���   PVW��M��d	��@�q���   ���   PVW��d	jh�*���   ���   PVW��M��d	�q���   ���   PVW��d	jh�(���   ���   PVW��M��d	��H�IQ���   ���   PVW��d	jh�(���   ���   PVW��M��d	�IQ���   ���   PVW��d	j	h�*���   ���   PVW��M��d	��H�IQ���   ���   PVW��E���u��P�Q0�d	VW���  Y3�Y_^[��QP�u�o������U���8SVWj3�^9}�}�u܉}��}�}�tv�E�P�E�P�d	�u�u���   ����u'9u�|Q�E�P�E�P�E��0�d	�u���   ����t���  9}�t?�}�9�EP�E��0�u��������u!j3�^�]9}�f�3u.�E   �}���  j h�+�u�d	���  ���  9u���   �E�P�E�P�E��p�d	�u���   ������  9E���   �E�P�E��0�d	j ���   ����u�E؅�ujXf��m�E�P�E��0�d	���   �}� YY��tJh�+W�� Y��Yt9�|+VW� Y��Yuf� �%VW� Y��Yuf� �j h`+����f� �}�~.�E�P�E�j�p�d	�u���   �����   �E��t� f�}�����f�}uc�}�������E�P�E�P�E��p�d	�u���   ������  �}�������EP�E��0�u�b��������t����M@�u�}�8f�}�S���3�9ut\�EP�d	�uV���   ����u!�E   �}��f��u8�f f� �  �E�P�d	�uV���   ���E   ��t��E   뼨t!�} t!�d	j j �u�u��  ���E�} u%�t���E
   ��E��uPh$+�����E�M���促������  �$�{� �FP�d	�u�u���   ������  f� �  �FP�d	�u�u���   �����u  f� ��  �FP�u�u�{_�������Q  f� �  �FP�d	�u�u���   �����'  f� �  ��@�	  �d	�~W3��uS���   ����uf� ��d	W�uS���   ����uf� �}�D  �E�P�d	�u���  YY�u�P�P�;ÉuSh+�k���f� �E�P�d	�u���  YY�u�P�P����FuP��f� ��   j�F�5�P�u�u��o�������C  f�	 �   f�
 �F ��   �d	�~W�u�u���   �����  �f� ���f�� ���j�F�5�P�u�u�^o��������   f� �CV�u�u�f^��������   f� �%�FP�d	�u�u���  ������   f� �E�Ȁ�f;t)f=@t#f%��Pj VV�L���}j P�u�j���.����E@tf�}@uf�@�w�e� �7f���@f�������w�$��� ����j h�*�����Q�u��   YY�E��t��E�8 P�d	���   Y�E�_^[�Ö� �� �� �� �� � �� �� � -� 8� `� �� J� �� �� �� �� �� �� �� �� � �� 9� 9� 9� 9� 9� 9� 9� 9� 9� 9� >� 9� � >� 9� 9� 9� 9� 9� 9� 9� 9� U���P�} t-�EPh�+�E�jPP�(��E�jP�d	�u���  ���ËD$��tf�8uP���U���SV�EWP�EP�EP�u�u��u�uj_W�H�P�uV�S3�;�}VP�u�Dh�����-  �E+���   H��   Ht\Ht�d	j$h,���   YY��   �d	jh�+���   V�E��50�u�R����E��E�P�d	j���   ���   �d	jh�+���   �u�E��u�u����V�E��5��u������ �E��E�u�P�QT�G�d	jh�+���   �u�E��u�u�����V�E��5��u踩���� �E��E�u�P�QP�E�Pj�VV�d	���   YY3�P�d	�u���  Y��Y_^[��U���  W3�h�   ��|���WP��� �E����|����E�    �R�U�RP�Q8;�}WP�u��f�����V9}�Vv)���|������|����V��Y��������6�X�G;}�rסd	������Q�u����  ���   P�u���3�^_���t$h��j �t$�<��U���VW3�9}uG�d	j���   �E�d	WW���   �E��d	�M�Qj���  ���   P�u���3���   �E�P�E��PW�u��T������u)�E�U�R�u���uP�Q;�t��tWP�u�e����jX�   3�;ǡd	S��Q���   �E�d	WW���   ��3�9}��E�v=�d	���   �E��P�����P�u��u��E����f�8uP��C��;]�rád	�M�Qj���  ���   P�u���3�[_^��U���P�5   �p�p�p�E�h,,jPP�(��E�jP�d	�u���  ��$3��Ã=H V� uVh8,�|T��Y�H   Y��^��"   ��uj��3���t$�t$�t$�t$��Ã=� u.����uh8,������thD,P�������U���#   ��uj��3�]��u�u�u�u�u��]Ã=4 u.����uh8,������th\,P���4�4Ã=L u3�U   ����u������xu�x u
�s   ���L   ����uj��3���t$�t$�t$�t$��Ã=� u.����uh8,������thp,P������Ã=� u.����uh8,������th�   P�������SVW�|$���u3��D<  8dI�5��uWhdI�օ��	9  �PI:uWhPI�օ�uj��8  �@I:uWh@I�օ�uj��8  �,I:uWh,I�օ�uj�8  �I:uWhI�օ�uj�8  �I:uWhI�օ�uj�8  ��H:uWh�H�օ�uj
�c8  ��H:uWh�H�օ�uj	�G8  ��H:uWh�H�օ�uj�+8  ��H:uWh�H�օ�uj�8  ��H:uWh�H�օ�uj��7  ��H:uWh�H�օ�uj��7  �xH:uWhxH�օ���7  �lH:uWhlH�օ�t��\H:uWh\H�օ�t��PH:uWhPH�օ�t��@H:uWh@H�օ�t��0H:uWh0H�օ������� H:uWh H�օ��"����H:uWhH�օ��%����H:uWhH�օ��(���� H:uWh H�օ���6  ��G:uWh�G�օ��������G:uWh�G�օ��������G:uWh�G�օ��������G:uWh�G�օ��������G:uWh�G�օ��������G:uWh�G�օ��A����xG:uWhxG�օ��D����dG:uWhdG�օ��G����LG:uWhLG�օ��
6  �<G:uWh<G�օ��5����0G:uWh0G�օ�������$G:uWh$G�օ�������G:uWhG�օ������� G:uWh G�օ��y�����F:uWh�F�օ��|�����F:uWh�F�օ�������F:uWh�F�օ��B5  ��F:uWh�F�օ��1�����F:uWh�F�օ��4�����F:uWh�F�օ��W�����F:uWh�F�օ��������F:uWh�F�օ��	�����F:uWh�F�օ��������F:uWh�F�օ�������tF:uWhtF�օ�������dF:uWhdF�օ��a4  �LF:uWhLF�օ��l����<F:uWh<F�օ��7����0F:uWh0F�օ������$F:uWh$F�օ��!����F:uWhF�օ���3  �F:uWhF�օ���3  ��E:uWh�E�օ��������E:uWh�E�օ��������E:uWh�E�օ���3  ��E:uWh�E�օ��������E:uWh�E�օ��:�����E:uWh�E�օ��]�����E:uWh�E�օ�������E:uWh�E�օ������xE:uWhxE�օ������lE:uWhlE�օ���2  �PE:uWhPE�օ�������8E:uWh8E�օ�������,E:uWh,E�օ�������E:uWhE�օ�������E:uWhE�օ��T2  ��D:uWh�D�օ��������D:uWh�D�օ��*�����D:uWh�D�օ��-�����D:uWh�D�օ���1  ��D:uWh�D�օ��������D:uWh�D�օ��r����|D:uWh|D�օ��=����pD:uWhpD�օ�������`D:uWh`D�օ�������PD:uWhPD�օ��Z1  �8D:uWh8D�օ������,D:uWh,D�օ��0����D:uWhD�օ��3����D:uWhD�օ���0  ��C:uWh�C�օ��Y�����C:uWh�C�օ��������C:uWh�C�օ��������C:uWh�C�օ��������C:uWh�C�օ��y0  ��C:uWh�C�օ��h�����C:uWh�C�օ��O�����C:uWh�C�օ��R�����C:uWh�C�օ��0  �tC:uWhtC�օ���/  �hC:uWhhC�օ�������\C:uWh\C�օ�������LC:uWhLC�օ���/  �8C:uWh8C�օ�������(C:uWh(C�օ�������C:uWhC�օ�������C:uWhC�օ��������B:uWh�B�օ��4/  ��B:uWh�B�օ��#�����B:uWh�B�օ��&�����B:uWh�B�օ��������B:uWh�B�օ��������B:uWh�B�օ��������B:uWh�B�օ���.  ��B:uWh�B�օ�������tB:uWhtB�օ��X����`B:uWh`B�օ��?����TB:uWhTB�օ��:.  �HB:uWhHB�օ��E����<B�<B:uWS�օ������,B:uWh,B�օ���-  �TB:uWhTB�օ���-  �HB:uWhHB�օ�������<B:uWS�օ������� B:uWh B�օ�������TB:uWhTB�օ��u-  �HB:uWhHB�օ�������<B:uWS�օ��O����B:uWhB�օ��6����TB:uWhTB�օ��-  �HB:uWhHB�օ�� ����<B:uWS�օ�������B:uWhB�օ�������TB:uWhTB�օ���,  �HB:uWhHB�օ�������<B:uWS�օ��������A:uWh�A�օ�������TB:uWhTB�օ��U,  �HB:uWhHB�օ��`����<B:uWS�օ��/�����A:uWh�A�օ��2�����A:uWh�A�օ��9�����A:uWh�A�օ��������A:uWh�A�օ��������A:uWh�A�օ��������A:uWh�A�օ��������A:uWh�A�օ��x+  ��A:uWh�A�օ��g����xA:uWhxA�օ��N����hA:uWhhA�օ������`A:uWh`A�օ������TA:uWhTA�օ������HA:uWhHA�օ���*  �8A:uWh8A�օ�������(A:uWh(A�օ�������A:uWhA�օ�������A:uWhA�օ��������@:uWh�@�օ��e*  ��@:uWh�@�օ��p�����@:uWh�@�օ�������@:uWh�@�օ��"�����@:uWh�@�օ��%�����@:uWh�@�օ���)  ��@:uWh�@�օ���)  ��@:uWh�@�օ��������@:uWh�@�օ��������@:uWh�@�օ�������|@:uWh|@�օ��k)  �t@:uWht@�օ��v����h@:uWhh@�օ��A����\@:uWh\@�օ�� )  �L@:uWhL@�օ�������D@:uWhD@�օ���(  �8@:uWh8@�օ�������,@:uWh,@�օ�������@:uWh@�օ�������@:uWh@�օ���(  ��?:uWh�?�օ��������?:uWh�?�օ��|�����?:uWh�?�օ��G�����?:uWh�?�օ��J�����?:uWh�?�օ�������?:uWh�?�օ�������?:uWh�?�օ�������?:uWh�?�օ��"�����?:uWh�?�օ�������t?:uWht?�օ�������d?:uWhd?�օ�������T?:uWhT?�օ��^'  �@?:uWh@?�օ�������4?:uWh4?�օ�������$?:uWh$?�օ�������?:uWh?�օ������� ?:uWh ?�օ�uj��&  ��>:uWh�>�օ�uj��&  ��>:uWh�>�օ�uj�&  ��>:uWh�>�օ�uj�&  ��>:uWh�>�օ��}�����>:uWh�>�օ�������>:uWh�>�օ��+�����>:uWh�>�օ������|>:uWh|>�օ������l>:uWhl>�օ������\>�\>:uWS�օ���%  �H>:uWhH>�օ��������>:uWh�>�օ�������|>:uWh|>�օ�������l>:uWhl>�օ�������\>:uWS�օ��a%  �4>:uWh4>�օ��P�����>:uWh�>�օ������|>:uWh|>�օ������l>:uWhl>�օ��!����\>:uWS�օ���$  � >:uWh >�օ���$  ��>:uWh�>�օ�������|>:uWh|>�օ�������l>:uWhl>�օ�������\>:uWS�օ��o$  �>:uWh>�օ��������>:uWh�>�օ��)����|>:uWh|>�օ��,����l>:uWhl>�օ��/����\>:uWS�օ���#  ��=:uWh�=�օ��=�����>:uWh�>�օ�������|>:uWh|>�օ�������l>:uWhl>�օ�������\>:uWS�օ��}#  ��=:uWh�=�օ��������=:uWh�=�օ��S�����=:uWh�=�օ��V�����=:uWh�=�օ��!����hA:uWhhA�օ�������`A:uWh`A�օ�������TA:uWhTA�օ�������HA:uWhHA�օ���"  ��=:uWh�=�օ�������(A:uWh(A�օ��o����A:uWhA�օ��r����A:uWhA�օ��u�����@:uWh�@�օ��8"  ��=:uWh�=�օ��C�����@:uWh�@�օ��������@:uWh�@�օ��������@:uWh�@�օ��������@:uWh�@�օ���!  ��=:uWh�=�օ���!  ��@:uWh�@�օ��u�����@:uWh�@�օ��x�����@:uWh�@�օ��{����|@:uWh|@�օ��>!  ��=:uWh�=�օ��1����|=:uWh|=�օ�������p=:uWhp=�օ�������d=:uWhd=�օ�������T=:uWhT=�օ���   �@=:uWh@=�օ�������(=:uWh(=�օ���   � =:uWh =�օ��~����=:uWh=�օ�������=:uWh=�օ��D   ��<:uWh�<�օ��S�����<:uWh�<�օ��r�����<:uWh�<�օ��������<:uWh�<�օ��������<:uWh�<�օ�������<:uWh�<�օ��������<:uWh�<�օ��-�����<:uWh�<�օ��|  �x<:uWhx<�օ�������h<:uWhh<�օ��R����\<:uWh\<�օ�������P<:uWhP<�օ�������@<:uWh@<�օ��#����0<:uWh0<�օ�������$<:uWh$<�օ������<:uWh<�օ�������<:uWh<�օ������� <:uWh <�օ���  ��;:uWh�;�օ��U�����;:uWh�;�օ��<�����;:uWh�;�օ��{�����;:uWh�;�օ��&�����;:uWh�;�օ��)�����;:uWh�;�օ���  ��;:uWh�;�օ�������t;:uWht;�օ�������d;:uWhd;�օ�������X;:uWhX;�օ�������H;:uWhH;�օ�������8;:uWh8;�օ��V  � ;:uWh ;�օ��=  �;:uWh;�օ������ ;:uWh ;�օ��O�����::uWh�:�օ��������::uWh�:�օ��������::uWh�:�օ���  ��::uWh�:�օ��������::uWh�:�օ��z�����::uWh�:�օ��������::uWh�:�օ��d�����::uWh�:�օ��g����|::uWh|:�օ��*  �d::uWhd:�օ������T::uWhT:�օ�������D::uWhD:�օ��#����8::uWh8:�օ�������(::uWh(:�օ�������::uWh:�օ���  � ::uWh :�օ��������9:uWh�9�օ��N�����9:uWh�9�օ��������9:uWh�9�օ��8�����9:uWh�9�օ��;�����9:uWh�9�օ���  ��9:uWh�9�օ��E�����9:uWh�9�օ�������x9:uWhx9�օ�������l9:uWhl9�օ�������\9:uWh\9�օ�������L9:uWhL9�օ��h  �<9:uWh<9�օ��s����,9:uWh,9�օ��>����9:uWh9�օ��  ��8:uWh�8�օ��(�����8:uWh�8�օ��������8:uWh�8�օ��������8:uWh�8�օ���  ��8:uWh�8�օ��������8:uWh�8�օ��������8:uWh�8�օ�������t8:uWht8�օ��y����h8:uWhh8�օ�������\8:uWh\8�օ������T8:uWhT8�օ������D8:uWhD8�օ������88:uWh88�օ�������,8�,8:uWS�օ���  �8:uWh8�օ�������h8:uWhh8�օ�������\8:uWh\8�օ��_����T8:uWhT8�օ��b����D8:uWhD8�օ��i����88:uWh88�օ��L����,8:uWS�օ��  �8:uWh8�օ���  �h8:uWhh8�օ��%����\8:uWh\8�օ�������T8:uWhT8�օ�������D8:uWhD8�օ�������88:uWh88�օ�������,8:uWS�օ��h  ��7:uWh�7�օ��;����h8:uWhh8�օ��z����\8:uWh\8�օ��	����T8:uWhT8�օ������D8:uWhD8�օ������88:uWh88�օ�������,8:uWS�օ���  ��7:uWh�7�օ�������h8:uWhh8�օ�������\8:uWh\8�օ��^����T8:uWhT8�օ��a����D8:uWhD8�օ��h����88:uWh88�օ��K����,8:uWS�օ��  ��7:uWh�7�օ��!����h8:uWhh8�օ��$����\8:uWh\8�օ�������T8:uWhT8�օ�������D8:uWhD8�օ�������88:uWh88�օ�������,8:uWS�օ��g  ��7:uWh�7�օ��N  ��7:uWh�7�օ��=�����7��7:uWS�օ��?�����7:uWh�7�օ��������7:uWh�7�օ��������7:uWS�օ��������7:uWh�7�օ�������|7:uWh|7�օ�������p7:uWhp7�օ�������`7:uWh`7�օ��p  �P7:uWhP7�օ��{����D7:uWhD7�օ��F����87�87:uWS�օ��H����$7:uWh$7�օ������D7:uWhD7�օ�������87:uWS�օ������7:uWh7�օ���  �7:uWh7�օ��������6:uWh�6�օ��~�����6:uWh�6�օ��������6:uWh�6�օ��������6:uWh�6�օ��G  ��6:uWh�6�օ�������6:uWh�6�օ��Y�����6:uWh�6�օ��������6:uWh�6�օ��������6:uWh�6�օ��������6:uWh�6�օ���  �t6:uWht6�օ�������d6:uWhd6�օ�������T6:uWhT6�օ��R����H6:uWhH6�օ��U����86:uWh86�օ��X����(6:uWh(6�օ��  �6:uWh6�օ������6:uWh6�օ��-�����5:uWh�5�օ��������5:uWh�5�օ��������5:uWh�5�օ��������5:uWh�5�օ���  ��5:uWh�5�օ��������5:uWh�5�օ��������5:uWh�5�օ��&�����5:uWh�5�օ��)�����5:uWh�5�օ��,����t5:uWht5�օ���  �d5:uWhd5�օ�������T5:uWhT5�օ������D5:uWhD5�օ�������85:uWh85�օ�������,5:uWh,5�օ�������5:uWh5�օ��Y  �5:uWh5�օ�������5:uWh5�օ��K�����4:uWh�4�օ��������4:uWh�4�օ�������4:uWh�4�օ�� �����4:uWh�4�օ��������4:uWh�4�օ��������4:uWh�4�օ��������4:uWh�4�օ��������4:uWh�4�օ��������4:uWh�4�օ��F  �x4:uWhx4�օ��5����l4:uWhl4�օ��8����`4:uWh`4�օ������P4:uWhP4�օ������@4:uWh@4�օ�������44:uWh44�օ�������$4:uWh$4�օ�������4:uWh4�օ��~  ��3:uWh�3�օ��������3:uWh�3�օ��p�����3:uWh�3�օ��W�����3:uWh�3�օ��  ��3:uWh�3�օ��	�����3:uWh�3�օ�uj��  ��3:uWh�3�օ�uj��  ��3:uWh�3�օ��������3:uWh�3�օ�������|3:uWh|3�օ�������p3:uWhp3�օ��e  �d3:uWhd3�օ�uj�K  �T3:uWhT3�օ�������H3�H3:uWS�օ��:����<3:uWh<3�օ������3:uWh3�օ�uj$��  �3:uWh3�օ��(����H3:uWS�օ�������<3:uWh<3�օ��������2:uWh�2�օ�uj �  ��2:uWh�2�օ��q����H3:uWS�օ��t����<3:uWh<3�օ��?�����2:uWh�2�օ�uj"�  ��2:uWh�2�օ�uj�  ��2��2:uWS�օ��������2:uWh�2�օ��������2:uWh�2�օ��������2:uWh�2�օ���  �t2:uWht2�օ�uj�  �d2:uWhd2�օ��Q����\2:uWh\2�օ��T����P2:uWhP2�օ��W����D2:uWhD2�օ��  �42:uWh42�օ�uj�   �$2:uWh$2�օ�������2:uWh2�օ�������2:uWh2�օ�������2:uWh2�օ���
  ��1:uWh�1�օ��m�����1:uWh�1�օ��p�����1:uWh�1�օ��s�����1:uWh�1�օ��6
  ��1:uWh�1�օ��a�����1:uWh�1�օ��(�����1:uWh�1�օ���	  ��1:uWh�1�օ�������x1:uWhx1�օ�uj�	  ��3:uWh�3�օ��������3:uWh�3�օ�������|3:uWh|3�օ�������p3:uWhp3�օ��R	  �d1:uWhd1�օ�uj�8	  ��2:uWS�օ�������2:uWh�2�օ�������2:uWh�2�օ�������2:uWh�2�օ���  �T1:uWhT1�օ�������D1�D1:uWS�օ�������81:uWh81�օ�������(1:uWh(1�օ�������1:uWh1�օ��X  �1:uWh1�օ�uj�>  ��0:uWh�0�օ�������0:uWh�0�օ�������0:uWh�0�օ�������0:uWh�0�օ���  ��0:uWh�0�օ��������0:uWh�0�օ��������0:uWh�0�օ��������0:uWh�0�օ��������0:uWh�0�օ��[  ��0:uWh�0�օ�������D1:uWS�օ������81:uWh81�օ������(1:uWh(1�օ������1:uWh1�օ���  �t0:uWht0�օ���  �h0:uWhh0�օ�������X0:uWhX0�օ���  �H0:uWhH0�օ�������40:uWh40�օ�uj�d  ��0:uWh�0�օ��5�����0:uWh�0�օ��8�����0:uWh�0�օ��;�����0:uWh�0�օ���  �$0:uWh$0�օ��������3:uWh�3�օ��������3:uWh�3�օ���  ��3:uWh�3�օ�������0:uWh0�օ�uj�  ��/:uWh�/�օ�uj�d  ��3:uWh�3�օ��5�����3:uWh�3�օ��8����|3:uWh|3�օ��;����p3:uWhp3�օ���  ��/:uWh�/�օ��a����H3:uWhH3�օ�������<3:u�<3WS�օ�u
�����<3��/:uWh�/�օ�uj%�  ��/:uWh�/�օ������H3:uWhH3�օ�������<3:uWS�օ��Q�����/:uWh�/�օ�uj!�/  �p/:uWhp/�օ�������H3:uWhH3�օ������<3:uWS�օ�������L/:uWhL/�օ�uj#��  ��2:uWh�2�օ��������2:uWh�2�օ��������2:uWh�2�օ��������2:uWh�2�օ��f  ��1:uWh�1�օ��9�����1:uWh�1�օ��<�����1:uWh�1�օ��?�����1:uWh�1�օ��  �8/:uWh8/�օ�������1:uWh�1�օ��������1:uWh�1�օ���  ��1:uWh�1�օ�������$/:uWh$/�օ��q����h0:uWhh0�օ�������X0:uWhX0�օ��S  �H0:uWhH0�օ��B�����0:uWh�0�օ�������0:uWh�0�օ�������0:uWh�0�օ�������0:uWh�0�օ���  ��0:uWh�0�օ��������0:uWh�0�օ��������0:uWh�0�օ��������0:uWh�0�օ��r  �/:uWh/�օ��������0:uWh�0�օ��,�����0:uWh�0�օ��/�����0:uWh�0�օ��2�����0:uWh�0�օ���   �/:uWh/�օ�uj��   ��.:uWh�.�օ��������.:uWh�.�օ��������.:uWh�.�օ��������.:uWh�.�օ�ty��.:uWh�.�օ�uj�b��.:uWh�.�օ��3�����.:uWh�.�օ��6�����.:uWh�.�օ��9�����.:uWh�.�օ�ujX�  ��.:uWh�.�օ�u
��  ��  �t.:uWht.�օ�u
��  ��  �d.:uWhd.�օ�u
��  �  �P.:uWhP.�օ�u
��  �  �8.:uWh8.�օ�u
��  �z  �$.:uWh$.�օ�u
��  �[  �.:uWh.�օ�u
��  �<  ��-:uWh�-�օ�u
��  �  ��-:uWh�-�օ�u
��  ��  ��-:uWh�-�օ�u
��  ��  ��-:uWh�-�օ�u
��  ��  ��-:uWh�-�օ�u
��  �  ��-:uWh�-�օ�u
��  �  �|-:uWh|-�օ�u
��  �c  �l-:uWhl-�օ�u
��  �D  �\-:uWh\-�օ�u
��  �%  �H-:uWhH-�օ�u
��  �  �4-:uWh4-�օ�u
��  ��   � -:uWh -�օ�u
��  ��   �-:uWh-�օ�u
��  �   ��,:uWh�,�օ�u
��  �   ��,:uWh�,�օ�u��  �n��,:uWh�,�օ�u��  �R��,:uWh�,�օ�u��  �6��,:uWh�,�օ�u��  ���,:u2Wh�,�օ�u&��   �d	P���  ���   P�t$���3��;�d	j���  �$��P�t$��d	j hBWh�,�t$,��   �� jX_^[�U��QQVW3�9}�}��}�u9}ujWX�H  �E�PhH�jWh8��8���;��%  9}t�E��u�P�QP��;���   9}t�E��u�P�Q��;���   9}t�E��u�P�Q,��;���   9}t�E��u�P�Q��;���   f9}t�E��u�P�Q4��;���   9} t�u$�E��u �P�QD��;�|v9}(t�E�W�u(�P�QH��;�|^9},|�E��u,�P�Q<��;�|G9}0t�E��u0�P�Q$��;�|0�E��U�Rh���P���;�|�E�j�u�P�Q���E�P��Q�E�;�t�P�Q��_^��U���  VWj�E�^3�PhH�VWh8��}��}��8�;�|&�E��U�Rh���P�;�|�E�W�u�P�Q;�}WP�u�}$�����  �E�S�u��uP�QL�d	WW���   Y���E�Y������h  �RP�Q(�}��|?�d	jh���   ���   PVW��d	������j�Q���   ���  PVW���(�E�������h  R�P�Q��|?�d	jh�I���   ���   PVW��d	������j�Q���   ���  PVW���(�E��U�RP��Q0��|;�d	jh�I���   ���   PVW��M�d	Q���   ���   PVW���$�E��U�R�������h  RP�Q@��|x�d	j
h�I���   ���   PVW��d	�u����   ���   PVW��d	j	h�I���   ���   PVW��d	������j�Q���   ���  ��@PVW����E��U�RP��Q��uA�d	jh�I���   ���   PVW��d	�u썘�   ���PVW���$�u��0��u�E��������j h  RP�Q��|?�d	jh�I���   ���   PVW��d	������j�Q���   ���  PVW���(�E��U�RP��Q8��|9�d	jh|I���   ���   PVW��d	�u����   ���   PVW���$�E�������h  R�P�Q ��|?�d	jhpI���   ���   PVW��d	������j�Q���   ���  PVW���(�d	VW���  Y3�Y3�[�E�;�t�P�Q�E�;�t�P�Q��_^��U��QQ�e� �e� �E�Phh�jj hX��8���|V�E�V�u��uP�Q����|0�E��U�Rh���P�����|�E�j�u�P�Q���E�P��Q�E���t�P�Q��^��U���VWj�E�^3�Phh�VWhX��}��}��8�;�|7�E��U�Rh���P�;�|"�E�W�u�P�Q;�|�E��U�RP��Q;�}WP�u�L �����*�d	j��u􍰴  ���  P�u����u��0�3��E�;�t�P�Q�E�;�t�P�Q��_^��U����e� �e� �E�VPhh�jj hX��8�����|S�E��U�Rh���P�����|<�E�j �u�P�Q����|(�E�U�E�E�E��E�E�E��E�   R�P�Q���E���t�P�Q�E���t�P�Q��^���   ��t�t$�t$���3�Ã=� u.���uh�I�����th�IP��������   ��t�t$��Ã=� u.����uh�I������th�IP��������
   ��t���3�Ã= u.����uh�I������th�IP������
   ��t���3�Ã=0 u.�L��uh�I�����Lth�IP���0�0�U���  �   ��uPj�*�   ������QRQ������Q������h  Q�Ѕ�tj P�u��������V������j�P�d	���  �E�����j�P�d	���  �E�������j�P�d	���  �E��d	�M�Qj���  ���   P�u���(3�^�Ã=� u.����uh�I������thJP�������U����~   ��uPj��M�Q�u�u�u�u�Ѕ�tj P�u�������ËE�V����P3��E���P�E�PhJ�E�jP�(��d	�M�j�Q���  ���   P�u���(3�^�Ã= u.�8��uh�I�����8th0JP�����U���   ��ujX]��u�u�u�u�u�u��]Ã=� u.����uh�I������th@JP�������U���(�ES�E؋E�E܋E�E��E�E�f�Ef�E�E �E�E�3�P�]������t�d	ShPJ�u���  ��jX�   �d	V�u����   �E��d	SS���   �E��E��;�t`9�H~RW�q�v��d	�v􍸸   ���  P�u��u��6�d	�v����   ���  P�u��u��E��(C��;|�_P����d	�M�Qj���  ���   P�u���3�^[��U���$V3�9utVj|� �EP�E�j$PV�u����Vu���P�u�����jX�,�d	V���   ���E�VP�   �d	V�u���  ��3�^�ád	SUVWjh�J���   ���   �t$ P3�VS��|$(�d	�7���   ���   PVS�U �d	jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	��Hjh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	��Hj���   h�J���   PVS�U �d	�w���   ���   PVS�U �d	jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	��Hj
h�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	jhxJ���   ���   PVS�U �d	�w���   ���   PVS�U �d	��HjhhJ���   ���   PVS�U �d	�w ���   ���   PVS�U ��$_^][��t$�t$�5��   ���U��Q�E��e� Pj �u�u�U��u�����zt3����E��E��VP�$���Y��t�E�PV�u�u�U��u
V��Y3���^���t$�t$�5��������U���u(�u �u$�u�u�u�u�u�u��]�U��Q�E�P�EjPj �u� ���t�E�Mj�X��3���U���D  ������S�M�V�M�WQ�M��   Q�E�P�������5��P�u�u�u�օ�u^�=���׃�ztj �7�E�3�P�u�S�u�������u,�E�P�E�P�u��u��u�u�u�օ�uS��P�u������jX��  3ۡd	�u�SS���   9]�YY�E��  �~8W����EP�d	W���  �E��Ej��DGP�d	���  �E��v�d	���   �E��v�d	���   �E��v�d	���   �E��v�d	���   �E��v�d	���   �E��FP�d	���   �E��FP�d	���   �E��FP�d	���   �E��v �d	���   �E�d	SS���   �E�~$��<�f9^�]v@W����E�d	�u���   W���  P�u��u��E���E�|G�F9E|�3ۋF,�9^(t�M�QP�u�C������t�d	Sh����   Y�E�Y�F4�v0�P�d	���   �E�d	�M�Qj���   ���   P�u�u��E���+�E�6;��K����u�d	�u���  ������Y9E�Yt
�u���Y3�_^[��j �t$�t$�t$�t$�����t$������t��u
j��3��U���   �}   j v�d	h K�u���  �+�EP�� ����uP�u�����uP���P�u�W����jX�ád	V�u�� ������  Q���  P�u���3�^��U��  諫 �E��E�   P������P�u�u�6� ��u)�d	V������j�Q���  ���  P�u���3�^��j P�u��������U��QV�E��u�e� �uPj �u�u�ߧ ��t=� �uE�E��P�$���Y��t2j �E��uPV�u�u謧 ��tS���V����YS��[3�h4Kj ���Y��Y^��U���SVW�E��u3��u�u��u�u�u�u�P�E�VPV�u��u�u�u�D� ��;�t=� �u^�E��=$��P��;�Y�E���   �E�;�t	�P��Y�E�9u�t	9u���   �u�E��uP�E��u�P�u��u�u�u�٦ ;�tVP�u������   �u��u�
��Y;�Y�E���   9u�t �u��u�
��Y;�Y�E�tw�u�����Y�u��ӍM�d	Q3�9u����  ��AQ���   P�u���3��i�d	���  ���0��d	YV�u��   ��8  YPh8K�u���9u�t�u���Y9u�t�u���Y9u�t�u���Y9u�t�u���Yj_h4KV���Y��Y_^[��U����EW�E�E�E�E�E��E�u$�E�E3��E��E �E��EP�E�WP�}蜥 ;�t=� �tWP�u�:����jX�   �EVP�E�PW�u� ������tj^�T�u$�EP�E��uP�I� ;�tWP�u������j^�!�d	j��u���  ���  P�u���3��u��Yh4KW���Y��Y^_��U��QQSVW�E��u3ۉ]��]�PS�u�ڤ ;�t =� �tSP�u�r�����E   �   �}�E�P�u�SW�8�������u��u�E�P�u��u茤 ;��E   StPW�&������  �d	S���   ��Y;�Y��  �d	jh�K���   ���   PVW��E���� ����u���d	j�Q���   ���  PVW��d	jh�K���   ���   PVW��E���(�@����u���d	j�Q���   ���  PVW��d	jh�K���   ���   PVW��E���(�@����u���d	j�Q���   ���  PVW��d	jh�K���   ���   PVW��E���(�@����u���d	j�Q���   ���  PVW��d	jh�K���   ���   PVW��M��d	�q���   ���   PVW��d	jhtK���   ���   ��@PVW��E����@����u���d	j�Q���   ���  PVW��d	VW���  �e ��3�h4KS���9]�YY_^[t
�u���Y�E��U���   V�E�WP�EP�u�u�Y� 3�h4KW�����Y;�Y�*  9}��!  �E�}�%   �}�=   �}�tw=   tZ=   t@�u�E�h,LP����u�d	��l  �E�WP�d	hL�u��   �� ��   �u�d	�u����  ��E�d	QQ�$���   Y��u�d	���   ;�Y�E�tG�u�E�h,LP����E�j�P�d	���   ��;ǉE�t�E�P�d	j���   Y;�Y�E�u Sj�u�[�;�tP����Y��Ku�jX[�WP�d	�u���  Y3�Y�B�u�E�Vh�KP����E�jP�d	�u���  ��9}�t�u�WV�u�����jX_^��V�t$W�F=� �u1�~��   �?P�v���Y��Yt�F�~�� ���� ��F_^� U���(Vj(�E�j P�� �M�h   �E�   �$��E�E؃��E��E��E�(P�E��  �B� h4Kj �����Y��Yt�u���YV��3���E�^��V�t$�� h4Kj �����Y��Y^�V�t$��� h4Kj �����Y��Y^�V�t$�ܟ h4Kj �����Y��Y^�V�t$�t$�t$軟 h4Kj �����Y��Y^�V�t$袟 h4Kj �����Y��Y^�V�t$�t$�t$�t$�}� h4Kj �����Y��Y^�V�t$�d� h4Kj �����Y��Y^�V�t$�K� h4Kj �����Y��Y^�V�t$�2� h4Kj �����Y��Y^�U���V�uj��FP�d	���  �E�FDj�P�d	���  ��D  �E�d	���   �E�H  j�P�d	���  �E��d	��H  j�V���  �E��E�P�d	j���   ��,^��U���V�uWj_�FP�j���E��FP�j���v$�E��d	���   �E������Hu�d	��(j�V���   ���hu�d	��(j�V���  Y�E�Yj_�E�P�d	W���   YY_^��U���Vj �5T�u��K��j �E��5�u�K���u�E��ri���E��d	�M�Qj���   ���   P�E�p�0���0jX^�� U��QQ�d	V�uj j �u����   Y�E�Y�E�Ph�+�u�u�T���uP���PV�����u�������jX��u��d	V���  Y3�Y^�Ã��d	SUV3�WSS���   ���d	j	h�L���   ���   PWS��t$@�d	�NQ���   ���   PWS�U �d	j
h�L���   ���   PWS�U �N�d	��@Q���   ���   PWS�U �d	jh�L���   ���   PWS�U �N�d	Q���   ���   PWS�U �d	j	h�L���   ���   PWS�U �N�d	��HQ���   ���   PWS�U �d	jh�L���   ���   PWS�U �N
�d	Q���   ���   PWS�U �d	j	h�L���   ���   PWS�U �N�d	��HQ���   ���   PWS�U �d	jh�L���   ���   PWS�U �N�d	Q���   ���   PWS�U �d	j
h�L���   ���   PWS�U �N�d	��HQ���   ���   PWS�U �d	j���   h�L���   PWS�U �N�d	Q���   ���   PWS�U �d	jhxL���   ���   PWS�U �d	��H�v���   ���   PWS�U �d	jhhL���   ���   PWS�U �d	�v���   ���   PWS�U �d	jh`L���   ���   PWS�U �d	��H�v���   ���   PWS�U �d	j]�v ���   �D$$�F ��H��   HteHtJH��   �F$P�d	���   �D$�F&P�d	���   �D$ �F(P�d	���   ���D$j�]�v$�d	���   �D$�F(��F$P�d	���   �D$�F&P�d	���   Y�D$Yj��F$P�d	���   Y�D$j]�d	jhXL���   �L$,���   P�D$0WS��d	���   �L$8�L$$QU���   P�D$DWS��d	j	hLL���   ���   PWS�U �N,�d	Q���   ���   ��@PWS�U �d	jh4L���   ���   PWS�U �N.�d	Q���   ���   PWS�U ��0��_^][���U���SV�EWP�E�P�d	�u�u���   ������  �E�tPh8M�u�  �uj0j V��� �E��e� ��H��f�0 ��  j_�E�t��d	��X  ��Y�:�Lu3h�LS�� Y��Yu"�FP�E�4�u�b��������s  �  �:�Luh�LS��� Y��Yu�F���:�Luh�LS��� Y��Yu�F롊:�Luh�LS蠚 Y��Yu�F끊:�Luh�LS耚 Y��Yu�F
�^����:�Luh�LS�]� Y��Yu�F�;����:�Luh�LS�:� Y��Yu�F�����:�Luh�LS�� Y��Yu�F������:�Luh�LS��� Y��Yu�F������:xLuhxLS�љ Y��Yu�F�>�:hLuhhLS豙 Y��Yu�F��:`Lu.h`LS葙 Y��Yu�FP�E�4�d	�u���   �i����:LLuhLLS�Y� Y��Yu�F,�7����:4Luh4LS�6� Y��Yu�F.�����:XL�u  hXLS�� Y��Y�`  �E�]P�E�P�E�4�d	S���   �����V  9E��  �E�P�E�0�d	S���   �����-  �E��F H��   H��   HtSH��   �}���   �F$P�E�pS�����������   �F&P�E�pS����������   �F(P�E�p�e�}���   �F$P�E�p�d	S���   ����uf�F(� �}�u[�F$P�E�pS�e�������uD�F&P�E�p��}�u2�F$P�E�pS�<�������u�E��E���H9E��}���3�_^[��j hMS�d	���  ����d	j hBSh�L�u��   ��jX��U��QQV3�9uuE�d	j���   �E��d	VV���   �E��d	�M�Qj���  ���   P�u�����   �E�UR�U�R�uP�Q;�t��tVP�u������jX�   3�;ơd	��Q���   �E��d	VV���   ��9u�E�tG9uS�0�v5W�M�d	j��4����   ���  P�u��u��E���4���F;ur�_�u��[�d	�M�Qj���  ���   P�u���3�^��U���S�U�V�ER�U�R�u3ۉ]��uP�Q ;É]���   ��~D= t$= t= ��   jh�M�j
h�M�jh�M�d	���   Y�E�Y�m�d	WjhxM���   �E��d	SS���   ��3�f9]�E�v-�d	���   ����E�P�����P�u��u���Gf;}r�9]�_t	�u��0��M��d	Q3�9]����  ��AQ���   P�u���3��SP�u�������^[��U��Q�E�U�R�U�RP�Q\��|(�M�d	VQ�u����  ���   P�u���3�^��j P�u�m�������U����d	SV��  WV�PY3��M�E�Q�M�QVPjW�u�E� �����u,�Ӄ�z�E�t"�u��d	�PW�u��u������jX�  9u�vM�u��d	�P�u��d	�PY�E�Y�M�Q�M�Q�u�PjW�u�ؒ ��uW��P�u������j_�B  �d	WW���   9}�YY�E��}�  �E��p�3��d	WW���   ���d	jh�M���   ���   PW�u��F�������u���d	j�Q���   ���  PW�u��d	jh�M���   ���   PW�u����(����u���d	j�Q���   ���  PW�u��d	j
h�M���   ���   PW�u��d	�v���   ���   PW�u��d	W�u��u���   ��D�E�E��;E������3��u�d	�u���  YY�u��d	�PY��_^[�Ã|$ t	�t$�`� Ã|$ t	�t$�U� �U���SV�E�WP�E�3�PjW�u�}��9� ��u?���9}���t	�u�����Y�d	Wh�M�u���  WV�u�������jX��  �d	WW���   9}�]Y�E�Y�}��  3��3��d	WW���   ���d	j	h�#���   �M���   P�EWS��d	���   �M�M��4���   P�EWS��d	j	h�#���   �M���   P�EWS��d	��@���   �M�M��t���   P�EWS��d	jh�M���   �M���   P�EWS��E���$�D����u���d	j�Q���   �U���  P�EWS��d	j�h�M���   �M���   P�EWS��E���(�D��t+�M�QPS�E���������   �u�d	WS���   ���&�d	j�h����   �M���   P�EWS����d	W�u�S���   ���E�E��;E��c����u�������u��d	S���  ��3�_^[���u�����W�����u������������U���V�E�WP�E�3�PjW�}��u�ۏ ��u?���9}���t	�u��Q���Y�d	Wh(N�u���  WV�u�z�����jX�[  �d	SWW���   9}��]Y�E�Y�}�  3��3��d	WW���   ���d	j	h�#���   �M���   P�EWS��d	���   �M�M��4���   P�EWS��d	jhN���   �M���   P�EWS��E���@�D����u���d	j�Q���   �U���  P�EWS��d	jh� ���   �M���   P�EWS��d	���   �M�M��t���   P�EWS��d	W�u�S���   ��D�E�E��;E�������u�������u��d	S���  ��3�[_^��U��QV�u�EWP�E�PV�u3��}��u�� ��u
������V;�|O��~��~E��~
��	~;��69}�t-�d	j��u����  ���  P�u���9}�t	�u��J���Y3��5j2^9}�t	�u��5���Y�d	WhXN�u���  WV�u�^�����jX_^��U��EP�u�u�u�u�u���3�;�tQP�u�(�����jX]�9M��  �d	SVWQQ���   ��d	jhO���   ���   �}PVW��E��� ����u���d	j�Q���   ���  PVW��d	jh�N���   ���   PVW��E��(�@����u���d	j�Q���   ���  PVW��d	jh�N���   ���   PVW��M�d	�q���   ���   PVW��d	j
h�N���   ���   ��@PVW��d	���   �E��P�'���PVW��d	j
h�N���   ���   PVW��E��0�@����u���d	j�Q���   ���  PVW��d	jh�N���   ���   PVW��E��(�@ ����u���d	j�Q���   ���  PVW��d	jh�N���   ���   PVW��M�d	�q$���   ���   PVW��d	j
h�N���   ���   ��@PVW��E���@(����u���d	j�Q���   ���  PVW��d	jh�N���   ���   PVW��E��(�@,����u���d	j�Q���   ���  PVW��d	VW���  ���u跆 _^[3�]�U��Q�d	S3�WSS���   �}YY�E�9v3�GV�E�u�d	�u���   �   P�u��u��E��C;r�^�E�_[��U���V�u�6�R   �v�E�d	���   �v�E��6   �v�E��+   �v�E��d	���   �E��E�P�d	j���   ��^�ád	Vj��t$���   ���P�YY^�U��Q�d	S3�WSS���   �}YY�E�9v6�GV�E�u�d	�u���   �    P�u��u��E\  ��C;r�^�E�_[��U���X�d	S3�VSh����   �u�E��d	��   ���   ��  �E��d	���   ��  �E��d	���   ��  �E��d	���   ��  �E���  P�d	���   ��  �E��d	���   ��   �E��d	���   ��$  �Eġd	���   S�E���(  �d	���  S�E���,  �d	���  S�E���0  �d	���  ��D�Eԡd	S��4  ���  S�E���8  �d	���  ��<  �Eܡd	���   S�E���@  �d	���  S�E���D  �d	���  S�E���H  �d	���  S�E���L  �d	���  S�E���P  �d	���  ��T  �E��d	���   �E���X  ��@8�0[  uHP�d	��\  V���   �E��E�P�d	j���   ��^[��U��Q�d	S3�WSS���   �}YY�E�9v3�GV�E�u�d	�u���   �   P�u��u��E��C;r�^�E�_[��U����d	V�u�6���   �v�E��FP�d	���   �v�E�������v�E��d	���   �E��E�P�d	j���   ��^��U���<  �d	SV�uW�6���   �v�E������=���E�d	YY���   f�FP����P��v�E��k����E�d	Y���   f�FYP����P��}Y�E�s�E�Pj�   �v�d	���   �}�   Y�E�s�E�Pj�   �v�d	�v���  Y�E�Y�   ���E  t?�MQ������Qj V�Ѕ�u+�d	j����������  j��E��������d	���  �$�d	��j�V���   �E��d	j�V���   ���E��E�Pj	�d	���   YY_^[�Ã=� u.�8��uh<O�����8th OP�������U���0  V�uW�6�����E�d	Y���   f�FP�����P��}Y�E�s�E�Pj�   �v�d	���   �}�   Y�E�s�E�Pj�   �v�d	�v���  Y�E�Y�   ���E  t?�MQ������Qj V�Ѕ�u+�d	j����������  j��E��������d	���  �$�d	��j�V���   �E��d	j�V���   ���E��E�Pj�d	���   YY_^�Ã=� u.����uh<O������thLOP�������U��Q�d	S3�WSS���   �}YY�E�9v5�GV�E�d	j�u���   �u�����P�u��u��E��C;r�^�E�_[��U��Q�d	S3�WSS���   �}YY�E�9v5�GV�E�d	j�u���   �u����P�u��u��E��C;r�^�E�_[��U��QQ�d	SV3�VV���   �]YY�E�93�u�v=�CW�E��   �d	V�u���   �u����P�u��u�u���E��E�;r�_�E�^[��U��Q�d	S3�WSS���   �}YY�E�9v5�GV�E�d	j�u���   �u�J���P�u��u��E��C;r�^�E�_[��U��Q�d	S3�WSS���   �}YY�E�9v5�GV�E�d	j�u���   �u�����P�u��u��E��C;r�^�E�_[��U��Q�d	S3�WSS���   �}YY�E�9v;�GV�E�d	h�   �u���   �u����P�u��u��E�   ��C;r�^�E�_[���t$�t$����YY��t$�t$�#���YY�U��}uR�E��|K��~$��~��<�u�u�0�����u�u�������u�u�\���YYP�d	�u���  Y3�Y]�j jW�u�������]�U��}u�E�� t1Ht!Htj jW�u������]��u�u�������u�u�t�����u�u�
���YYP�d	�u���  Y3�Y]�U���8V�uW����FWP�d	���   �Eȍ�  WP�d	���   ���  �E̍��  P�d	���   ���  �EСd	���   ���  �Eԡd	���   ���  �Eءd	���   �E܍��  P�u�   �E����  WP�d	���   �E䍆   WP�d	���   ��$  �E�d	���   ��@�E썆,  WP�d	���   �E���T  WP�d	���   �E�x  �RP�d	���  �E���|  �RP�d	���  �E��E�P�d	j���   ��(_^��U����d	SVj j ���   �uY��Y��thW�~ �FtWj�P�d	���   �E�Fj�P�d	���   �E��v$�d	���   �E��d	�M�Qj���   ���   PS�u���(�6��u�_��^[�ád	SVj j ���   �t$Y��Y��t(W�d	V�t$���   �����PS�t$ ��6����u�_��^[�U���l  V�E�WP�������E�H  P�������;} ���� td��ot��yuD�d	j hhO�u���  �8�u��$���Y��t�E�PV��| ����t#V��Y�j_j W�u������jX��   �d	j�V���   �E܍��   j�P�d	���   �E���  P�u�   �E���4  �d	���   �E荆8  j�P�d	���   �E���<  �d	���   �E���@  �d	���   �E���D  �d	���   �E���������0;�tV��Y�d	�M�Qj���  ���   P�u���3�_^�ád	SWj j ���   �|$Y��Y��t0V� �Ot�d	j�Q���   ���   PS�t$ ����?��u�^��_[�j j h�Mh@��t$�   ���U��QQSV3�W9uuVj�u�@�����jX�   �]jz�E��  �u�_��zt��ouL3�9}�t
�u���Y�E�P�u�WS���������u�9}t�u�E�P�u��U�
�E�P�u��UF����
|���u�u��d	S���  �UPS����j WS�������}� t
�u���Y3�����_^[��U���   V�E�WP��l����E��   P��l����u�z ���� td��ot��yuG�d	j h�O�u���  �;�u��$���Y��t�E�PV�u�Qz ����t V��Y�j_j W�u�������jX�g�6�d	���   �E��v�d	���   �E�FP�u������E���l�����;�tV��Y�d	�M�Qj���  ���   P�u���3�_^��j j h�QhL��t$�������U��Q�d	S3�WSS���   �}YY�E�9~6�GV�E�u�d	�u���   �    P�u��u��E  ��C;|�^�E�_[��U��QQ�d	V�u�6���   �E��d	��j�V���  �E��E�P�d	j���   ��^��U���\  �E������������P��x ��tj P�u������jX�ád	V���  ������P�u�>���P�u���3�^���t$jhsBhX��t$���������t$jh�Ah^��t$���������t$jh�Dhd��t$��������t$jhShj��t$�������U��Q�d	S3�WSS���   �}YY�E�9v3�GV�E�u�d	�u���   �   P�u��u��E8��C;r�^�E�_[��U���8V�u�6������v�E�������v�E̡d	���   �v�E������v�Eԡd	���   �v�Eءd	���   �v�Eܡd	���   �v�E�d	���   �v �E�d	���   �v$�E�d	���   �v(�E�d	���   �v,�E�d	���   �v0�E��d	���   �v4�E��d	���   �E��E�P�d	j���   ��@^��U��V�W   3�;�Vuj�u�������>�u�M�u�uQ�u��;�t	��ztVP�ԡd	�u���  ���   P�u���3�^]Ã=� u.����uh<O������th�OP�������U��V�W   3�;�Vuj�u��������>�u�M�u�uQ�u��;�t	��ztVP�ԡd	�u���  ���   P�u���3�^]Ã= u.�<��uh<O�����<th�OP�����U��QSVW��   ��3�;�tU�5��j�u�]���P�E��uP�׋�;���   �u��d	�u���  �����P�u����u�S��P����   �u�E�]PS�Qu ����zuC�u�$���Y��uP�d	h�u���  �'�u�EPS�u ����tS��Y3�SW�u������jX�&�d	S�u���  �����P�u�S����3�_^[�Ã=� u.����uh<O������th PP�������U��QSVW��   ��3�;�tU�5��j�u�]���P�E��uP�׋�;���   �u��d	�u���  ����P�u����u�S��P����   �u�E�]PS�t ����zuC�u�$���Y��uP�d	h�u���  �'�u�EPS��s ����tS��Y3�SW�u�]�����jX�&�d	S�u���  �����P�u�S����3�_^[�Ã=� u.�H��uh<O�����Hth$PP�������U���,  ����uj�   ��V�M��uj Q������h  Qj�u�Ћ�V�����tj V�u������jX�M������j�P�d	���   �E��E�j�P�d	���   �E��d	�M�Qj���  ���   P�u��� 3�^��U���0  �=� �E�P�E�Z�E�P�E��_�E�pP�E�RZt�E��\P�7  SVW������h  P������  ������P������P��t ������hPPP��t �=���������P�׋�����th�PV�Ӆ�u	V��3���uO������P������P�t ������hHPP�t ��������P�׋���tqh�PV�Ӆ�u	V��3���tX�e� �=�� ~+�}��w�V�Ӆ��t�E����E�;��|��	V��3���t���3���~�T���\P@;�|��E_^��\P��   [�� SV�t$����t+W�=��F��tP��Y�F��tP��Y�vS�ׅ�Y��u�_^[� U���$SVW�}3�3�9]�]��]�]�]��]��]��]�]܉]�u9]u
��*  �-  �E;�ty9X��   9X��   9X��   9X��   ����M�t9]u
�&'  ��  �H;�t��t
�?'  ��  �p;�t��t��t��t
�<'  �  �@�E�9]��   �E�j
P�u����M����E�8u*P���;�E�E���   j^�u��   ��*  �^  �=��;�t��uh�P�u��;�t
f�@�E�E�;�t��uh�P�u��;�t	f�@�E���E�f9]�u�����f%���*  ��   ;�u 3�f;���Af;Ë�tf9]��E�   u�]�}9]t<�E�P�u�   ��uI�E��t�E��*  �   ��WP�u��u�V�u�y  �E��k�E�$���%����  P����E��u��u��u�V��   ;Éu	�E�   �K9]t0��E�t'�u����P�A   ��A�9Xu�E�   9]�u9]�t�7�u��  ;ÉE�t	�7�[�����E�_^[�� VW�|$��tW��o @Pj���������u3��WV��p Y��Y_^� �L$V3��ъ��t<.uF�BB��u��uQ������u3��	�L$j�X^� VW�=��j j�׋�Y��Ytjj��Y��YuV��Y3��3f�T$jf�P�T$Y�Pf��N�L$�F�N�L$�N�F   ��_^� U���  ��SV�   W��3��������������e� �΍�����h   �������u������󫍅����������P������������e� �uP�u�u�u�u�   �؅�ur�E�8 uIV�jn ��Yt9VW�n Y��Yt,�E��}�t#�u�ǋ���P�u�u�u�u�7   �؅�t����*  ��u9]tV�?����M��B�9Xuj[_��^[�� U��ESVW�}�u�' �  ����؅�tYf�{u3f�{
u,�s���t#�0�u�u�u�Q������t�x����jX�E�uh   �3V�����    ��3��&����ȸ�*  +�tItItI���*  ���*  _^[]� V�t$��t1�F�p�t$�vj�������t�N�H�F�p��u؅�tjX�3�^� U���SVW��P�}�3ɥf��}�E�;��E��4  �}�*  f�?t
�?'  �  9Mt9Mu9M�@  9M�7  �] �]�et��t
�&'  ��   9Mto9Mtjf�w��u'��$���%�PP��P�����t� ��t�E��V�����P�E�h�PP������u��?l 9EYv~�u��u�xm YY3�9M��   9M��   �G9M�EtP�ej�EjP�����t!� ��t����tNj.V���Y��Yt?�  �:��t*����ȸ�*  +�tItIu��*  _^[�� ��*  ���u�����V�k 9EYv�V�u��l YY3��̸�*  ��U���,SVW3�j �E�WP�|k �E���E�j;�[�]�uW�5�����M�Q�M�Q�u�u�Ћ�V���;�WtV�u�K�����jX��   �d	W���   �E�E�Y;�Y�E��   9X�puu�xuof9uj�d	j��v���   ���P��E��d	Y���   f�FYP�����P��E��d	�M�QS���   ���   P�u�u��E���3��@�E�;��{���� ;�uS�K���� �u���u�d	�u���  Y3�Y_^[��U���8�E�P�u�u��h ��u&�d	V���  �E�P�u����P�u���3�^��j P�u������jX�ËD$��w-t%HtHHtHt	Hu0�4RøRø�Qø�Qø�QÃ�t%HtHt-�  t�hQø4QøQø�Pø�P�U��QW3�9}t%�}�   u�u��d W�u�u������jX�_�d	SVWW���   9}�uY��Y~'�}�E�P�uV�Uu�P�d	S�u���   ��Ouܡd	S�u���  YY�u�^d ^3�[_��U���(�EV�E؋E�E܋E�E��E�E�E �E��E$�E��EWP�E�3�Ph�  �u�}�}�}�}��td ��;�u3��3WV�u��������Wu�d	W�u��   ����YP�u���jX_^��U���V3�W�EVP�E�P�E�j�Pj�u�d ��;�t%���   u�u��c VW�u�K�����jX�   �d	VV���   ��Y3�9u�Y�Ev~�M��@j��4��d	���  �M��E�E�@�t��d	���   �M��E��Ej��@�t��d	���  �E��d	�M�Qj���   ���   PW�u��E��(@;E��Er��d	W�u���  YY�u���b 3�_^��U��QQ�EVP�u�u�$c 3�;�u�d	j���   �u�E��=	  VuA�d	���   �E�V�d	���   �E��d	�M�Qj���  ���   P�u���3��P�u������jX^��U��VW�}��vt��v���  ug�EPW�u�u�b ����t%�d	j h�R�u���  j V�u�������D�d	W�u���  �u�4   P�u����u�a 3���d	j h`R�u���  ��jX_^]�U���(�EV�uW3�H��   HtS-�  t#9}t�d	Wh�R�u���  ��3���   j�E�_P�v$�u��������u�P�d	���   Y�E��d	j��v�����  j��E��v�d	���  �v�E�d	���   �v�E�d	���   �v�E�d	���   ���E�d	j��v���  �v�E�d	���   j��E��6�d	���  �E؍E�P�d	��W���   ��_^��U��QQSV�E�W��  PV�u�u��` ��3�;�t#�d	Wh�R�u���  WS�u��������v�E��M�H�E��M�H�E��M�x �E��H$�E�P�u�V�u�u�` ��;�u3��;�u���_ WV�u��������Wu�d	W�u���   �w���YP�u���jX_^[��U���(  �E�}$ �E�E�E��E�E�E�E�t�E(��E(�E  P�EP������P�E��u,�u �u(P�u��` ��u)�d	V������j�Q���  ���  P�u���3�^��P�u�m���YY��U��Q�MW�}�  QPj W�E�貺������tjX�N�E�VP�uj�u�[` ��u�u�d	W���  �'   PW���3��PW����YYj^�u��Y��^_��U����d	V�uj��6���  j��E��v�d	���  j��E��v�d	���  �E��E�P�d	j���   �� ^��U��0  �b ������W�E��E�E�E�E�E�EԍEP�E�P������P�E�P�E�   �_ �}��tX=�   u.�E�P�u�j W藹������u6�EP�E�P�E��u�P�I_ ��t#PW����������Y9E�Yt
�u���YjX�VV�u�W�O   j��E��u�d	���  �E��d	�M�Qj���  ���   PW��� ������9E�^t
�u���Y3�_��U��d	SVWj j ���   ���d	jhDS���   ���   �]PWS��d	�u�6���   �M���   P�EWS��d	jh<S���   �M���   P�EWS��d	��@�v���   �M���   P�EWS��d	jh,S���   �M���   P�EWS��d	�v���   �M���   P�EWS��d	jh$S���   �M���   PWS�E��d	��H�v���   �M���   P�EWS��d	jhS���   �M���   P�EWS��F��$����u���d	j�Q���   �U���  P�EWS��d	jhS���   �M���   P�EWS��F��(����u���d	j�Q���   �U���  P�EWS��d	j	h�R���   �M���   P�EWS��F��(����u���d	j�Q���   �U���  P�EWS��d	j
h�R���   �M���   P�EWS��v��(����u���d	j�Q���   ���  PWS�����_^[]�U���V3�W�E�VP�E�P�E�j�PVV�E[ ��;�t%���   u�u��Z VW�u�b�����jX�   �d	VV���   9u�YY���u�v_�E��M�j��4ȡd	���  �M��E�E�j��t��d	���  �E�d	�M�Qj���   ���   PW�u���$�E��E�;E�r��d	W�u���  YY�u���Y 3�_^��U��EPj�u�u�uZ ��tj P�u������]ád	V�u���  �u�   P�u����u�Y 3�^]ád	SUVWj j ���   ��d	j	h�S���   ���   �\$$PVS��|$4�������u���d	j�Q���   ���  PVS�U �d	j
h�S���   ���   PVS�U �G��(����u���d	j�Q���   ���  PVS�U �d	jh�S���   ���   PVS�U �G��(����u���d	j�Q���   ���  PVS�U �d	j
h�S���   ���   PVS�U �d	�w���   ���   PVS�U �d	jh�S���   ���   ��@PVS�U �d	�w���   ���   PVS�U �d	jh|S���   ���   PVS�U �d	�w���   ���   PVS�U �d	��@jhlS���   ���   PVS�U �d	�w���   ���   PVS�U �d	���   jh\S���   PVS�U �G��8��u���d	j�P���   ���  PVS�U �d	jhLS���   ���   PVS�U � ��(��u���d	j�W���   ���  PVS�U ����_^][�U���  �E��E�   P������P�u�X ��tP�u�F���YY�ád	V������j�Q���  ���  P�u���3�^��U��EP�u�u�VW ��tj P�u�x�����jX]ád	Vj��u���  ���  P�u����u�V 3�^]�U��EP�u�u�W ��tj P�u�"�����jX]ád	V�u���  �   P�u����u�.V 3�^]�U����d	V�u�6���   �v�E�d	���   �E��FP�d	���   �E��F	P�d	���   j��E��v�d	���  �E��E�P�d	j���   �� ^��U��EP�u�u�>V ��tj P�u�T�����jX]ád	V�u���  ���   P�u���3�^]�U��QQV3�W�EVP�E�P�E�j�P�u��U ��;�t"���   u�u��,U VW�u�������jX�d�d	VV���   ��Y3�9u�Y�Ev.�M�����P�>   P�d	W�u���   �E��@;E��Erҡd	W�u���  YY�u��T 3�_^��U����d	V�u�6���   �v�E�d	���   �v�E�d	���   �E��FP�d	���   �E��FP�d	���   j��E��v�d	���  �E��E�P�d	j���   ��$^��U��V�u��t4��t/��t*��
t%���  t�d	j h�S�u���  ��jX�7�Ej P�EP�Ej�PV�u�u�u�vT Vh�t�u�uP�u�������^]ád	SUV3�WUU���   �\$$�|$���D$ Y+�Y�+�&  H��   Htb���g  -�  �U  �d	j	h8T���   �L$$���   P�D$(VU��d	j��w���   �L$8���  P�D$<VU���(��d	jh,T���   �L$$���   P�D$(VU��d	j��w���   �L$8���  P�D$<VU���(��d	jh T���   �L$$���   P�D$(VU��d	j��w���   �L$8���  P�D$<VU��d	j	hT���   �L$L���   P�D$PVU��d	�w���   �L$\���   ��@P�D$ VU��d	jhT���   �L$0���   P�D$4VU��d	�w���   �L$@���   P�D$DVU��d	j	h T���   �L$T���   P�D$XVU��d	��D�w���   �L$ ���   P�D$$VU��d	j
h�S���   �L$4���   P�D$8VU��d	�w���   �L$D���   P�D$HVU���4��d	jh�S���   �L$$���   P�D$(VU��d	j��7���   �L$8���  P�D$<VU���(���_^][ád	jh�S���   ���   PVU��d	�|$(j��7���   �L$8���  P�D$<VU��d	jh T���   �L$L���   P�D$PVU��d	j��w���   �L$`���  ��DPVU�D$(��d	���   �L$(jhT���   PVU�D$<��d	���   �L$<�w���   PVU�D$L��d	���   �L$Lj	h T���   PVU�D$`���D�d	���   �L$�w���   PVU�D$,����   �����U��EP�u�u�u�u�wP ��tj P�u�{�����jX]ÍEP�u�u�����P�d	�u���  ���u�O 3�]�U��V�u��t"��t�d	j h�S�u���  ��jX�4�Ej P�EP�Ej�PV�u�u��O Vh+y�u�uP�u�7�����^]ád	SUV3�WSS���   �l$$�|$���D$ Y+�Y�] ��  H�  �d	jhXL���   �L$$���   P�D$(VS��d	�w���   �L$4���   P�D$8VS��d	j	hT���   �L$H���   P�D$LVS��d	�w���   �L$X���   P�D$\VS��d	��H���   jhT�L$$���   P�D$(VS��d	�w���   �L$4���   P�D$8VS��d	j	hPT���   �L$H���   P�D$LVS��d	�w���   �L$X���   P�D$\VS��d	��H���   jh T�L$$���   P�D$(VS��d	j��w���   �L$8���  P�D$<VS��d	jhHT���   �L$L���   P�D$PVS��d	j��w���   �L$`���  ��DP�D$ VS����E �d	jhDT���   �L$$���   P�D$(VS��d	�7���   �L$4���   P�D$8VS���$�E ��_^][�U��V�u��t"��t�d	j h�S�u���  ��jX�7�Ej P�EP�Ej�PV�u�u�u�NM Vh�{�u�uP�u������^]ád	SUV3�WUU���   �\$$�|$���D$ HYHY�+�/  H�s  �d	jhtT���   �L$$���   P�D$(VU��d	�w���   �L$4���   P�D$8VU��d	j	hhT���   �L$H���   P�D$LVU��d	�w���   �L$X���   P�D$\VU��d	��H���   jh T�L$$���   P�D$(VU��d	j��w���   �L$8���  P�D$<VU��d	jh\T���   �L$L���   P�D$PVU��d	j��w���   �L$`���  ��DP�D$ VU�����d	jhDT���   �L$$���   P�D$(VU��d	�7���   �L$4���   P�D$8VU���$���_^][�U��EP�u�u�u�vK ��tj P�u�h�����jX]ÍEP�u�u����P�d	�u���  ���u�pJ 3�]�U��QQ�d	V�u�6���   �v�E��d	���   �E��E�P�d	j���   ��^��U��V�EW�}P�EP�d	�uW���   ����uU�}u9�u�EV�0�d	W���   ����u�E��V�p�d	W���   ����t�d	j h�TW���  ��jX_^]ád	SUV3�WSS���   ��d	jh�T���   ���   PVS��|$0�d	�7���   ���   PVS�U �d	jh�T���   ���   PVS�U �O�d	��@Q���   ���   PVS�U �d	jh�T���   ���   PVS�U �O�d	Q���   ���   PVS�U �d	j
h�T���   ���   PVS�U �d	��H�w���   ���   PVS�U �d	jh�T���   ���   PVS�U �G��$;�u���d	j�P���   ���  PVS�U �d	jh�T���   ���   PVS�U ���(;�u���d	j�W���   ���  PVS�U ����_^][�V�t$W3�;�t<9~t7S��U3�9~v �F�D8��tP�ӋFY�d8 E��;nr��v��Y][_^�U���SV�E�WP�E�P�d	�u�u���   �����(  �E��]3��@�s��VPW�;�u�{�#���������   9}��}��   �M�E�P�E�P�E��4��d	�u���   ������   �}���   �EP�E��0�d	�u���   ����u�E�P�E��p�d	���   �E��D8P�u�j �u莢������ud��C�M��} �8t�M���M�L8�u���u��t8�����E�E��;E��6���3�_^[�ád	j h�T�u���  ��S�a���YjX��U����d	VW3�WW���   �uYY�E�9>uj9~�}v_S�F�t�d	���   �E�F��0�p�d	���   �E��d	�M�Qj���   ���   P�u�j ��� �E�E��;Fr�[�E�_^��U����E�WP�E�P�D�3�;�WtP�u�{������d�d	W���   9}�YY�E�v1SV3ۡd	���   �E��P�����P�u��u���G��;}�r�^[�u���H �u��d	�u���  Y3�Y_��U���<SVW3ۃ=�	jXu9�	r�}��3��E�j�E�^�E��E(WP�E؉u�P�E�P�E�u(���]�]��u$�]��u �uP�u�u�u����+�t;��	 t*ItItSP�u脱�����   jhU�jhU�jh U�Vh�T�d	���   Y�E�Y�E�P�����EȍE�P�����u(�E̡d	���   ��;��E�t�w�d	�7���  Y�E�Y�d	�M�Q3�;����  ����Q���   P�u���9]�t�u��G 3�_^[��U���<SVW3ۃ=�	jXu9�	r�}��3��E܍E�j�E�^�E�P�EP�E�P�E�P�E�u���u�]�P�]��u�]��u�u��=	�tN;�tB=	 t2=	 t"=	 tSP�u�8������   jhU�!jhU�jh U�Vh�T�jh0U�d	���   Y�E�Y�E�P�����EȍE�P�����u�E̡d	���   ��;��E�t�w�d	�7���  Y�E�Y�d	�M�Q3�;����  ����Q���   P�u���9]�t�u��,F 3�_^[��U��QQSV�5��W�u���u�E����u���֋u��؍E�P�;ƍD "Pj j ��������t3��   �E��@   �E��H��M��ƉA�E��H��LJ�H�M��ǉA�E��H�P�LJ�H�M��ÉA�D6�5�P�u�E��0�֍D?P�E��u�p�֍DP�E��u�p�֋E���$_^[�Ã|$ t�t$��Y�U���,SV�uW3�3ۃ�v!��t��t��t���+  ���"  �E�PV�u�����E�4  ���6  �  +���   N�  NtvNN�M  �uԡd	���   �u؉E�d	���   �u܉E�d	���   �u��E��d	���   �u�E��d	���   �E��E�P�d	j���   ����   �uءd	�u����  �u��E�d	�u����  �E��E�Pj�J�uԡd	���   �u؉E�d	���   �u܉E�d	���   �u��E��d	���   �E��E�Pj�d	���   ���>�]ԅ�tN�d	j�S���  Y��Y��   ����   ��t0Nu&�uԡd	���   Y����t�d	W�u���  YY3�_^[�ËEԾ���u��j�P�d	���  �E�E�Y��Yu��j�P�d	���  �E��E�P�d	j���   ���}� ��t�u��C �}� �{����u���B �n����uءd	�u����  �-����d	WhDU�u���  ����tS��B �} �-���j �u�u��������/���U���`W�E�3�PW�u��;�tWP�u�̫������   �}� v�E�P�u�W�u蔚������tjX��   �E��E��E�S�E��E��EȋE�E̋EVj�E�^�u�E��E��E�P�u��u�E�  ��u�}��u����;�tWS�u�C������I�u��d	�u����   �ủE��d	�u����   �E��d	�M�QV���  ���   P�u��� 3��E�9E�t
�u���Y3�;�^[��_��U���  W�E�3�PW�u��;�tWP�u诪�����  �}� S�]V�E� 	�v�E�P�u�WS�m��������5  ��E��E��}� v�E�P�u�WS�F��������  �	��d����E�u���   v�E�PVWS����������   �	�������E�V�u�u����Eȃ��E̋E��EԋE��E��EĉE�E�j�E�_�E��u�E��E��e� P�E�   �u�E�   �u��E�	   �u�}��@ ���E�tj PS襩�����Y�u̡d	�u����   �u؉E��d	�u����   �u�E��d	�u����   �E��d	�M�QW���  ���   PS���(�5���d���9E�t�u���Y������9E�t�u���Y�E�9E�t�u���Y3�^9E�[��_��U���   �}   Vv2�d	j���  ����P�u��d	j htU�u���  ���S�� ���P�u�u�����t(�u�d	�� ���Q���  ���   P�u���3��j ���P�u�o�����jX^��QQSUVW�������D$uj�b�-$��@�  W�Ջ�Y��uj�I�D$PWV�t$(�T$ �؁�  �uV���W��Y��Y��t��uυ�tǅ�tV��S����YYP��3����_^][YY��5   ��uj� j �t$�t$�t$�t$�Ѕ�tP�޴��YP��3��jXÃ=� u.���uhP�����th�UP�������U��QQ�5   ��uj��u�M��u�uQ�u�Ѕ�tP�d���YP��3���jX�Ã= u.� ��uhP����� th�UP����ËD$V3���t,�P��t%�H��vQRj	�0�`�������u�������^�jWX^�U���   VW�d�3��=�	�Ẻ}�}�}�u�=�	�E�   s�E�   j�������Y;��u�uW���P�u�K�����jX�  9}	�E2   ���  9E|�E�d	SWW���   ��E�E�]�Phd  W�u����������  �E��  PVW�u�Ŕ��������  �E�PVW�u謔��������  ;߉}��  �Eԋh��p�}�t�9E��  �E;�|	;F���  �=�	u�~�u	�>��  ;�}��9F���  �v�jj@�l�;ǉE�t!jj�M�WQ�N�u�QP�p���u�u���9}��  �Y  ��\���j8PW�u��,�������u�u����u���9}�c  �(  hd  �u�j�u����������u�u����u���9}�:  ��  �E�f�8�E��8�}��;E���   �E��E�  �E��E��EȍE�P�E�WPh&�WW�t��u�E�P�x�=  u6j��u��|��E�h<V��P�`��E���P���M��������E�P�u������u	����E��u����"h  �u�j�u���������u	����E��u����u���9}�t9}�y  �
  �FP�d	���   �v��E��d	���   �E��FP�d	���   �v�E��d	���   ��d����E��d	���   ��h����E��d	���   �u��E��d	�u����  �E��� �;E�u�E�����QP��E����Q�p�d	���  �E�Y�YP�d	���   �E��E����Q�p�d	���  �E��d	�M�Qj
���   ���   P�u��u��� 3��E܃��E�;E��	����u�d	�u���  YY�u���Y��[_^��WhV�Wh�U�u�d	���  ��W���P�u�Z������#�d	Wh�U�u���  W�u��u�5�����9}�t	�u��6���Y9}�t
�u���Y9}�t
�u���Y9}�t
�u���Yj_�U���U��EW�}P�u�d	W��d  ����uPhpV�,�MQ�M��Ƀ�AAQP�d	��l  ����uj hPV�d	W���  ��jX�&�d	Vj �5����  �u�����PW���3�^_]�U���V�uj h�VV�u�u�_   ����tj�E�5�P�v�u��������tjX�1�u�R���P�E�h�#P����E�jP�d	�u���  ��3�^��U���8�e� �e� S�]VW�; �C  �E�}���E�<:�-  <;�%  <|u�E�   C�EH9E���  �w�����}���  � ��8~�jP��YY�����	�A����t�Ej �0�d	���   P�T  ����u�E� ���bA��   ��I%��H��   ��B��   I��   ItGIItC�_  ��L��   ����   ��l��   t~��cte��dt��ft��g�+  ��i~a�!  �M�QP�u�d	���   �����B  �<ft<Ft<dt<D��   �E����   �E����   j P�d	���   � YY�G�M�QP�u�d	���   ������   �<it0<It,<lt(<Lt$<ht<Ht<bt<B��   �E��zf�E�f��q�E��j��ot`ItB��u_�{#�{u �E��M��1P�d	���   Y�Y�ߋ}��6j P�d	���   Y�Y���j�7VP�u�k�������tH��E� ��EC�E��; ������;;��   �EH;E���   j h�V�u�d	���  ���E�@P�E�h�VP����5��j:�u�փ���uj;�u��Y��Yu���M�j Qh�VP�d	�u��   ��jX��}� u	j h�V�3�_^[�Ã=D t*�t$h��$Y��Yt�@��t$h�V���YY3��U��V�uW�}j h�VV�uW��������tF�EP�d	�vW���   ����u,�u语����Yu$�d	W��l  Yj ���PW�D�����jX�#�d	j �5����  P����PW���3�_^]�U��EPhW�u�u�u��������u]�V�d	j �5<���  �u�u�   P�u���3�^]�U��� SVW�}3�VW�u������9w�E��   9u��   VP�d	���   �M�QP�u�d	���  �]����t;�tfj�$��u��d	�P|Y�� �EY�F�Gh�< VhH= �F�^�d	j �u���  ���   YYP�u����F��t	�u舠��Y�E_^[��U��EWPh4W�u�u�u���������t"�u�S�����Y��uP���P�u趛����jX�(�d	Vj�W���  ���  P�u�W����3�^_]�U��Q�E��E��P�EPhdW�u�u�u�|�������u���u��u�u聝������U��Q�EV�uPj �e� h�WV�u�u�<�������tj�E�j P�v�u�ʟ������tjX��u�u��u臨����^��U��Q�EV�uP�E�e� Pj h�WV�u�u���������tj�E�j P�v�u�h�������tjX��u�u�u��u�M�����^��U��QQ�E�V�uP�E�e� Pj �M��h�WV�u�u�p�������tj�E�j P�v�u���������tjX��u��u�u��u������^��U��QQ�E�V�uP�E�e� Pj �M��h8XV�u�u��������tj�E�j P�v�u蔞������tjX��u��u�u��u�ק����^��U��QQ�EV�uP�E�e� P�E�Pj h|XV�u�u������ ��tj�E�j P�v�u�*�������tjX��u�u�u��u��u襧����^��U��QQV�u�Ej P�E�Pj �e� h�XV�u�u�1����� ��tj�E�j P�v�u违������tjX�*�EP�d	�v���   P�u�u�u��u��u�y����� ^��U����E�VP�E�uP�E�e� P�E�Pj �M��h YV�u�u������$��tj�E�j P�v�u�6�������tjX��u��u�u�u��u��u�_�����^��U��QQ�E�V�uP�Ej P�EPj �e� �M��hTYV�u�u�2�����$��tj�E�j P�v�u���������tjX�&�v�d	��   �u�P�u�u�u��u�^�����^��U��EWP�E�}Ph�Y�u�uW���������t/�u�u�`���u$�d	W��l  Yj ���PW�o�����jX�%�d	Vj �5����  P����PW���3�^_]�U��V�u�EWP�E�}Pj h�YV�uW�:�������tNj�E�5�P�vW�ƛ������u2�u�u�u�\���u$�d	W��l  Yj ���PW�Ȗ����jX�#�d	j �5����  P����PW���3�_^]�U��V�uj hZV�u�u��������t9j�E�5�P�v�u�(�������u�u�~�����Ytj P�u�A�����jX�3�^]�U��V�uW�}j h ZV�uW�7�������tj�E�5�P�vW�Ú������tjX�-�u�X��d	j �5<���  PW����PW���3�_^]�U��V�uj h<ZV�u�u���������t9j�E�5�P�v�u�M�������u�u若����Ytj P�u�f�����jX�3�^]�U��V�uj hXZV�u�u�^�������tj�E�5�P�v�u��������tjX�'�u�T��d	P���  ���   P�u���3�^]�U��QV�uj �e� htZV�u�u���������t0j�E�j P�v�u�x�������u�u��h���u�u����YjX�3�^��U��QSV�uW�]3�Wh�ZV�}��uS��������t:j�E�WP�vS��������u#9}�u#�d	S��l  YW���PS�(�����jX�#�d	W�5����  �u��q���PS���3�_^[��U��Q�E��E��P�EPh�Z�u�u�u���������u�ÍEP�u�u��u蜂������u(�d	Vj �5<���  �u�����P�u���3�^��U��QV�uj �e� h�ZV�u�u��������tj�E�j P�v�u��������tjX��}� t
�u���Y3�^��U��V�u�EW�}Pj h�ZV�uW�)�������t7j�E�5�P�vW赗������u�EP�u�u�����uW�N���YjX�5�d	j �5����   �u������P�d	W���  YPW���3�_^]�U��QV�u�EWP�E�}Pj h [V�uW��������t:j�E�5�P�vW��������u�E�P�u�u�u�����uW詟��YjX�5�d	j �5����   �u��q�����P�d	W���  YPW���3�_^��U��V�uj hd[V�u�u���������t�EP�v�u��������t�} t
�u��YjX��u�u芇��YY^]�V�t$j j h�[V�t$ �t$ ��������u^ád	W�v��   �v���d	��   PW�t$ �	�����_^�U��V�uWj j h�[V�u�u�7�������t&�v�d	��   ���EP�v�u�@�������t�} t
�u��YjX��uW�u�   ��_^]�U���$SVW3��}�3�����E�=��P�E�P�E�VPV�E�   �u�u��u�u��u�u��ׅ�u7�����;�t+��zt&�d	Vh�[�u���  VS�u�M�������   �]�E�P�E��PVS���������   �E�P�E��PVS��~��������   �E�P�E�P�E��u�P�u��u�u�ׅ�u(�d	Vh�[S���  ��V���PS�ɏ�����X�d	j��u����  j��E��u��d	���  �u�E�d	���   �E�d	�M�Qj���  ���   PS���$�u�9u��=�t�u���Y9u�t�u���Y�E�_^[��U��EV�uPj h\V�u�u�I�������tj�E�5�P�v�u�ӓ������tjX��u�u�u�D�����^]�U��V�uW�}j j hD\V�uW���������tHj�E�5�P�vW�x�������u,�EP�vW��������u�u�u�8���Y��YuW� ���Y�} t
�u��YjX��} t
�u��Y3�_^]�U��V�uW�}j j hx\V�uW�S�������tHj�E�5�P�vW�ߒ������u,�EP�vW�R�������u�u�u�����Y��YuW�g���Y�} t
�u��YjX��} t
�u��Y3�_^]�U���VW3��E��uWPW�E�WPWWWh�\V�u�u������0��u��   �E�}P�d	�v���  9}YY�E�u�}��v�d	��   �v�E�d	��   �E��EP�d	�v�}���  ��9}�Eu�}�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v ���  9}YYu3�P�u�S�u�u��u��u��u��u蚩����$[_^��U��V�uW3�WWh ]V�u�u��������tI�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS�_  ;�[tWP�u�K�����jX�3�_^]�U��EV�uPj h,]V�u�u�>�������u�/�e �EP�d	�v���  �} YYu3��uP�u�J�����^]�U��V�uj h\]V�u�u���������u�+�e �EP�d	�v���  �} YYu3�P�u�.���YY^]�U��V�uj h�]V�u�u��������u�+�e �EP�d	�v���  �} YYu3�P�u����YY^]�U��V�uj j h�]V�u�u�B�������u�?�e �ESP�v�d	���  �} YY��u3��v�d	��   PS�u������[^]�U��EV�uPj j h�]V�u�u���������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u覦����[^]�U��V�uj j h^V�u�u�k�������u�?�e �ESP�v�d	���  �} YY��u3��v�d	��   PS�u�u�����[^]�U��V�uj j hX^V�u�u��������u�?�e �ESP�v�d	���  �} YY��u3��v�d	��   PS�u�D�����[^]�U��EV�uPj j h�^V�u�u��������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u������[^]�U��EV�uPj j h�^V�u�u�(�������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u�8�����[^]�U��EV�uPj j h�^V�u�u��������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u������[^]�U��V�uW3�WWWh4_V�u�u�L�������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u觰����;�[tWP�u�ȇ����jX�3�_^]�U��V�uW3�WWWht_V�u�u��������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u�4�����;�[tWP�u�7�����jX�3�_^]�U��V�uW�E3�PWWh�_V�u�u�'�������tN�ESP�d	�v�}���  9}YY��u3��v�d	��   �uPS�ӯ����;�[tWP�u赆����jX�3�_^]�U��V�uW3�WWWh�_V�u�u��������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u�c�����;�[tWP�u�$�����jX�3�_^]�U��V�uW3�WWWhD`V�u�u��������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u������;�[tWP�u蓅����jX�3�_^]�U��V�uW�E3�PWWh�`V�u�u��������tN�ESP�d	�v�}���  9}YY��u3��v�d	��   �uPS蒮����;�[tWP�u������jX�3�_^]�U��V�uW3�WWWh�`V�u�u��������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u�"�����;�[tWP�u耄����jX�3�_^]�U��V�uW�E3�PWWhaV�u�u�p�������tN�ESP�d	�v�}���  9}YY��u3��v�d	��   �uPS�������;�[tWP�u�������jX�3�_^]�U��V�uW3�WWWh`aV�u�u���������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u�Q�����;�[tWP�u�m�����jX�3�_^]�U��V�uW�E3�PWWh�aV�u�u�]�������tN�ESP�d	�v�}���  9}YY��u3��v�d	��   �uPS������;�[tWP�u������jX�3�_^]�U��V�uW�E3�PWWh�aV�u�u���������tN�ESP�d	�v�}���  9}YY��u3��v�d	��   �uPS菬����;�[tWP�u�i�����jX�3�_^]�U��V�uW3�WWWhHbV�u�u�\�������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u������;�[tWP�u�؁����jX�3�_^]�U��V�uW3�WWWh�bV�u�u���������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u诫����;�[tWP�u�G�����jX�3�_^]�U���  V�uW�}j j h�bV�uW�4�������tK�v�d	��   �E�E�P�vW�^   ����u&������h   P�E�P�u�������uW�E���YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U��d	SVW�u��X  ��V�D Y��YuC�~-u=�=���EjPV�׋]���C�F9Eu�EjP�F	P�׉�F��9Eu3��13�9}t'�d	Wh(c�u���  �d	WV�u��   ��jX_^[]�U���   V�uj j h@cV�u�u���������tC�d	S�v��   �v�ءd	��   �� ���h   QPS裙������[u�u����YjX�*�d	f�e� �� ���j�Q���  ���  P�u���3�^��U��QQV�uj j h�cV�u�u�W�������tL�e �ESP�v�d	���  �} YY��u3��v�d	��   Y�M�QPS�����[u�u�g���YjX��d	���  �E�P�ǖ��P�u���3�^��U��V�uj h�cV�u�u���������t�EP�v�u�ێ������t�} t
�u��YjX�7�u���d	P���  ���   P�u����} t
�u��Y3�^]�U��QV�u�EW�}Pj �e� j h�cV�uW�.�������tPj�E�5�P�vW躂������u4�E�P�vW�{   ����u �EP�u�u��u�~�������uW�:���Yj^�-�u�d	���   Y�d	PW���   ���  YPW���3��u��   Y��_^�Ã|$ t�t$��Y�U��Q�E�VP�EP�d	�u�u���   ����uU�uV�u�u�P   ����u?��M��E��H�ɉEt1��@�L�Q�M��4��u�S   ����u��6�w����& YjX^��3���V�t$W�|$�vW��   Pj �t$�k������tjX���03�_^�U��QV�EW�}P�E�P�d	�uW���   ����u`�}�u3�u�FP�E�p�d	W���   ����u�EV�0W��������t*��t#�d	j �u��   ��X  YPh$dW���jX_^��U��QV�u3�W�M�}PQPhDdV�E��uW��������t0j�E�5�P�vW蠀������u�E�P�vW�a�������t�u��?���YjX��u��u�uW�ƕ����_^��U��V�uW3�WWWh�dV�u�u��������tq�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �؍EP�d	�v�}���  ��9}u3�PS�u������;�[tWP�u�{����jX�3�_^]�U��V�uW3�WWWh�dV�u�u���������tq�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �؍EP�d	�v�}���  ��9}u3�PS�u�g�����;�[tWP�u�cz����jX�3�_^]�U��V�uW3�WWh�dV�u�u�W�������tI�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS� ;�[tWP�u��y����jX�3�_^]�U��V�uW3�WWh eV�u�u���������tI�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS� ;�[tWP�u�qy����jX�3�_^]�U��V�uW3�WWWhPeV�u�u�d�������t_�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   YYPS�u� ;�[tWP�u��x����jX�3�_^]�U��V�uW3�WWWh�eV�u�u���������t_�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   YYPS�u�} ;�[tWP�u�Qx����jX�3�_^]�U��V�uW3�WWWh�eV�u�u�D�������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u������;�[tWP�u��w����jX�3�_^]�U��V�uW3�WWWhfV�u�u��������t`�E�}P�d	�v���  9}YY�Eu�}�d	S�v��   �v�ءd	��   PS�u�t�����;�[tWP�u�/w����jX�3�_^]�hXf�t$�t$�t$�*�������u��t$�J���Y�U��QV�uj �e� h�fV�u�u���������t�E�P�v�u�V   ����t�}� t
�u���YjX�7�u�����d	P���  ���   P�u����}� t
�u���Y3�^��U����ESVW�u3��8�d	�}���X  Php�� ������  �E�uP�E�P�d	�uV���   ������  j[9]�t";���  �d	Wh�fV���  ���  �E�P�E�P�E��p�d	V���   �����H  �E��]�$�;��E   tb��P��;�Y�E�tc3�9}�~M�8A��;M�|�9}�~=�u��E�V�4��u�B  ������   ��HM�8v�E�   G��;}�|�3��u��Y;ǋM�u9}��   Wh�V�u��uP���9}�~*�u���HQP�Ej��u��0�����t8G��;}�|�3��E�0�����u|9}t5Wh�f�u�d	���  ����} tj ���P�u�t����3��u�;�t#9}�~�6��G��;}�Y|�3��u���Y�u�;�t
P��Y�>jX�+9}�t$�5�3�9}�~�}��7��C��;]�Y|��u���Y3�_^[��U����ESV�]�  �EWP�E�P�d	�uS���   �����  �}��  �E�P�E�0�d	S���   ������   �E�P�E�p�d	S���   ������   j����}� ����   �}���   �}���   ��W�$���Y����   �E���E��F�Ff�~P�E�p�d	S���   ����uk�E�p�d	��X  P�G�����Y��Yt�FWP�F��P����Wu%��Y��tj ���PS��r����jX_^[����Y�g�}�t��t�j hg�8�E�P�E�p�d	���   }��W�$�������u�]��t�j h�d	S���  ��u�SV�����E�03��U��QV�uj �e� hgV�u�u�s�������t�E�P�v�u�  ����t�}� t	�u��?   YjX�6�u�����d	P���  ���   P�u����}� t	�u��   Y3�^��U���SW�}3�;���   W�������   �E�VP�EPW�D��5���t9]t�u��Y�E�P�EPW�H���t9]t�u��Y�E�P�E�P�E�PW�L���t9]�t9]�t�u���Y�E�P�E�P�E�PW�P���t9]�t9]�t�u���YW��Y^_[��U���SV�u�E�]WP�E�P3��u�>�d	�}�S�}����   �����!  9}��  �}�t";��
  �d	WhtgS���  ����  j�$�;�Y�u;���  Wh�JjP�T����Z  �E�P�E�0�d	S���   �����p  �E���;�t#���^  j hDg�d	S���  ���C  � ?  f#�PQ�6�������   �E�P�E�p�d	���   �}� ���YYt'P������Y�E���   �ǃ�P�u��6�Ӆ���   �E�P�E�p�d	���   �}� YYtP�р����Y�E�t{�ǃ�P�u��6�Ӆ�tj�EP�E�p�u�%�������uj�ǃ�P3�9E�u��P�6�����t3�E�P�E�p�u���������u3�� 9E�W�u���P�6�����un�]��tj ���PS�"o�����}� t
�u���Y�}� t
�u���Y3�9}t
�u��Y9}�t
�u���Y�;�t
P��Y�>jX�3�_^[��U��V�u�EWP�E�}Pj h�gV�uW��������tU�v�d	��   �u�uP����������u �d	W��l  YV���PW�Yn������EPVW���������tjX��u�d	W���  YYV� �3�_^]�U���SV3�WS�uSS�ESP�E�}PSh�gV�]��u�]�W������,����   �v�d	��   �E��EP�vW�~������uf�EP�vW��}������uR�E�P�vW�/�������u>�E�P�vW��������u*�u��u��u�u�u�u��u����;�tBSPW�Xm����9]�5�t�u��Y9]t�u��Y9]�t�u���Y9]�t�u���YjX�49]�5�t�u��Y9]t�u��Y9]�t�u���Y9]�t�u���Y3�_^[��U��QV�u�EWP�E�}Pj hHhV�uW���������tej�E�5�P�vW�kq������uI�u�u�u�^���������u �d	W��l  YV���PW�jl������E�PVW�	�������tjX��u��d	W���  YYV� �3�_^��U���SV3�WS�uSS�ESP�E�}PSh�hV�]��u�]�W������,����   j�E��5�P�vW�p������uz�EP�vW�|������uf�EP�vW�|������uR�E�P�vW�5�������u>�E�P�vW�!�������u*�u��u��u�u�u�u��u����;�tBSPW�^k����9]�5�t�u��Y9]t�u��Y9]�t�u���Y9]�t�u���YjX�49]�5�t�u��Y9]t�u��Y9]�t�u���Y9]�t�u���Y3�_^[��U���V�E�uWP�E�3�PWWWh�hV�u�u�������$��te�d	S�v��   �E��EP�d	�v�}���  ��9}��u3��v�d	��   Y�M�Q�u�u�PS�u������[u�u��w��YjX�8�d	W�5����   �u�衬����P�d	�u���  YP�u���3�_^��U��V�uj h$iV�u�u��������t4j�E�5�P�v�u�n������u�u�����u�u�Aw��YjX�3�^]�hLi�t$�t$�t$��������t�����u�t$�w��YjX�3��U��EPhdi�u�u�u��������t�u�����u�u��v��YjX]�3�]�U��V�uW�}j j h�iV�uW�;�������tOj�E�5�P�vW��m������u3j�E�5�P�vW�m������u�u�u�����uW�Hv��YjX�3�_^]�U���SV�EW�uP�E3�P�E�}SPSh�iV�u�]�W������$��tTj�E��5�P�vW�4m������u8�E�P�vW�   ����u$�E�P�u�u�u��u�u������uW�u��Y9]�t	�u��M   YjX�B�d	S�5����   �u��k�����P�d	W���  YPW���9]�t	�u��   Y3�_^[��V�t$��t�F��tP�����YV��Y^�U��S�E�]V�uP�E�& P�u�d	S���   ������   9E��   �}t"����   P�d	hjS���  ���   j�$���Y�u��taP�d	hS���  ���J�    �EP�E�p�d	S���   ����t&�3�9E���A���P�E�0S��������u���tP���& YjX�3�^[]�U����EPhXj�u�u�u���������t �u�E�P迗��Y��Ytj P�u�f����jX�ád	V���  �E�P��[��P�u���3�^��U���hxj�u�u�u�Z�������t�E�P�����tj P�u�f����jX�ád	V���  �E�P�m[��P�u���3�^��U��QQh�j�u�u�u���������t�E�P�����u�u�;s��YjX�ád	V���  �E�P�}��P�u���3�^��U��EP�EPh�j�u�u�u��������t�u�u�t���u�u��r��YjX]�3�]�h�j�t$�t$�t$�Q�������t�x���u�t$�r��YjX�3��U���  �EPh�j�u�u�u��������t$������h  P�u��������u�u�Fr��YjX�ád	f�e� V������j�Q���  ���  P�u���3�^��U���(  SVj�E�j P�_� �u�E��]Pj h$kV�uS�|�����$��t~�E�P�d	�v���  YY�M���   s_�L	QP������P���E��u��f�E�f�E��������E��E�P�E�P�G�������u$�d	S��l  Yj ���PS��c����jX�#�d	j �5����  P�#���PS���3�^[��U��V�uj h\kV�u�u��������tj�E�5�P�v�u�:h������tjX�&�u�k� �d	P���  ���   P�u���3�^]�U��V�uW�}j j h|kV�uW�>�������t0j�E�5�P�vW��g������u�EP�vW�=s������t�} t
�u��YjX��u�uW�I�����_^]�U���  V�uj j h�kV�u�u��������t=j�E�5�P�v�u�Fg������u�EP�d	�v���  YY�M��   rjX�;�L	QP������P���E�f�E�f�E��������E��E�P�u�u�]�����^��U��QSV�u3�W�}SSShlV�]��uW��������tHj�E�5�P�vW�f������u,�EP�vW�r������u�EP�E�P�vW�5   ����t9]t
�u��YjX��u�u��u�uW茔����_^[��U��QQV�E�WP�E�P�d	�u�u���   ����t@�E�3�������v�E��4��d	���  GY;}��tFr�EPVj �u��O������tjX�v�E��M3����4�vX�EP�E��4��d	���  �M�L	QPV���E���t��E�M�f���Ef����Gf�H�E�tF�E�;�r��M�U��M�3�_^��U��QQSV�u3�W�ES�}PSShllV�]��uW肿���� ��tHj�E��5�P�vW�e������u,�EP�vW�p������u�EP�E�P�vW��������t9]t
�u��YjX��u�u��u�u�u�W�M�����_^[��h�l�t$�t$�t$��������u��t$�r���Y�U��QQV�uj h mV�u�u軾������t�E�P�v�u���������tjX��E�P�u賓��YY^��U��EV�uPj h(mV�u�u�i�������tj�E�5�P�v�u��c������tjX��u�u�u豖����^]�U��Q�EV�uPj �e� hdmV�u�u��������tj�E��5PP�v�u�c������tjX��E���t�M�3�^��U��QV�uj �e� h�mV�u�u謽������tj�E��5PP�v�u�6c������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�mV�u�u�9�������tj�E��5PP�v�u��b������tjX��E���t�M�H3�^��U��QV�uj �e� h,nV�u�u�ݼ������tj�E��5PP�v�u�gb������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h`nV�u�u�i�������tj�E��5PP�v�u��a������tjX��E���t�M�H3�^��U��QV�uj �e� h�nV�u�u��������tj�E��5PP�v�u�a������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�nV�u�u虻������tj�E��5PP�v�u�#a������tjX��E���t�M�H3�^��U��QV�uj �e� hoV�u�u�=�������tj�E��5PP�v�u��`������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hLoV�u�u�ɺ������tj�E��5PP�v�u�S`������tjX��E���t�M�H3�^��U��QV�uj �e� h�oV�u�u�m�������tj�E��5PP�v�u��_������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��QV�uj j �e� h�oV�u�u���������t<j�E��5PP�v�u�_������uj�E�5�P�v�u�g_������tjX��E��H3��Uf�f�@@=   |�3�^��U��QV�uW�}�e� j h�oV�uW�p�������tj�E��5PP�vW��^������tjX�*�E��d	j ���5����  PW�C���PW���3�_^��U��Q�EV�uPj �e� h,pV�u�u���������tj�E��5PP�v�u�^������tjX��E���tf�Mf��  3�^��U��QV�uj �e� htpV�u�u蕸������tj�E��5PP�v�u�^������tjX�*�E�f��  �d	��Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�pV�u�u��������tj�E��5PP�v�u�]������tjX��E���tf�Mf��  3�^��U��QV�uj �e� h�pV�u�u蹷������tj�E��5PP�v�u�C]������tjX�*�E�f��  �d	��Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h,qV�u�u�>�������tj�E��5PP�v�u��\������tjX��E���tf�Mf��  3�^��U��QV�uj �e� hhqV�u�u�ݶ������tj�E��5PP�v�u�g\������tjX�*�E�f��  �d	��Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�qV�u�u�b�������tj�E��5PP�v�u��[������tjX��E���t	�M��  3�^��U��QV�uj �e� h�qV�u�u��������tj�E��5PP�v�u�[������tjX�)�E���  �d	��Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hrV�u�u艵������tj�E��5PP�v�u�[������tjX��E���t	�M��  3�^��U��QV�uj �e� h@rV�u�u�*�������tj�E��5PP�v�u�Z������tjX�)�E���  �d	��Q���  ���   P�u���3�^��U��hpr�u�u�u轴������u]�Vh  j����d	j �5P���  P�u襸��P�u��� 3�^]�U��QV�uj �e� h�rV�u�u�[�������tj�E��5PP�v�u��Y������tjX��u���Y3�^���t$��Y�U��QV�uj �e� h�rV�u�u���������t4j�E��5PP�v�u�Y������u�u�� �����Yu�u�b��YjX�3�^��U���   h�r�u�u�u蔳������t �� ���h   P����Y��Yu�u��a��YjX�ád	f�e� V�� ���j�Q���  ���  P�u���3�^��U���   �EPhs�u�u�u��������t$�� ���h   P�u袌������u�u�Qa��YjX�ád	f�e� V�� ���j�Q���  ���  P�u���3�^��U��QQV�EWP�u�E�P�E�3�PWWhHsV�u�u菲����$��t^�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v���  9}YYu3��u�u��u�PS�����[u�u�`��YjX�3�_^��U��V�uj h�sV�u�u��������t4�e �EP�d	�v���  �} YYu3�P�����u�u�,`��YjX�3�^]�U��S�]V�EWPh   j S�kA������uR�}�uPh�sW�uS臱������t(�w�d	��   �$ �  VP�P���uS�_��Y��tV��YjX�1f����   �d	j�V���  ���  PS�����tV��Y3�_^[]�U���SVW3��E�uWP�E��}�P�E�WPhtV�u�u������$��thj�E�5�P�v�u�jV������uJ�E� �E�E�P�EP�d	�v�u���   ����t!�E�M���Q��   PW�u�>@������t9}�t
�u���YjX�F3�;�v�E�W�4��d	���  YY�M���F;�r�E��<��u�S�u��u��u��u��u�2�����_^[��U���SV�uW3��E�WWPhttV�}��u�u��������tS�v�d	��   �E��EP�EP�d	�v�u���   ����t!�E�M���Q��   PW�u�\?������t9}�t
�u���YjX�@3�;�v�EW�4��d	���  YY�M���F;�r�E��<��u�S�u��u��u�������_^[��U��EV�uPj h�tV�u�u��������u�^�d	W�v��   Y�uj P���j�E�$����EjPW���d	j�5����  W�u�ز��P�u���(3�_^]�U��V�uj h�tV�u�u蒮������t6j�E�5�P�v�u�T������u�E�0����u�u�\��YjX�3�^]�h u�t$�t$�t$�4�������u��t$�t���Y�U��3�V�u�MPQPPhuV�u�u������� ��u�_�d	SW�v��   �v���d	��   �v�ءd	��   ��P�uSW�L��d	P���  ���   P�u���3�_[^]�U��EV�uPj j hduV�u�u�s�������u�K�d	W�v��   �v���d	��   YY�uPW�H��d	P���  ���   P�u���3�_^]�U��QQSV�E�WP3�h   S�u��<������u/�uSSSS�}�h�uV�u�u�ݬ���� ��u;�tW��YjX�   �v�d	��   �v�E��d	��   �v�E�d	��   �v�E�d	��   ��Ph �  W�u�u�u��D��d	P���  ���   P�u�f����  �d	j�W���  ���  P�u���;�tW��Y3�_^[��U��S�]V�EWP3�h   VS��;������u,VVV�u�}h�uV�uS�ݫ������u��tW��YjX�   �v�d	��   �v�E�d	��   �v�E�d	��   ��h �  WP�u�u�@��d	P���  ���   PS�f����   �d	j�W���  ���  PS�����tW��Y3�_^[]�U��Q3�V�uPPPPhLvV�u�u������ ����   �d	SW�v��   �v�E��d	��   �=���,$SP�E�׃���u!E�v�d	��   SP�E�׃���_[u!E�v�d	��   YP�u�u�u��<���u�u��X��YjX�3�^��U��3�S�]PPPh�vS�u�u�R���������   �d	VW�s��   �5���,$WP�E�փ���u!E�s�d	��   WP�E�փ���u!E�s�d	��   ��WS�փ���_^u3�S�u�u�8���u�u�&X��YjX�3�[]�U��V�uj j h�vV�u�u蜩������u�@�d	S�v��   �e �؍EP�d	�v���  ���} u3�PS�u������[^]�U��V�uj hwV�u�u�5�������u�+�e �EP�d	�v���  �} YYu3�P�u�ن��YY^]�hDw�t$�t$�t$��������u��t$����Y�U��QQ�EV�uP�Ej P�E�P�e� h`wV�u�u觨���� ��t9j�E�j P�v�u�5N������u�u�u��u�u��|���u�u��V��YjX�3�^��h�w�t$�t$�t$�F�������u��t$����Y�h�w�t$�t$�t$��������u��t$�؈��Y�U��QV�uW3�W�EWPWh�wV�u�u������ ��tj�E��5�P�v�u�oM������tjX�D�d	S�v��   �؍EP�d	�v�}���  ��9}u3�PS�u�u��u�L�����[_^��U��V�uW�}j j h4xV�uW�T�������tOj�E�5�P�vW��L������u3j�E�5�P�vW��L������u�u�u�L���uW�aU��YjX�3�_^]�U��W�}h`x�u�uW�ڦ������t�EP�P���uW�!U��YjX�/�d	V�u���   Y�d	PW���   ���  YPW���3�^_]�U��QQhxx�u�u�u�n�������u�ÍE�VP�4��d	���  �E�P�#:��P�u���3�^��h�x�t$�t$�t$�!�������u�V�0��d	P���  ���   P�t$���3�^�U���V�uW�}j h�xV�uW�ѥ������t-�E�P�vW�9������u�E�P�E�P�,���uW� T��YjX��d	���  �E�P�"7��PW���3�_^��U���V�uW�}j h�xV�uW�W�������t-�E�P�vW�7������u�E�P�E�P�(���uW�S��YjX��d	���  �E�P��8��PW���3�_^��U��EPhy�u�u�u��������t�u�Ȉ����Yu�u�(S��YjX]�3�]�U���hDy�u�u�u袤������t�EP������Yu�u��R��YjX���u�E�h�#P����E�jP�d	�u���  ��3���U��V�uj hlyV�u�u�7�������t2�EP�d	�v�u���   ����u�u賈����Yu�u�aR��YjX�3�^]�U��EWP�EP�E�}Ph�y�u�uW�ϣ������t2�u�u�u�l���u$�d	W��l  Yj ���PW�yD����jX�%�d	Vj �5����  P�����PW���3�^_]�W�|$h�y�t$�t$W�P�������t)�d���u$�d	W��l  Yj ���PW�D����jX_Ëd	Vj �5����  P�K���PW���3�^_�U��EV�uPj h�yV�u�u�բ������t7j�E�5�P�v�u�_H������u�u�u�$���u�u��P��YjX�3�^]�U���  V�uW�}j j h(zV�uW�h�������tXj�E�5�P�vW��G������u<�EP�d	�vW���   ����u"������h  P�u�u�� ��uW�lP��YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U���  V�uW�}j j hlzV�uW賡������tXj�E�5�P�vW�?G������u<�EP�d	�vW���   ����u"������h  P�u�u�`� ��uW�O��YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U���  V�uW�}j h�zV�uW� �������t9�EP�d	�vW���   ����u������h  P�u��� ��uW�#O��YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U���  V�uW�}j h�zV�uW�l�������t9�EP�d	�vW���   ����u������h  P�u�D� ��uW�N��YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U��� V�uW�}j j hL{V�uW�ٟ������tRj�E�5�P�vW�eE������u6�EP�d	�vW���   ����u�E�jP�u�u�� ��uW��M��YjX�   �5��S�u���#�E�SP�֡d	h@{W��  �E�P�d	W��  �u��E�h�VP�֡d	h4{W��  �E�P�d	W��  �u��E�SP�֡d	��Dh({W��  �E�P�d	W��  ��3�[_^��h�{�t$�t$�t$�Þ������u��t$近��Y�U��V�uj h�{V�u�u蕞������tj�E�5�P�v�u�D������tjX��u�u�~���YY^]�h�{�t$�t$�t$�D�������u��t$�d���Y�h�{�t$�t$�t$��������u�V� ��d	P���  ���   P�t$���3�^�W�|$h�{�t$�t$W�ѝ������t)����u$�d	W��l  Yj ���PW�>����jX_Ëd	Vj �5����  P�̀��PW���3�^_�U��EWP�EP�E�}Ph|�u�uW�P�������t2�u�u�u����u$�d	W��l  Yj ���PW��=����jX�%�d	Vj �5����  P�B���PW���3�^_]�U��EV�uPj hP|V�u�u�˜������tj�E�5�P�v�u�UB������tjX��u�u�u�Տ����^]�U���|SVW3�WW�E�W�uP�E�]PWWWWh�|V�}��u�}�}�S�T�����4���  �E�}P�d	�v���  9}YY�E�u�}��E�}P�d	�v���  9}YY�Eu�}�E�P�vS�&���������   �E�P�vS����������   �v�d	��   �$,$P�E����Y��Yu�}���E�P�vS�3������tg�E�}P�d	�v ���  9}YY��u3ۍE�P�v$�u��������u1�E�P�E�PS�u��u��u��u��u��u�u�����u<�u�I��Y9}�t	�u��/���Y9}�t	�u��!���Y9}�t
�u���YjX�   W�5��u��8~��W�E��5��u��&~���u��E̡d	���   �u�EСd	���   �Eԡd	�M�Qj���  ���   P�u���09}�t	�u�����Y9}�t	�u�����Y9}�t
�u���Y3�_^[��U���   SVW3�WW�E�WP�u�E�]PWWWWWh<}V�u�}��}�}�S�'�����8���=  j�E��5�P�vS�?�������  �E�}P�d	�v���  9}YY�E�u�}��E�}P�d	�v���  9}YY�Eu�}�E�P�vS�����������   �E�P�vS�����������   �v �d	��   �$,$P�E����Y��Yu�}���E�P�v S�c1������tj�E�}P�d	�v$���  9}YY��u3ۍE�P�v(�u�Ȍ������u4�E�P�E�PS�u��u��u��u��u��u�u��u������u<�u�BG��Y9}�t	�u������Y9}�t	�u������Y9}�t
�u���YjX�   W�5��u���{��W�E��5��u���{���u܉Eȡd	���   �u��E̡d	���   �EСd	�M�Qj���  ���   P�u���09}�t	�u��F���Y9}�t	�u��8���Y9}�t
�u���Y3�_^[��U��V�uW�}j h ~V�uW���������t1j�E�5�P�vW�=������u�u�����uW�"F��YjX��d	P���  ���   PW���3�_^]�U��V�uW�}j h ~V�uW�}�������t1j�E�5�P�vW�	=������u�u�����uW�E��YjX��d	P���  ���   PW���3�_^]�U��EV�uPj h@~V�u�u��������t7j�E�5�P�v�u�<������u�u�u����u�u�&E��YjX�3�^]�U��V�uW�}j ht~V�uW蜖������t0j�E�5�P�vW�(<������u�u����uW��D��YjX��d	P���  ���   PW���3�_^]�U��EV�uPj h�~V�u�u�!�������t7j�E�5�P�v�u�;������u�u�u� ���u�u�FD��YjX�3�^]�U��V�uW�}j h�~V�uW輕������t3j�E�5�P�vW�H;������u�u���=���uW��C��YjX��d	P���  ���   PW���3�_^]�U��V�uj h�~V�u�u�B�������tj�E�5�P�v�u��:������tjX��u�u����YY^]�U��V�uj h0V�u�u��������tj�E�5�P�v�u�w:������tjX��u�u�)���YY^]�U��QQSV�u�MW3�Q�}PPPhpV�E��uW艔���� ��toj�E�5�P�vW�:������uS�EP�d	�vW���   ����u9jP�]�E�P�vW��9������u�E�P�u�u�S�u�����uW�vB��YjX�-�u��d	���   Y�d	PW���   ���  YPW���3�_^[��U��V�uW�}j h�V�uW迓������t4j�E�5�P�vW�K9������u�EP�u�����uW��A��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U��h��u�u�u�7�������u]������u�u�d	��l  Y� �d	Vj�P���  ���  P�u���^3�]�V�t$j h�V�t$�t$�Ԓ������u^��v�d	��   P�t$������^�U��EP�EPh��u�u�u菒������u]��u�u�u�ww����]�U���V�uW�}j hD�W�uV�S�������t-�w�d	��   Y�M�Q�M�Q�M�QP�����uV�@��YjX�   �u��d	�u����   ���  YYP�d	V���  YPV��u��d	�u����   ���  ��P�d	V���  YPV��u�d	�u荸�   ���  ��P�d	V���  YPV���3�_^��V�t$j hd�V�t$�t$�p�������u^��v�d	��   YP����d	P���  ���   P�t$���3�^�h���t$�t$�t$��������u�V����d	P���  ���   P�t$���3�^�U���   V�uW�}j h��W�uV�Ɛ������tB�w�d	��   Y�� ����   QR�UR�UR�URQ�� ���QP�����uV��>��YjX��   �d	f�e� �� ���j�Q���   ���  YYP�d	V���  YPV��u�d	���   �d	��PV���   ���  YPV��u�d	���   �d	��PV���   ���  YPV��u�d	���   �d	��PV���   ���  YPV��d	f������ �� ���j�Q���   ���  ��P�d	V���  YPV���3�_^��U��V�uj j h��V�u�u�g�������tH�d	S�v��   �e �؍EP�d	�v���  ���} u3�PS�����[u�u�{=��YjX�3�^]�U��V�uj h$�V�u�u��������u�+�e �EP�d	�v���  �} YYu3�P�u����YY^]�U��V�uj �Ej PhL�V�u�u蛎������t:�d	W�v��   �v���d	��   YYPW�u�����_u�u�<��YjX�3�^]�U���   W�}h���u�uW�1�������t6�� ���h   P������u$�d	W��l  Yj ���PW��.����jX�Y�d	Vj �5����  P�q��PW��d	f�e� �� ���j�Q���   ���  ��P�d	W���  YPW���3�^_��U���   V�uW�}j h��V�uW�p�������t?j�E�5�P�vW��2������u#�� ���h   P�u���������uW�;��YjX�P�d	P���  ���   PW��d	f�e� �� ���j�Q���   ���  ��P�d	W���  YPW���3�_^��U��V�uj h�V�u�u趌������t4j�E�5�P�v�u�@2������u�u�����u�u��:��YjX�3�^]�U���  V�uW�}j h�V�uW�N�������tG�v�d	��   �������$  QP������u$�d	W��l  Yj ���PW��,����jX�W�d	j �5����  P�,o��PW��d	f�e� ������j�Q���   ���  ��P�d	W���  YPW���3�_^��U���  V�uW�}j hP�V�uW�}�������t?j�E�5�P�vW�	1������u#������h  P�u�Y��������uW�9��YjX�P�d	P���  ���   PW��d	f�e� ������j�Q���   ���  ��P�d	W���  YPW���3�_^��U��V�uj h��V�u�u�Ê������t4j�E�5�P�v�u�M0������u�u�����u�u��8��YjX�3�^]�V�t$j j h��V�t$ �t$ �a�������t8�d	W�v��   �v���d	��   YYPW�����_u�t$�8��YjX^�3�^�V�t$j h�V�t$�t$���������t$�v�d	��   YP�����u�t$�68��YjX^�3�^�U���   V�uj h�V�u�u詉������t0�v�d	��   �� ����$   QP�����u�u��7��YjX�*�d	f�e� �� ���j�Q���  ���  P�u���3�^��U���  V�uj hX�V�u�u��������t0�v�d	��   �������$  QP�����u�u�K7��YjX�*�d	f�e� ������j�Q���  ���  P�u���3�^��U���SV3�W�ESP�E�uP�E�SP�E�}PSh��V�]��uW������,��t�v�d	��   �E��E�P�vW��������uZj�E�5�P�vW��-������u>�u�u�u�u��u��u��u�������u1�d	W��l  YS���PW��(����9]�t	�u������YjX�0�d	S�5����  P�k��PW���9]�t	�u������Y3�_^[��U���S3�V�ES�uP�E�P�E�PSh �V�u�]��u聇����$��t5�v�d	��   �E��EP�E�P�d	�v�]�u���   ����ujX�X�E�W��   P�$�3�9]�Y��~�ES�4��d	���   ��F;u�YY|�W���u��u�u��u��u��u�l� ��_^[��U��EPhl��u�u�u�Ɇ������u]��u�u�� YY]�S�\$V�t$j h��V�t$ S蔆������t9�v�d	��   P賁��Y��Yu$�d	S��l  Yj ���PS�7'����jX�#�d	j �5����  P�i��PS���3�^[�U��V�uj h��V�u�u��������tj�E�5�P�v�u�+������tjX��u�m���Y3�^]�U���   �EPh��u�u�u赅������t!�� ���h   P�u�o� ��u�u��3��YjX�ád	f�e� V�� ���j�Q���  ���  P�u���3�^��U��V�uj h�V�u�u�?�������tj�E�5�P�v�u��*������tjX��u�u讀��YY^]�U��3�V�uPPPhH�V�u�u��������tj�E�5�P�v�u�q*������tjX�0�d	W�v��   �v���d	��   PW�u�u�x�����_^]�U��V�uj h��V�u�u�o�������tj�E�5�P�v�u��)������tjX��u�u蔃��YY^]�U��V�uj h��V�u�u��������tj�E�5�P�v�u�)������tjX��u�u����YY^]�U��EV�uPj j h̅V�u�u迃������t:�d	W�v��   �v���d	��   YY�uPW�����_u�u��1��YjX�3�^]�U���V�uW�}j h�W�uV�T�������t<j�E�5�P�wV��(������u �E�P�E�P�E�P�u�����uV�t1��YjX�~�d	���   �E�P����YP�d	V���  YPV��d	���   �E�P�����P�d	V���  YPV��d	���   �E�P�����P�d	V���  YPV���3�_^��U���SV�u3�WS�}SSSh$�V�uW�e����� ����   j�E�5�P�vW��'��������   �E��E�E�P�vW�������t'�v�d	���  ��Y��   �d	W��l  Y�]�E��E�E�P�vW��������t#�v�d	���  ��Yud�d	W��l  Y�]�E�]�P�vW�������t"�v�d	���  ��Yu*�d	W��l  Y3�S�u�u�u�����uW��/��YjX�3�_^[��U��Q�EV�uPj �e� hX�V�u�u�8�������tj�E��5�P�v�u��&������tjX��E���t�M�3�^��U��QV�uj �e� h|�V�u�u�݀������tj�E��5�P�v�u�g&������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h��V�u�u�j�������tj�E��5�P�v�u��%������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u��������tj�E��5�P�v�u�%������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hԆV�u�u�������tj�E��5�P�v�u�$%������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u�>������tj�E��5�P�v�u��$������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�V�u�u��~������tj�E��5�P�v�u�T$������tjX��E���t�M�H3�^��U��QV�uj �e� h@�V�u�u�n~������tj�E��5�P�v�u��#������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��h`��u�u�u�~������u]�Vjj����d	j �5����  P�u����P�u��� 3�^]�U��QV�uj �e� ht�V�u�u�}������tj�E��5�P�v�u�2#������tjX��u���Y3�^���t$��Y�U��Q�EV�uPj �e� h��V�u�u�?}������tj�E��5P�v�u��"������tjX��E���t�M�3�^��U��QV�uj �e� h��V�u�u��|������tj�E��5P�v�u�n"������tjX�"�E���d	Q���  ���   P�u���3�^��U���V�uW3�WWh��V�u�}��u�q|������t4j�E��5P�v�u��!������u�E�P�v�u�|������tjX��E�;�t
�x�u쥥��3�_^��U��QV�uW�}�e� j h�V�uW��{������tj�E��5P�vW�!������tjX�*�E��d	j ���5����  PW����PW���3�_^��U���V�uW3�WWh8�V�u�}��u�~{������t4j�E��5P�v�u�!������u�E�P�v�u�{������tjX��E�;�t
�x�u쥥��3�_^��U��QV�uW�}�e� j hh�V�uW�{������tj�E��5P�vW� ������tjX�*�E��d	j ���5����  PW��~��PW���3�_^��U��Q�EV�uPj �e� h��V�u�u�z������tj�E��5P�v�u� ������tjX��E���t�M�H$3�^��U��QV�uj �e� h��V�u�u�/z������tj�E��5P�v�u�������tjX�#�E��H$�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�V�u�u�y������tj�E��5P�v�u�E������tjX��E���t�M�H(3�^��U��QV�uj �e� h�V�u�u�_y������tj�E��5P�v�u��������tjX�#�E��H(�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hD�V�u�u��x������tj�E��5P�v�u�u������tjX��E���t�M�H,3�^��U��QV�uj �e� h��V�u�u�x������tj�E��5P�v�u�������tjX�#�E��H,�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h��V�u�u�x������tj�E��5P�v�u�������tjX��E���t�M�H03�^��U��QV�uj �e� h�V�u�u�w������tj�E��5P�v�u�I������tjX�#�E��H0�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h�V�u�u�Kw������tj�E��5P�v�u��������tjX��E���t�M�H43�^��U��QV�uj �e� h\�V�u�u��v������tj�E��5P�v�u�y������tjX�#�E��H4�d	Q���  ���   P�u���3�^��U��QV�uj j �e� h��V�u�u�}v������t<j�E��5P�v�u�������uj�E�5�P�v�u��������tjX��E���t
�Mf�	f�H83�^��U��QV�uW�}�e� j hȊV�uW��u������tj�E��5P�vW�������tjX�F�E�Sjf�@8�E�$��؍EjPS���d	j�5����  SW�y��PW���(3�[_^��U��Q�EV�uPj �e� h�V�u�u�gu������tj�E��5P�v�u��������tjX��E���tf�Mf�H:3�^��U��QV�uj �e� h4�V�u�u�	u������tj�E��5P�v�u�������tjX�'�E�f�H:�d	��Q���  ���   P�u���3�^��U��hd��u�u�u�t������u]�Vj<j����d	j �5���  P�u�x��P�u��� 3�^]�U��QV�uj �e� h|�V�u�u�?t������tj�E��5P�v�u��������tjX��u���Y3�^���t$��Y�U��Q�EV�uPj �e� h��V�u�u��s������tj�E��5�P�v�u�`������tjX��E���t�M�3�^��U��QV�uj �e� hЋV�u�u�{s������tj�E��5�P�v�u�������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h��V�u�u�s������tj�E��5�P�v�u�������tjX��E���t�M�H3�^��U��QV�uj �e� h,�V�u�u�r������tj�E��5�P�v�u�6������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hT�V�u�u�8r������tj�E��5�P�v�u��������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u��q������tj�E��5�P�v�u�f������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��QQV�uj j �e� �e� h��V�u�u�eq������t<j�E��5�P�v�u��������uj�E��5�P�v�u��������tjX��E���t�M���P�A�M��A3�^��U��QV�uW�}�e� j h�V�uW��p������tj�E��5�P�vW�j������tjX�*�E��d	j ���5����  PW�t��PW���3�_^��U��QQV�uj j �e� �e� h$�V�u�u�ap������t<j�E��5�P�v�u��������uj�E��5�P�v�u��������tjX��E���t�M���P�A�M��A3�^��U��QV�uW�}�e� j hd�V�uW��o������tj�E��5�P�vW�f������tjX�*�E��d	j ���5����  PW�s��PW���3�_^��U���V�uW3�WWh��V�u�}��u�`o������t4j�E��5�P�v�u��������u�E�P�v�u�o������tjX��E�;�t
�x�u쥥��3�_^��U��QV�uW�}�e� j h܍V�uW��n������tj�E��5�P�vW�s������tjX�*�E��d	j ���5����  PW�r��PW���3�_^��U��h��u�u�u�zn������u]�Vj,j����d	j �5����  P�u�er��P�u��� 3�^]�U��QV�uj �e� h,�V�u�u�n������tj�E��5�P�v�u�������tjX��u���Y3�^���t$��Y�U��Q�EV�uPj �e� hT�V�u�u�m������tj�E��5�P�v�u�<������tjX��E���t�M�3�^��U��QV�uj �e� ht�V�u�u�Wm������tj�E��5�P�v�u��������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h��V�u�u��l������tj�E��5�P�v�u�n������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u�l������tj�E��5�P�v�u�������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��h̎�u�u�u�!l������u]�Vjj����d	j �5����  P�u�p��P�u��� 3�^]�U��QV�uj �e� h��V�u�u��k������tj�E��5�P�v�u�L������tjX��u���Y3�^���t$��Y�h���t$�t$�t$�fk������u��t$�q��Y�U��V�uj h�V�u�u�8k������t�EP�d	�v�u���   ����tjX��u�u�q��YY^]�U���V�uj h8�V�u�u��j������t�EP�d	�v�u���   ����tjX�2�u���P�E�h�#P����E�jP�d	�u���  ��3�^��U����EV�uPj hX�V�u�u�cj������t�EP�d	�v�u���   ����tjX�5�u�u���P�E�h�#P����E�jP�d	�u���  ��3�^��U����EV�uPj h��V�u�u��i������t�EP�d	�v�u���   ����tjX�5�u�u���P�E�h�#P����E�jP�d	�u���  ��3�^��U���h���u�u�u�gi������u�����P�E�h�#P����E�jP�d	�u���  ��3���U���h���u�u�u�i������u�����P�E�h�#P����E�jP�d	�u���  ��3���U���hԏ�u�u�u�h������u�����P�E�h�#P����E�jP�d	�u���  ��3���U��V�uj h��V�u�u�jh������t�EP�d	�v�u���   ����tjX�'�u����d	P���  ���   P�u���3�^]�U���V�uW�}j h�W�uV��g������tG�EP�d	�wV���   ����u-�u�����u%������d	V��l  j WV�����jX�'P�E�h�#P����E�jP�d	V���  ��3�_^��U���h4��u�u�u�`g������u�����P�E�h�#P����E�jP�d	�u���  ��3���U���V�uW3�WWhL�V�u�u�g������u�q�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v���  9}YYu3�PS���P�E�h�#P����E�jP�d	�u���  ��3�[_^��U��� V�uW3�WWWWh|�V�u�u�df���� ��t>�E�P�d	�v�u���   ����u"�E��E�E�P�d	�v�u���   ����tjX�|�ES�]�P�v�d	�}���  9}YY�Eu�}�E�}P�d	�v���  9}YYu3�P�uS�u����P�E�h�#P����E�jP�d	�u���  ��3�[_^��U���   V�uW�}j hȐV�uW�we������t:�EP�d	�vW���   ����u �� ���h   P�u�����uW���YjX�(�d	f�e� �� ���j�Q���  ���  PW���3�_^��U���   V�uW�}j h �V�uW��d������t:�EP�d	�vW���   ����u �� ���h   P�u�����uW���YjX�(�d	f�e� �� ���j�Q���  ���  PW���3�_^��U��EV�uPj h0�V�u�u�Qd������t�EP�d	�v�u���   ����tjX�*�u�u����d	P���  ���   P�u���3�^]�U��QV�u�EWP�E�}Pj hT�V�uW��c������t:�EP�d	�vW���   ����u �E�P�u�u�u��j������uW����YjX�-�u��d	���   Y�d	PW���   ���  YPW���3�_^��U���SV�EWP�EP�E�P�u�E��]P�E�Pj j h��V�uS�(c����,��t[�EP�d	�vS���   ����uA�}�E�P�d	�vS���   ����u$�u�u�u��u��u��u�W�����uS�)��YjX�3�_^[��U��V�uW�}j hđV�uW�b������t�EP�d	�vW���   ����tjX�S�EP�u����d	P���  ���   PW��u�d	���   �d	��PW���   ���  YPW���3�_^]�U��Q�EV�uPj �e� h�V�u�u��a������tj�E��5 P�v�u�������tjX��E���t�M�3�^��U��QV�uj �e� h�V�u�u�a������tj�E��5 P�v�u�+������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hD�V�u�u�.a������tj�E��5 P�v�u�������tjX��E���t�M�H3�^��U��QV�uj �e� ht�V�u�u��`������tj�E��5 P�v�u�\������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��QV�uj j �e� h��V�u�u�``������t:j�E��5 P�v�u��������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� hԒV�u�u��_������tj�E��5 P�v�u�p������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U��QV�uj j �e� h �V�u�u�i_������t:j�E��5 P�v�u��������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� h8�V�u�u��^������tj�E��5 P�v�u�y������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U��QV�uj j �e� hd�V�u�u�r^������t:j�E��5 P�v�u��������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� h��V�u�u��]������tj�E��5 P�v�u�������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U��QV�uj j �e� h̓V�u�u�{]������t:j�E��5 P�v�u�������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� h�V�u�u�]������tj�E��5 P�v�u�������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U��QV�uj j �e� h<�V�u�u�\������t:j�E��5 P�v�u�������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� hx�V�u�u�
\������tj�E��5 P�v�u�������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U��QV�uj j �e� h��V�u�u�[������t:j�E��5 P�v�u�������u�EP�d	�v�u���   ����tjX��E���t�M�H3�^��U���V�uj �e� h��V�u�u�[������tj�E��5 P�v�u� ������tjX�.�E��p�E�h�#P����E�jP�d	�u���  ��3�^��U���V�uW3�WWh�V�u�}��u�Z������t4j�E��5 P�v�u� ������u�E�P�v�u�Z������tjX��E�;�t
�x �u쥥��3�_^��U��QV�uW�}�e� j h@�V�uW�Z������tj�E��5 P�vW��������tjX�*�E��d	j �� �5����  PW��]��PW���3�_^��U��hh��u�u�u�Y������u]�Vj0j����d	j �5 ���  P�u�]��P�u��� 3�^]�U��QV�uj �e� h��V�u�u�OY������tj�E��5 P�v�u���������tjX��u���Y3�^���t$��Y�U��QV�u�Ej P�e� h��V�u�u��X������t@j�E��5 P�v�u�p�������u"�E�� 0   �u��u�����u�u���YjX�3�^��U���  V�uW�}j hܕV�uW�rX������t<�EP�d	�vW���   ����u"������h  P�u�T_������uW���YjX�(�d	f�e� ������j�Q���  ���  PW���3�_^��U��V�uj j h�V�u�u��W������tE�EP�d	�v�u���   ����u)�d	W�v�}��   YPW�����_u�u����YjX�3�^]�U��EV�uPj h4�V�u�u�lW������t�EP�d	�v�u���   ����tjX�*�u�u����d	P���  ���   P�u���3�^]�U��EV�uPj hT�V�u�u��V������t�EP�d	�v�u���   ����tjX�*�u�u����d	P���  ���   P�u���3�^]�U��EV�uPj h|�V�u�u�V������t5�EP�d	�v�u���   ����u�u�u�����u�u���YjX�3�^]�U��EV�uPj h��V�u�u�V������t�EP�d	�v�u���   ����tjX�*�u�u����d	P���  ���   P�u���3�^]�U��V�uj hȖV�u�u�U������t2�EP�d	�v�u���   ����u�u�����u�u����YjX�3�^]�U��V�uj h��V�u�u�QU������t2�EP�d	�v�u���   ����u�u�����u�u�{��YjX�3�^]�U��V�uj h��V�u�u��T������t2�EP�d	�v�u���   ����u�u�����u�u���YjX�3�^]�U��V�uj h�V�u�u�T������t�EP�d	�v�u���   ����tjX�'�u����d	P���  ���   P�u���3�^]�U��V�uj h0�V�u�u�(T������t�EP�d	�v�u���   ����tjX�'�u�`��d	P���  ���   P�u���3�^]�U��V�uj hH�V�u�u�S������t�EP�d	�v�u���   ����tjX�'�u�d��d	P���  ���   P�u���3�^]�U��V�uj hh�V�u�u�NS������t�EP�d	�v�u���   ����tjX�'�u�h��d	P���  ���   P�u���3�^]�U��V�uj h��V�u�u��R������t�EP�d	�v�u���   ����tjX�'�u�l��d	P���  ���   P�u���3�^]�U��V�uj h��V�u�u�tR������t�EP�d	�v�u���   ����tjX�'�u�p��d	P���  ���   P�u���3�^]�U��SV�u�]Wj j h��V�uS�R������t7�EP�d	�vS���   ����u�}�EP�d	�vS���   ����tjX�&�uW�t��d	P���  ���   PS���3�_^[]�U���V�EWP�E�uP�EP�E�P�E��}Pj h�V�uW�`Q����(��tA�E�P�d	�vW���   ����u'�E�P�u�u�u�u��u��u��x���uW�{���YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QQ�EV�uP�EP�E�Pj h4�V�u�u�P���� ��t;�E�P�d	�v�u���   ����u�u�u�u��u��|���u�u�����YjX�3�^��U��QQ�EV�uP�EP�E�Pj hl�V�u�u�DP���� ��t;�E�P�d	�v�u���   ����u�u�u�u��u������u�u�e���YjX�3�^��U���V�uj h��V�u�u��O������t�EP�d	�v�u���   ����tjX�2�u���P�E�h�#P����E�jP�d	�u���  ��3�^��U���V�uW�}j h��V�uW�]O������t2�EP�d	�vW���   ����u�E�P�u�����uW����YjX��d	���  �E�P�P��PW���3�_^��U���V�uW�}j hИV�uW��N������t2�EP�d	�vW���   ����u�E�P�u�����uW����YjX��d	���  �E�P�O��PW���3�_^��U��QSV�u3��]WPPh�V�u�E�S�[N������tW�EP�d	�vS���   ����u=j�}�5�E�P�vS���������u�E�� <   �u�W�����uS�`���YjX�3�_^[��U��QSV�u3��]WPPh�V�u�E�S��M������tW�EP�d	�vS���   ����u=j�}�5��E�P�vS�<�������u�E�� ,   �u�W�����uS�����YjX�3�_^[��U��QSV�u3��]WPPh<�V�u�E�S�?M������tW�EP�d	�vS���   ����u=j�}�5��E�P�vS��������u�E�� ,   �u�W�����uS�D���YjX�3�_^[��U���V�uj hh�V�u�u�L������t�E�P�v�u�XN������tjX�5�u��u����P�E�h�#P����E�jP�d	�u���  ��3�^��U���SV�u�EW�]Pj j h��V�uS�6L������tl�EP�d	�vS���   ����uR�}�EP�d	�vS���   ����t43�9Et�E�P�vS�6L������u�E��uPW�����uS�&���YjX�3�_^[��U����EVP�EP�E��uP�E�P�E�Pj h��V�u�u�K����(��tA�E�P�d	�v�u���   ����u%�u�u�u��u��u��u������u�u����YjX�3�^��U��V�uj h��V�u�u�K������t2�EP�d	�v�u���   ����u�u�����u�u�B���YjX�3�^]�U��EV�uPj h�V�u�u�J������t�EP�d	�v�u���   ����tjX�*�u�u����d	P���  ���   P�u���3�^]�U��EP�EPh4��u�u�u�BJ������t�u�u�����u�u����YjX]�3�]�U��EPhX��u�u�u��I������u]�V�u����d	P���  ���   P�u���3�^]�ht��t$�t$�t$�I������u�V����d	P���  ���   P�t$���3�^�U��EPh���u�u�u�hI������t�u�����u�u����YjX]�3�]�U��V�uj h��V�u�u�'I������t2�EP�d	�v�u���   ����u�u�����u�u�Q���YjX�3�^]�U��V�uj hКV�u�u��H������t2�EP�d	�v�u���   ����u�u�����u�u�����YjX�3�^]�U��QQh��u�u�u�mH������t�E�P����u�u����YjX�ád	V���  �E�P�I��P�u���3�^��U��EP�EPh���u�u�u�H������t�u�u�p���u�u�K���YjX]�3�]�U��Q�EP�EP�E�Ph��u�u�u�G������u��V�u�u�u��l��d	P���  ���   P�u���3�^��U��V�uj hT�V�u�u�fG������t�EP�d	�v�u���   ����tjX�'�u�h��d	P���  ���   P�u���3�^]�U��EPhx��u�u�u��F������u]��u�u�_N��YY]�U��EPh���u�u�u��F������u]��u�u�eQ��YY]�U��QS�EV�uPj j h��V�u�u�F������t>�e �EP�d	�v���  �} YY��u3ۍE�P�d	�v�u���   ����tjX�+�u�u�S�p��d	P���  ���   P�u���3�^[��U��QQh��u�u�u��E������t�E�P�d���u�u�>���YjX�ád	V���  �E�P�7G��P�u���3�^��U��EP�EPh���u�u�u�E������t�u�u�`���u�u�����YjX]�3�]�U��Q�EP�EP�E�Ph��u�u�u�GE������u���u�u�u��u��- ����U��EPhL��u�u�u�E������u]��u�u�	/ YY]�U��EPhl��u�u�u��D������u]��u�u�dJ��YY]�U���<SV3�WSSS�E�SP�E��uP�E�P�E�P�E�P�}S�E�SPh��V�u�]�W�D����@����   �v�d	��   �v�Eܡd	��   �E��EP�d	�v$W���   ����uU�Ej�5��E��EP�v(W���������u3j�E�5�P�v,W��������uj�E�SP�v0W��������tjX�Q�u��u�u�u��u��u��u��u��u��u��u��u����P�E�h�#P����E�jP�d	W���  ��3�_^[��U��QQ�EV�uP�EP�E�Pj h�V�u�u�`C���� ��t;�E�P�d	�v�u���   ����u�u�u�u��u��\���u�u����YjX�3�^��W�|$hP��t$�t$W��B������t)�@���u$�d	W��l  Yj ���PW������jX_Ëd	Vj �5����  P��%��PW���3�^_�U��V�uj hp�V�u�u�B������t4j�E�5�P�v�u��������u�u����u�u����YjX�3�^]�U��S�EV�uP�E�]Pj h��V�uS�B������t?�v�d	��   Y�u�uP�D���u$�d	S��l  Yj ���PS������jX�#�d	j �5����  P� %��PS���3�^[]�U��QSVW�u3��EWP�E�]PWh��V�u�}�S�|A���� ��tY�v�d	��   �E�E�P�vS�z������u4�u��u�u�u��;�u1�d	S��l  YW���PS�������9}�t	�u��z��YjX�0�d	W�5����  P�;$��PS���9}�t	�u���y��Y3�_^[��U��V�uj h(�V�u�u�@������t4j�E�5�P�v�u�C�������u�u����u�u�����YjX�3�^]�hL��t$�t$�t$�]@������u��t$�N��Y�U��V�uj hh�V�u�u�/@������tj�E�5�P�v�u��������tjX��u�u�N��YY^]�U��V�uj h��V�u�u��?������tj�E�5�P�v�u�d�������tjX��u�u��M��YY^]�U��S�EV�uP�EP�E�]Pj h��V�uS�w?���� ��tB�v�d	��   Y�u�u�uP� ���u$�d	S��l  Yj ���PS������jX�#�d	j �5����  P�Z"��PS���3�^[]�U���SVW3��E�uWP�E�]PWWWh��V�u�}�S��>����(����   �v�d	��   �v�E�d	��   j�E��5��EP�vS�8�������uV�E� �E��E�P�vS�w������u:�u��u�u�u��u��u����;�u1�d	S��l  YW���PS������9}�t	�u��3w��YjX�0�d	W�5����  P�R!��PS���9}�t	�u�� w��Y3�_^[��U��EWP�EP�E�}PhP��u�uW��=������t2�u�u�u�����u$�d	W��l  Yj ���PW�p�����jX�%�d	Vj �5����  P� ��PW���3�^_]�U��V�uj h��V�u�u�E=������t4j�E�5�P�v�u���������u�u����u�u�m���YjX�3�^]�U��V�uj h��V�u�u��<������t4j�E�5�P�v�u�o�������u�u�<���u�u����YjX�3�^]�U��EW�}PhП�u�uW�<������t,�u�8���u$�d	W��l  Yj ���PW�3�����jX�%�d	Vj �5����  P�{��PW���3�^_]�U��V�uj h��V�u�u�<������t4j�E�5�P�v�u��������u�u�4���u�u�0���YjX�3�^]�h��t$�t$�t$�;������u�V�0��d	P���  ���   P�t$���3�^�U��QQh8��E�   �u�u�u�\;������t�E�P�,���u�u����YjX�ád	V�u����  ���   P�u���3�^��U��EPhT��u�u�u��:������u]�V�u�(��d	��P���  ���   P�u���3�^]�U��EPht��u�u�u�:������u]�V�u�$��d	��P���  ���   P�u���3�^]�U��EP�EPh���u�u�u�S:������u]�V�u�u� ��d	P���  ���   P�u���3�^]�U��V�uW3�Wh��V�u�u��9������t9�}~�EP�d	�v�u���   ����u�}W����u�u�"���YjX�3�_^]�h��t$�t$�t$�9������t����u�t$�����YjX�3��h���t$�t$�t$�d9������t�����u�t$����YjX�3��U��V�uW�}�Ej Ph�V�uW�!9������tKj�E�5�P�vW��������u/�u�u�����u$�d	W��l  Yj ���PW������jX�#�d	j �5����  P����PW���3�_^]�U��EW�}Ph<��u�uW�8������t,�u�<���u$�d	W��l  Yj ���PW�6�����jX�%�d	Vj �5����  P�~��PW���3�^_]�U���h`��u�u�u�8������u���8�P�E�h�#P����E�jP�d	�u���  ��3���h���t$�t$�t$�7������u��t$�F��Y�U���   �EPh���u�u�u�7������t"�� ���h   P�u�4���u�u�����YjX�ád	f�e� V�� ���j�Q���  ���  P�u���3�^��U���h��u�u�u�7������u���0�P�E�h�#P����E�jP�d	�u���  ��3���U��EPh���u�u�u�6������u]�V�u�,��d	P���  ���   P�u���3�^]�U��V�uj h(�V�u�u�m6������t#�v�d	��   YP�(���u�u����YjX��d	P���  ���   P�u���3�^]�U��EPhT��u�u�u�6������u]��u�u� YY]�U��V�uj h|�V�u�u��5������t�EP�d	�v�u���   ����tjX��u�u� YY^]�h���t$�t$�t$�5������u�V����ȡd	Q���  ���   P�t$���3�^�h���t$�t$�t$�75������u�V����ȡd	Q���  ���   P�t$���3�^�h��t$�t$�t$��4������u�V����d	P���  ���   P�t$���3�^�h���t$�t$�t$�4������u�V����d	P���  ���   P�t$���3�^�U��h��u�u�u�`4������t����ȅ�u�u����YjX]ád	VQ���  ���   P�u���3�^]�U��h@��u�u�u�4������t����ȅ�u�u�L���YjX]ád	VQ���  ���   P�u���3�^]�U����EVP3�P�MPQ�M��uQ�M�QP�E�P�E�P�E�Phd�V�u�u�3����8��u�U�d	SW�v��   �v ���d	��   �v$�ءd	��   �uPS�u�u��u�W�u��u��u��u�B����8_[^��U���3�V�MPQ�MQP�M�PQ�M�Q�M�QP�E�uP�E�P�E�Ph�V�u�u��2����@��u�l�d	SW�v��   �v ���d	��   �v$�ءd	��   �v0�E��d	��   P�u�u�u�S�u��u��u�W�u��u��u��u��B����D_[^��h���t$�t$�t$�T2������u�V����d	P���  ���   P�t$���3�^�U���   �EWP�E�}Ph���u�uW��1������t#�� ���h   P�u�u�����uW�6���YjX�A�d	VP���  ���   PW��d	f�e� �� ���j�Q���  ���  PW���3�^_��h���t$�t$�t$�s1������u�V����d	P���  ���   P�t$���3�^�h��t$�t$�t$�,1������u�V����d	P���  ���   P�t$���3�^�U���V�uj h�V�u�u��0������t,�v�d	��   Y�M�QP�@���tj P�u������jX��d	���  �E�P����P�u���3�^��U���V�uj h4�V�u�u�f0������t,�v�d	��   Y�M�QP�D���tj P�u������jX��d	���  �E�P�"���P�u���3�^��U���SV�uW�]3�WhX�V�uS��/������t;�E�P�d	�v��   YP�X�;�u�EP�E�P�H�;�tWPS������jX�J9}t�d	j��u���  Y��Y�u�0���d	Wh����   Y��Y�d	VS���  Y3�Y_^[��U���V�uj hx�V�u�u�6/������t,�v�d	��   Y�M�QP�X���tj P�u�������jX��d	���  �E�P�����P�u���3�^��U���$SV�u�EW3�P�ESPSSh��V�u�]��u�.����$��t`�E�P�d	�v��   �=X�YP��;�u3j�E�SP�v�u��������u'�E�P�d	�v��   YP��;�tSP�u�*�����jX��u�E�P�E��u�u�P�u�{K����_^[��U���SV�uW�]3�Wh�V�uS��-������t<�E�P�d	�v��   YP�X�;�u�EP�E�WP�D�;�tWPS������jX�4�d	W�5����   �u������P�d	S���  YPS���3�_^[��U���SV�uW�E3��]PWWh�V�u�}�S�T-������t@j�E�WP�vS���������u)�E�P�d	�v��   YP�X�;�tWPS�������jX��u�E�P�u�S��J����_^[��U��V�uW�}j h8�V�uW��,������t+�v�d	��   �MQP�2g������tj PW������jX�5�d	j �5����   �u������P�d	W���  YPW���3�_^]�U���SV�u�E�W3ۋ}PSSh`�V�u�]��]�W�6,��������   j�E��5�P�vW��������t6j�E��5$P�vW��������tj�E��5�P�vW�������K�d	W��l  �EP�EP�d	�vW���   ����t �E�M��EQ��   PSW�[�������tjX�B3�9]v �ES�4��d	���  YY�M���F;ur��E����u��u��u�u�W�I����_^[��U��QSV�uW�]3�Wh��V�}��uS�+������t:j�E�WP�vS��������u#9}�u#�d	S��l  YW���PS�������jX�#�d	W�5����  �u��
��PS���3�_^[��U��QV�uj �e� hĦV�u�u�*������tj�E��5�P�v�u��������tjX��u��u�I��YY^��U��Q�EV�uPj �e� h�V�u�u�3*������tj�E��5�P�v�u��������tjX��u�u��u�tO����^��U��Q�EV�uPj �e� h�V�u�u��)������tj�E��5�P�v�u�[�������tjX��u�u��u�R����^��U��QQSV�uW3�WWhH�V�u�}��}��u�l)������t`j�E��5�P�v�u���������uB�EP�EP�d	�v�u���   ����t!�E�M���Q��   PW�u�Ҹ������tjX�=3�;�v�EW�4��d	���  YY�M���F;�r�E��<��u�S�u��u�V����_^[��U��Q�EV�uPj �e� hx�V�u�u�(������tj�E��5�P�v�u�$�������tjX��u�u��u�W����^��U��Q�MV�uQ�M3�QPPh��V�E��u�u�3(���� ��tj�E��50P�v�u��������tjX�#�v�d	��   �u�uP�u��u�@`����^��U��V�u�EW�}Pj hЧV�uW��'������t-�v�d	��   Y�MQ�uP�@���tj PW�q�����jX�5�d	j �5����   �u�
����P�d	W���  YPW���3�_^]�U���V�EW�uP�EP�E�}Pj h��V�uW�$'���� ��t;�E�P�vW蜽������u'�E�P�E��u�u�uP�<���tj PW�������jX�5�d	j �5����   �u��
����P�d	W���  YPW���3�_^��U��QV�uW3�WWWh4�V�}��u�u�&������t\j�E��5�P�v�u��������u>�d	S�v��   �v�ءd	��   YYPS�u��8�;�[tWP�u������jX�3�_^��U����EVP�E�uP�E�P�E�Pj hl�V�u�u��%����$��t>�E�P�v�u�[�������u(�u�E��u�u��u�P�4���tj P�u������jX�3�^��U���V�EW�uP�EP�E�}P�e� j h��V�uW�f%���� ��t;�E�P�vW�޻������u'�E�P�E��u�u�uP�,���tj PW������jX�%�d	�u����  �����PW����u��X�3�_^��U��QV�uj �e� h��V�u�u��$������tj�E��5�P�v�u�`�������tjX��u��u�T��YY^��U��QV�uW�}�e� j h �V�uW�z$������t9j�E��5�P�vW��������u�EP�u��(���tj PW������jX�5�d	j �5t���   �u�e����P�d	W���  YPW���3�_^��U���(SV3�W�ES�}P�EP�E�PShP�W�u�u��#����$��tf�E�P�d	�w��   �5X�YP��;�u9�E�P�d	�w��   YP��;�u�E�P�E�P�E��u�u�u�P�$�;�tSP�u�D�����jX�8�d	S�5t���   �u������P�d	�u���  YP�u���3�_^[��U��QV�uj �e� h��V�u�u��"������tj�E��5tP�v�u��������tjX��u��u�\��YY^��U��Q�EV�uPj �e� hĩV�u�u�"������tj�E��5|P�v�u�+�������tjX��u�u��u��\����^��U��W�}h��u�uW�J"������t�EPj �L���tj PW�
�����jX�7�d	Vj �5l���   �u�Q����P�d	W���  YPW���3�^_]�U��V�uW�}j h�V�uW��!������t*�v�d	��   Y�MQP�P���tj PW�}�����jX�5�d	j �5����   �u������P�d	W���  YPW���3�_^]�U��QV�uj �e� h$�V�u�u�<!������t5j�E�j P�v�u���������u�u��T���tj P�u�������jX�3�^��U����E�Ph@��u�u�u�� ������t�E��E�PQQ�$� ���u�u����YjX�ád	V���  �E�P�6���P�u���3�^��U���V�uW�}j hh�V�uW�j ������t-�E�P�vW虲������u�E�P�E�P����uW����YjX�3�E��d	QQ�$���   YY�d	PW���   ���  YPW���3�_^��U���  SV�u�EWP�E��]j Pj h��V�uS������ ��tb�EP�d	�vS���   ����uHj�}�5��EP�vS�;�������u)������P�u�u�u�W�\������tj PS�F�����jX�#�d	������j�Q���  ���  PS���3�_^[��U���  V�u�EWP�E�}Pj hȪV�uW�������t=�EP�d	�vW���   ����u#������P�u�u�u�
[������uW�*���YjX�#�d	������j�Q���  ���  PW���3�_^��U��V�u�EW�}Pj h�V�uW�z������t:�EP�d	�vW���   ����u �EP�u�u�����tj PW������jX�+�} t#�d	�u���  �7���PW����u�0�3�_^]�U���  V�uW�}�e� j h<�V�uW��������t/�E�P�vW��������u������P�u������uW����YjX�#�d	������j�Q���  ���  PW���3�_^��U��QQV�uW3�W�E�WPWh`�V�u�u�W���� ��tn�EP�d	�v�u���   ����uR�d	S�v�]��   �E��EP�d	�v�}���  ��9}u3�P�u��u�S��Y������[u�u�E���YjX�3�_^��U��V�uj j h��V�u�u�������t`�EP�d	�v�u���   ����uD�d	W�v�}��   PW� �������_u(�u�d	��l  Yj ���P�u�6�����jX�%�d	j �5@���  P����P�u���3�^]�U��V�uj h��V�u�u�������tj�E�5@P�v�u��������tjX��u话��Y3�^]�h��t$�t$�t$�������u�V�ѝ���d	P���  ���   P�t$���3�^�h���t$�t$�t$�v������u�V�ם���d	P���  ���   P�t$���3�^�h��t$�t$�t$�0������u��t$�ڝ��Y�U��QQ�EV�uP�EP�E�Pj h(�V�u�u������ ��tj�E��5@P�v�u�~�������tjX��u�u�u��u��u�g�����^��U���dV�EWP�u�EP�E�}Pj j hd�V�uW�����$��tcj�E��5@P�vW��������uGj�E��5�P�vW��������u+�E�P�u�u�u�u��u�袞������tj PW�������jX��d	���  �E�P�;��PW���3�_^��U��EPh���u�u�u��������u]��u�u�W��YY]�hȬ�t$�t$�t$�������u��t$�bU��Y�U��� V3�W�E�VP�E�VP�}�E�VPVVVVVh�W�u�u��u�_����<���*  �w�d	��   �E��EP�d	�w�u���  ��9u�E�u�u��E�P�w�u�f���������   �E�uP�d	�w���  9uYY�E�u�u��E�uP�d	�w���  9uYY�E�u�u��E�uP�d	�w���  9uYY�Eu�u�ESP�d	�w$�u���  9uYY��u3ۍE�uP�d	�w,���  9uYYu3�P�u�S�u��u�u��u��u��u��u��u��Ւ����,;�[tVP�u������jX�3�_^��U��QV�u�EWP�E�j Pj h��V�u�u������ ��t,�v�d	��   ���EP�d	�v�u���   ����tjX��u�u�u�W�u豓����_^��U��EV�uPj j hȭV�u�u�������t?�d	S�v��   �v�ءd	��   �uPS���������[tj P�u�#�����jX�3�^]�V�t$j h �V�t$�t$�������u^��v�d	��   P�t$� �����^�U��QSV�u�Ej Pj j h(�V�u�u������ ��ta�v�d	��   �v�ءd	��   �E��EP�d	�v�u���   ����u$�u�u�u�S�`�������tj P�u�K�����jX�3�^[��U��Q�EV�uP3��M�PPQPhh�V�u�u�6����$��t_�EP�d	�v�u���   ����uC�d	SW�}�v��   �v�ءd	��   YY�uPS�u�W���_[��u�u�3���YjX�3�^��U���SVW�u3��E�WPW�E�WPWh��V�u�u�����(����   �E�P�d	�v�u���   ������   �E��v�E�d	��   �=���,$SP�E�׃���u!E��EP�v�u�@�������td�v�d	��   SP�E�׃���u1!E�v�d	��   P�u��u�u�u��u��u輙���� _^[�ÍEP�v�u�ܬ������u�3�9}�5�t�u��Y9}t�u��YjX��U��Q�EV�uPj �e� h��V�u�u�{������tj�E��5XP�v�u��������tjX��E���t�M�3�^��U��QV�uj �e� h4�V�u�u� ������tj�E��5XP�v�u誹������tjX�"�E���d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hd�V�u�u�������tj�E��5XP�v�u�7�������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u�Q������tj�E��5XP�v�u�۸������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hԯV�u�u��������tj�E��5XP�v�u�g�������tjX��E���t�M�H3�^��U��QV�uj �e� h�V�u�u�������tj�E��5XP�v�u��������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hP�V�u�u�������tj�E��5XP�v�u藷������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u�������tj�E��5XP�v�u�;�������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hȰV�u�u�=������tj�E��5XP�v�u�Ƕ������tjX��E���t�M�H3�^��U��QV�uj �e� h �V�u�u��������tj�E��5XP�v�u�k�������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� h\�V�u�u�m������tj�E��5XP�v�u���������tjX��E���t�M�H3�^��U��QV�uj �e� h��V�u�u�������tj�E��5XP�v�u蛵������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��Q�EV�uPj �e� hȱV�u�u�������tj�E��5XP�v�u�'�������tjX��E���t�M�H3�^��U��QV�uj �e� h �V�u�u�A������tj�E��5XP�v�u�˴������tjX�#�E��H�d	Q���  ���   P�u���3�^��U��h,��u�u�u��������u]�Vjj����d	j �5X���  P�u����P�u��� 3�^]�U��QV�uj �e� hH�V�u�u�{������tj�E��5XP�v�u��������tjX��u���Y3�^���t$��Y�U��QQSV�uW�E�3�PWWhl�V�}��u3��E�?  �u���������   �}~"�E�}P�d	�v���  9}YY�E�u�}��}~ �E�}P�d	�v���  9}YY��u3��u�S�u����;�u'�u�d	��l  YW���P�u�\�����jX�$�d	W�5����  P����P�u���3�_^[��U��SV�uW�}j h��V�uW�-������tCj�E�5�P�vW蹲������u'�u����؅�u���=  tSPW�ƭ����jX�"�d	j �5����  S����PW���3�_^[]�U��V�uj h�V�u�u�������t4j�E�5�P�v�u�&�������u�u�����u�u�ĺ��YjX�3�^]�U��SV�uW�]3�Wh0�V�uS�8������t<j�E�5�P�vS�ı������u �u�#  ��Y;�Wu���PS�ج����jX��   �d	W���   ���d	j	h$����   �M���   P�EWS��d	�6���   �M���   P�EWS��d	jh����   �M���   P�EWS��F��@����u���d	j�Q���   �U���  P�EWS��d	jh����   �M���   P�EWS��d	�v���   �M���   P�EWS��d	WS���  ��@V��Y3�_^[]�U��Q�E�V�5��Pj j �u�օ�u�����zt3��/W�u��$���Y��t�E�P�u�W�u�օ�u
W��Y3���_^��U��QV�u�E�W�}Pj j h\�V�u�E�� W�b
������t[j�E�5�P�vW��������u?�v�d	��   Y�u�P�u�|���u$�d	W��l  Yj ���PW������jX�#�d	j �5����  P�,���PW���3�_^��U���(SVW3�WWWWW�E�WP�E�uP�E�P�E�P�]WWWh��V�}��uS�	����D���T  j�E��5�P�vS���������4  �v�d	��   �v�Eܡd	��   �v �E�d	��   �v$�E��d	��   j�E��5d�E�P�v(S軮����$����   �v,�d	��   �$,$P�E���Y��Yu�}��EP�v,S����������   �E�}P�d	�v0���  9}YY��u3ۍE�}P�d	�v4���  9}YYu3�PS�u�u��u��u��u��u��u��u��u��u��u��x�;�u6�u�d	��l  YW���P�u������9}t
�u��YjX�3�d	W�5����  P�V���P�u���9}t
�u��Y3�_^[��U��V�uj h��V�u�u��������t4j�E�5�P�v�u�[�������u�u�t���u�u�����YjX�3�^]�U��QQSV�uW3�WWh��V�u�}��u�h��������   j�E��5�P�v�u����������   �EP�EP�d	�v�u���   ����tf�E�M���Q��   PW�u�Ɩ������uE3�;�v�EW�4��d	���  YY�M���F;�r�E��<��u�S�u��p���u�u����Y9}�t
�u���YjX�9}�t
�u���Y3�_^[��U��QV�u3�W�M�}PQPhдV�E��uW�c������tRj�E�5�P�vW��������u6j�E��5\P�vW�ӫ������u�u��u�u�l���uW�m���YjX�3�_^��U��QV�u3�W�}PPh�V�E��uW��������tOj�E�5�P�vW�h�������u3j�E��5\P�vW�L�������u�u��u�h���uW����YjX�3�_^��U��SV�uW�]3�WhȵV�uS�\��������  j�E�5�P�vS����������  �u��  ��Y;�Wu���PS��������  �d	W���   ���d	jh�J���   �M���   P�EWS��d	�6���   �M���   P�EWS��d	jh�����   �M���   P�EWS��d	��@�v���   �M���   P�EWS��d	jh�����   �M���   P�EWS��d	�v���   �M���   P�EWS��d	jh�����   �M���   P�EWS��d	��H�v���   �M���   P�EWS��d	jh�����   �M���   P�EWS��F��$����u���d	j�Q���   �U���  P�EWS��d	jh|����   �M���   P�EWS��F��(����u���d	j�Q���   �U���  P�EWS��d	jhh����   �M���   P�EWS��F��(����u���d	j�Q���   �U���  P�EWS��d	jhX����   �M���   P�EWS��F ��(����u���d	j�Q���   �U���  P�EWS��d	j�hH����   �M���   P�EWS��vS蛛����0��uW�]���YjX�'P�d	WS���   �d	WS���  V����3�_^[]�U��Q�E�V�5d�Pj j �u�օ�u�����zt3��/W�u��$���Y��t�E�P�u�W�u�օ�u
W��Y3���_^��U��SV�u�]Wj j h�V�uS�������tMj�E�5�P�vS�I�������u1�v�d	��   P�u�����������uP���PS�L�����jX�$�d	j�W���  ���  PS�W����3�_^[]�U��SV�u�]Wj j h�V�uS�������tMj�E�5�P�vS触������u1�v�d	��   P�u�Љ��������uP���PS誡����jX�$�d	j�W���  ���  PS�W����3�_^[]�U��� SVW3�WWWWWW�E�W�uP�E�}�P�E�PWhL�V�u�u�b ����<���X  j�E��5�P�v�u���������6  �v�d	��   �=���,$SP�E��׃���u!E��v�d	��   SP�E��׃���u!E�j�E��5dP�v�u�}���������   �v �d	��   SP�E�׃���u!E��EP�v �u謗��������   �v$�d	��   SP�E��׃���u!E��v(�d	��   SP�E�׃���u!E�v,�d	��   ��SV�׃���u3�V�u�u��u�u��u��u��u��u��u��u��`���u�u�d���Y3�9}t
�u��YjX��} t
�u��Y3�_^[��U��Q�EV�uP�EPj h�V�u�u��������tj�E��5�P�v�u�:�������tjX��u�u�u��u�   ��^��U����E�W3�Ph }  W�u�}���������tjX��   �d	SVWW���   Y�E�Y�E��}�P�E�P�E�Ph }  �u��u�u�u�\�;ǉE�u��������   u;3�9}�v-�d	���   �E��P�\   P�u��u���C��$;]�r�3�9}�u��u�蟫��WV�u脞����j_��u��d	�u���  YY�u���Y^��[_�ád	SUV3�W�|$SS���   ��d	jhP����   ���   PVS�U ���;Ë�u���d	j�Q���   ���  PVS�U �d	jhX����   ���   PVS�U �O��(;�u���d	j�Q���   ���  PVS�U �d	jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	jh�J���   ���   ��@PVS�U �d	�w���   ���   PVS�U �d	jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	��@jh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	���   jh�J���   PVS�U �d	�w���   ���   PVS�U �d	��Hjh�J���   ���   PVS�U �d	�w���   ���   PVS�U �d	j
h�J���   ���   PVS�U �d	�w ���   ���   PVS�U ��H��_^][�U��QQV�Ej �uP�EP�E�Pj h`�V�u�u�
�����$��tj�E��5�P�v�u蔠������tjX�>�v�d	��   ���$,$V���Y��Yu3�V�u�u�u��u��u�   ��^��U���W3�9}t$�d	Wh���u���  WjW�u�R�������E��}�Ph }  W�u��������tjX��   �d	SVWW���   Y�E�Y�u�E�}P�EP�E�Ph }  �u��u�uW�u�X�;ǉE�u��������   u;3�9}v-�d	���   �E��P�\   P�u��u���C��,;]r�3�9}�u��u�袧��WV�u臚����j_��u��d	�u���  YY�u���Y^��[_�ád	SUV3�WUU���   ��d	jhP����   ���   PVU��|$0���;ŋ�u���d	j�Q���   ���  PVU��d	jhX����   ���   PVU��G��(;ŋ�u���d	j�Q���   ���  PVU���VW�)������_^][�U��EV�uPj hܷV�u�u��������tj�E�5�P�v�u�,�������tjX��u�u�u�   ��^]�U���V�M�W��  Q3�PW�u�E��
�������uc�E�5T�P�E�P�u��u��u�u�օ�uH���=�   u;�u����E�P�u�W�u轇������u�E�P�E�P�u��u��u�u�jX�e�d	SWW���   Y3�9}�Y�Ev+�d	���   �E��P�-���P�u�u���C��$;]�r��u�d	�u���  �u�����3�[_^��U��V�uj h�V�u�u�Q�������t4j�E�5�P�v�u�ۜ������u�u�P���u�u�y���YjX�3�^]�U��EV�uPj h<�V�u�u���������tj�E�5�P�v�u�w�������tjX��u�u�u�|����^]�U��QQS�EV�uP�E�3�PShh�V�]��u�u��������t$�E�]P�E�P�d	�v�u���   ����ujX�R�E�W��   P�$�3�9]�Y��~�ES�4��d	���   ��F;u�YY|���u�u�W�u��u��  ��_^[��U����EP�EP�E�P�E�P�E�P�E�Ph���u�u�u�������(��t'�u�u�u��u��u��u����  ����u�u����YjX��3���U��EPh��u�u�u�{�������u]��u�u��  YY]�U��V�uW3�WWh0�V�u�u�E�������t_�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS�L�;�[u'�u�d	��l  YW���P�u�����jX�$�d	W�5����  P����P�u���3�_^]�U��� SV3�WSS�E�S�}P�E�uP�E�PShd�W�u�]�V�~�����,����   j�E��5�P�wV����������   �EP�wV�u���������   �E�P�E�P�d	�wV���   ������   �E��M��EQ��   PSV�Ń������um3�9]v �E�S�4��d	���  YY�M���F;ur��E����E�P�d	�w���   P�u��u��u�u�u��u��u��u��|����,��u*�u����Y9]�5�t�u��Y9]�t�u���YjX�9]�5�t�u��Y9]�t�u���Y3�_^[��U��V�uj hȹV�u�u�,�������t4j�E�5�P�v�u趘������u�u�H���u�u�T���YjX�3�^]�U��V�uW3�WWh��V�u�u���������t_�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS�D�;�[u'�u�d	��l  YW���P�u�F�����jX�$�d	W�5����  P����P�u���3�_^]�U��V�uW3�WWh(�V�u�u��������t_�ESP�d	�v�}���  9}YY��u3��v�d	��   YPS�@�;�[u'�u�d	��l  YW���P�u蕒����jX�$�d	W�5����  P�����P�u���3�_^]�U��Q�EV�uP�EPj h`�V�u�u�a�������tj�E��5�P�v�u��������tjX��u�u�u��u�z����^��U��V�uj h��V�u�u��������t4j�E�5�P�v�u菖������u�u�<���u�u�-���YjX�3�^]�U��V�uj j h��V�u�u��������tDj�E�5�P�v�u�-�������u&�v�d	��   YP�u�8���u�u軞��YjX�3�^]�U��V�uj j h�V�u�u�1�������tTj�E�5�P�v�u軕������u6!E�EP�d	�v���  �} YYu3�P�u�4���u�u�9���YjX�3�^]�U��V�uW�}j h�V�uW��������t4j�E�5�P�vW�;�������u�EP�u�0���uW�ם��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U��V�uW�}j hH�V�uW�!�������t4j�E�5�P�vW譔������u�EP�u�,���uW�I���YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U��V�uW�}j ht�V�uW��������t5j�E�5�P�vW��������u�EP�u�w��Y��YuW躜��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�h���t$�t$�t$�
�������t�����u�t$�R���YjX�3��U��QSV�E�uW3�P�EWP�]�EPh��V�}��uS������ ��tI�E�P�vS��&������u5W�u�u��u�u���;�u1�d	S��l  YW���PS�L�����9}�t	�u��i&��YjX�0�d	W�5����  P����PS���9}�t	�u��6&��Y3�_^[��U��QQV�uW�Ej P�E�}P�e� j h�V�uW������� ��tMj�E�j P�vW脒������u5�EP�vW�^   ����u!�E�P�u�u�u�u������uW����YjX�-�u��d	���   Y�d	PW���   ���  YPW���3�_^��U��QQ�EV�uP�EP�d	�uV���   ������   �}ub�E�P�E�0�d	V���   ����uF�E�P�E�p�d	V���   ����u)�U���|"��  ;��M���|;��Ef�f�H3����t�d	j hl�V���  ��jX^��U��QSV�uW3��EW�]PWWh̼V�}��uS������ ��t[j�E�WP�vS��������uD�v�d	��   f�8�EP�vS���������u�EP�u�uW�u������uS菙��YjX�-�u�d	���   Y�d	PS���   ���  YPS���3�_^[��U��QV�uj �e� h �V�u�u���������t0j�E�j P�v�u�c�������u�u������u�u����YjX�3�^��hP��t$�t$�t$�}�������t�����u�t$�Ř��YjX�3��U��EP�EPhd��u�u�u�<�������t�u�u�����u�u����YjX]�3�]�h���t$�t$�t$���������u�V����d	P���  ���   P�t$���3�^�U��QV�uW�}�e� j h��V�uW��������t0j�E�j P�vW�:�������u�EP�u������uW�֗��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��h��t$�t$�t$�&�������u�V����d	P���  ���   P�t$���3�^�U���V�uW�}�e� j h �V�uW���������t0j�E�j P�vW�b�������u�E�P�u������uW�����YjX��d	���  �E�PW�   PW���3�_^��U���V�uW�}VW�U   �E�FPW�H   �E��FP�d	���   �E�F
PW�m   ���E�VW�   �E��E�P�d	j���   ��,_^��U��QQV�u�P�d	���   �E��FP�d	���   �E��E�P�d	j���   ��^��U���V�u�P�d	���   �E��FP�d	���   �E��FP�d	���   �E��FP�d	���   �E��E�P�d	j���   ��^��U���  h4��u�u�u�<�������t������h  P�����u�u�y���YjX�ád	f�e� V������j�Q���  ���  P�u���3�^��U���V�uh`��u�uV���������t,�����u'W������d	V��l  j WV�x�����_jX�'P�E�h�#P����E�jP�d	V���  ��3�^��U��QSV�uW�]3�Wh|�V�}��uS�B�������t?j�E�WP�vS�Ӌ������u(�u����f;ǉEuf9}uW���PS�߆����jX��d	���  �EPS�����PS���3�_^[��U��QV�uW�}�e� j h��V�uW��������t0j�E�j P�vW�B�������u�EP�u������uW�ޓ��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��W�}h��u�uW�,�������t�EP�����uW�s���YjX�/�d	V�u���   Y�d	PW���   ���  YPW���3�^_]�U��EW�}Ph��u�uW��������t,�u��p����Yu$�d	W��l  Yj ���PW�l�����jX�%�d	Vj �5����  P����PW���3�^_]�U��EPh4��u�u�u�A�������t�u�����u�u臒��YjX]�3�]�U��QS�]V�uj �e� j hX�V�uS���������tCj�E�j P�vS臉������u+�EP�vS�a�������u�u�u������uS����YjX�3�^[��U��Q�EV�uPj �e� h��V�u�u�~�������t3j�E�j P�v�u��������u�u�u������u�u觑��YjX�3�^��U��EPh̿�u�u�u��������t�u�����u�u�e���YjX]�3�]�U��QS�]V�uj �e� j h��V�uS���������tCj�E�j P�vS�e�������u+�EP�vS�?�������u�u�u������uS����YjX�3�^[��U��Q�EV�uPj �e� h0�V�u�u�\�������t3j�E�j P�v�u��������u�u�u������u�u腐��YjX�3�^��V�t$j hp�V�t$�t$���������t$�v�d	��   YP� ���u�t$�5���YjX^�3�^�U���SV�u�E�]j P�e� j h��V�uS��������tGj�E�j P�vS�/�������u/�E�P�vS�-   ����u�E�P�u�u�����uS贏��YjX�3�^[��U����EV�uP�EP�d	�uV���   ����t�}t�d	j h��V���  ��jX^�ÍE�P�E�0�d	V���   ����uލE�P�E�p�d	V���   ����u��E�P�E�p�d	V���   ����u��E�P�E�p�d	V���   ����u��Ef�M�f�f�M�f�Hf�M�f�Hf�M�f�H3��a���U��QV�u�Ej P�e� h$�V�u�u�;�������t3j�E�j P�v�u�Ʌ������u�u��u����u�u�d���YjX�3�^��U��QS�EV�u�]Pj �e� j hP�V�uS���������tDj�E�j P�vS�_�������u,�v�d	��   �MQ�uP�u��k������uS����YjX�-�u�d	���   Y�d	PS���   ���  YPS���3�^[��U��QSV�uW3��]WWWh��V�}��uS�)�������t^j�E�WP�vS躄������uG�EP�d	�v���  ���EP�vS��������u�EP�u�uW�u�����uS�'���YjX�-�u�d	���   Y�d	PS���   ���  YPS���3�_^[��U��QV�uj �e� h��V�u�u�m�������t0j�E�j P�v�u���������u�u�����u�u虌��YjX�3�^��U��Q�EV�uPj �e� h�V�u�u��������tj�E�j P�v�u薃������tjX��u�u��u�	j����^��U��EP�EPh<��u�u�u��������u]��u�u�u�!�  ��]�ht��t$�t$�t$�|�������u��t$���  Y�U��W�}h���u�uW�P�������t�EP�mr����Ytj PW�~����jX�/�d	V�u���   Y�d	PW���   ���  YPW���3�^_]�V�t$j h��V�t$�t$���������t)�v�d	��   P�r��Y��Ytj P�t$�}����jX^�3�^�U��QV�EW�}P�E�3�PVVh��W�u�u�}����� ��tz�ESP�d	�w�u���  9uYY��u3ۍE�uP�d	�w���  9uYYu3��u�u�PS�Li������;�[uV���P�u��|�����W�u�$u��Y;�YujX�P�d	�u���  W����3�_^��U��QQV�E��uWP�E�3�PWWWh4�V�u�u������$��u�h�E�}P�d	�v���  9}YY�Eu�}�ESP�d	�v�}���  9}YY��u3��v�d	��   �u��u�PS�u�u��h����[_^��U���V�E�W�uP3��E�WPWWWWh��V�u�u������,��u�   �E�}P�d	�v���  9}YY�E�u�}��v�d	��   �E��EP�d	�v�}���  ��9}�Eu�}�ESP�d	�v�}���  9}YY��u3��v�d	��   �u�P�u�S�u�u��u��u�i����$[_^��U��EV�uPj h�V�u�u�=�������u��v�d	��   �uP�u�Sj����^]�U��VhP��u�u�u���������t�n����V�u�s��Y��YujX�P�d	�u���  Y��YtV��Y3�^]�U��EPhl��u�u�u��������t�u��n����Ytj P�u�^z����jX]�3�]�U��SV�uW�E�]3�PWh��V�uS�O�������t=�E�}P�d	�v���  9}YYu3��MQ�uP�n����;�tWPS��y����jX�4�d	W�5����   �u�7�����P�d	S���  YPS���3�_^[]�U��V�uj h��V�u�u��������t9j�E�5�P�v�u�<~������u�u�6n����Ytj P�u�Uy����jX�3�^]�U��V�u�EW�}Pj j h��V�uW�E�������tMj�E�5�P�vW��}������u1�v�d	��   �MQ�uP�u��m������tj PW��x����jX�5�d	j �5����   �u������P�d	W���  YPW���3�_^]�U��V�uj h4�V�u�u��������t8j�E�5�P�v�u�"}������u�u�� ��tj P�u�<x����jX�3�^]�U��V�uj hX�V�u�u�4�������t8j�E�5�P�v�u�|������u�u�v ��tj P�u��w����jX�3�^]�U��EV�uPj h|�V�u�u���������tj�E�5�P�v�u�V|������tjX��u�u�u�Vi����^]�V�t$j h��V�t$�t$�s�������t)�v�d	��   P�l��Y��Ytj P�t$�&w����jX^�3�^�U��EV�uPj h��V�u�u��������u�/�e �EP�d	�v���  �} YYu3��uP�u�b����^]�U��V�uW�}j h�V�uW���������tF�EP�d	�vW���   ����u,�u�$���u$�d	W��l  Yj ���PW�Yv����jX�#�d	j �5���  P袸��PW���3�_^]�U��V�uW�}j h0�V�uW�-�������tF�EP�d	�vW���   ����u,�u� ���u$�d	W��l  Yj ���PW��u����jX�#�d	j �5���  P����PW���3�_^]�U��SV�u�]Wj j hL�V�uS��������t9�EP�d	�vS���   ����uj�}�5�EP�vS�z������tjX�&�uW���d	P���  ���   PS���3�_^[]�U��QV�uW�E�}j P�e� j hl�V�uW���������t3j�E�5P�vW�y������ujP�E�P�vW�qy������tjX�+�u��u�u����d	P���  ���   PW���3�_^��U��EV�uPj h��V�u�u�o�������tj�E�5P�v�u��x������tjX�*�u�u����d	P���  ���   P�u���3�^]�U���L  V�E�W�}P�E3�PVh��W�u��uǅ����H  �u���������t?�E�uP�d	�w���  9uYYu3��u�������Q�uP����u�u�����YjX�"�d	���  ������P��h��P�u���3�_^��U��V�u�EW�}Pj h �V�uW�N�������tI�EP�d	�vW���   ����u/�u�u����u$�d	W��l  Yj ���PW��r����jX�#�d	j �5T���  P�*���PW���3�_^]�U���V�u�EW�}Pj h,�V�uW��������tD�E�P�vW���������u0�u�E�P����u$�d	W��l  Yj ���PW�Fr����jX�#�d	j �5T���  P菴��PW���3�_^��U��QQV�u�EW�}Pj hT�V�uW��������tF�E�P�vW��������u2�u�u��u�����u$�d	W��l  Yj ���PW�q����jX�#�d	j �5T���  P����PW���3�_^��U���hV�uW�}j h|�V�E�h   �uW�t�������t4j�E�5TP�vW� v������u�E�P�u����uW�~��YjX��d	���  �E�P�g��PW���3�_^��U���V�uW�}j j h��V�uW���������tRj�E�5P�vW�}u������u6�EP�d	�vW���   ����t3�9Et�E�P�vW���������tjX��E�P�uW�Vg����_^��U��QSV�u�Ej Pj �e� h��V�u�u�X�������t1�v�d	��   �}Y��~j�E�j P�v�u��t������tjX�+�u��uS����d	P���  ���   P�u���3�^[��U��QSV�u�Ej Pj �e� h�V�u�u���������t1�v�d	��   �}Y��~j�E�j P�v�u�<t������tjX�+�u��uS�|��d	P���  ���   P�u���3�^[��U��3�V�uPPP�EPhT�V�u�u�7����� ��tN�d	SW�v��   �v���d	��   �v�ءd	��   ��PSW�u�x�_[��u�u�E|��YjX�3�^]�U��Q�EV�uPj �e� h��V�u�u��������tj�E��5�P�v�u�>s������tjX��u�u��u�cn����^��U���$V�u�MW3�Q�}PPPh��V�u�E�W�L����� ��t`j�E��5�P�vW��r������tj�E��5�P�vW�r������u(�E�P�vW�C_������u�E�P�vW�/_������tjX��u�E�P�E�P�u�W��n����_^��U��QV�uW�}�e� j h �V�uW��������t8j�E��5�P�vW�/r������t!j�E��5�P�vW�r������tjX��u�W�}o��YY_^��U��EPhT��u�u�u�5�������u]��u�u�o��YY]�U��EW�}Ph���u�uW� �������t�EP�u����uW�Dz��YjX�/�d	V�u���   Y�d	PW���   ���  YPW���3�^_]�U��V�uj h��V�u�u��������tj�E�5�P�v�u�q������tjX��u��p��Y3�^]�U��Q�EV�uP�EPj h��V�u�u�3�������t9j�E��5�P�v�u�p������u�u�u�u�� ��u�u�Vy��YjX�3�^��U��V�uj h�V�u�u���������tj�E�5�P�v�u�Xp������tjX��u�u�Bp��YY^]�U��V�uj h(�V�u�u�y�������tj�E�5�P�v�u�p������tjX��u�u�Rr��YY^]�U��Q�EV�uP�EPj hL�V�u�u��������t9j�E��5�P�v�u�o������u�u�u�u�� ��u�u�>x��YjX�3�^��S�\$V�t$j h��V�t$ S��������t8�v�d	��   YP� ��u$�d	S��l  Yj ���PS�Xj����jX�#�d	j �5����  P衬��PS���3�^[�U��Q�EV�uP�EPj h��V�u�u�&�������tj�E��5�P�v�u�n������tjX��u�u�u��u�r����^��U���V�EWP�E�uP�EP�E�P3��M�PQ�M�}PQPh��V�uW������4��tij�E��5�P�vW�6n������uM�d	S�v��   �v�ءd	��   YY�u�M�Q�u�u�u�P�u�S�u��u��m  ��[uW�v��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U���SV�E�W�}3�PVVVVhX�W�u�u�������$��t|�E�uP�d	�w���  9uYY�E�u�u��E�uP�d	�w���  9uYY�Eu�u�EP�d	�w���  9uYYt$�M�]�QP�X�;�tVP�u�<h����jX�63ۍE�uP�d	�w���  9uYYu3��u�PS�u�u��u�q����_^[��U��Q�EP�EP�E�Ph���u�u�u���������t�u�u�u��S�  ��u�u�6u��YjX��3���U��V�uW�}j h��V�uW��������t4j�E�5�P�vW�9l������u�EP�u����uW��t��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U��EPh��u�u�u�!�������u]��u�u�F�  YY]�U��V�uj h@�V�u�u���������t�EP�d	�v�u���   ����tjX��u�u��  YY^]�U���$hd��u�u�u��������t�E�P�i�  ��u�u��s��YjX���E�VP�d	���   �E��E�P�d	���   �E��E�P�d	���   �E��E�P�d	���   �u��E�d	���   �u��E�d	���   �E�d	�M�Qj���  ���   P�u���(3�^��U��EPh���u�u�u���������u]�V�u� ��d	P���  ���   P�u���3�^]�U��� SV3�W�}VVVVh��W�u��u�u�p����� ����   �EP�d	�w���  9uYYt�M��M�M�QP�X�;�t	V�   �u�E�P�d	�w�u���   ����u{�]��EP�d	�w�u���  9uYY�E�u�u��}~j�E�VP�w�u�}i������u7�u��u�S�u�������u'�u�d	��l  YV���P�u�zd����jX�$�d	V�5���  P�Ħ��P�u���3�_^[��U��V�uj h�V�u�u�N�������t4j�E�5P�v�u��h������u�u�����u�u�vq��YjX�3�^]�U���,SV3�W�}VV�E�VPVVVhH�W�u��u�u�������,���  �EP�d	�w���  9uYYt�MԉM��M�QP�X�;�t	V��   �u��E�uP�d	�w���  9uYY�E�u�u�E�P�d	�w�u���   ������   j�E��5�]�P�w�u��g��������   �E�uP�d	�w���  9uYY�E�u�u��}~j�E�VP�w�u�g������u@�u��u��u��u�S�u��u�������u'�u�d	��l  YV���P�u�b����jX�$�d	V�5���  P�ߤ��P�u���3�_^[��U��QV�u3�W�M�}PQPh��V�E��uW�]�������tRj�E�5P�vW��f������u6j�E��5P�vW��f������u�u��u�u�����uW�go��YjX�3�_^��U���SV�u�MW3�Q�MP�}QPPh�V�E��u�E�W�������$j[;���   S�E�5P�vW�Nf������uwS�E��5P�vW�3f������u\S�E��5�P�vW�f������uA�E�P�E��u�u�P�u�u��u����؅�u#�����zt��ujWXj PW�a����jX�o�d	S���  ���   PW��u��d	���   �d	��PW���   ���  YPW��u�d	���   �d	��PW���   ���  YPW���3�_^[��U���SV�uW3��EWP�]WWWh��V�u�}��}�S耿����$����   j�E�5P�vS�e��������   j�E��5P�vS��d������uh�E�P�d	�v��   YP�X�;�tWPS��_�����=j�E��5tP�vS�d������u!�u��E��uP�u��u�����uS�4m��YjX�3�_^[��U���SV�u3�W�ESP�}SSSh��V�u�]�]��]�W蓾����$����   j�E�5P�vW�d��������   j�E��5tP�vW��c������uuj�E��5�P�vW��c������uYj�E��5P�vW��c������u=�u��E�P�u�u��u��u���;ÉEu"�����zt;�ujWXSPW�^����jX�G�d	�u���  ���   PW��u�d	���   �d	��PW���   ���  YPW���3�_^[��U���  SV�uW3��]WWWWh��V�u�}��}�}�S�U����� ����   �E�P�d	�v��   YP�X�;�tWPS�^�����   �}~j�E��5�P�vS�b������u_�}~�v�d	��   Y�E�}~j�E�WP�vS�tb������u*�u��������u��u�h   P�E�P�����uS��j��YjX�'�d	������j�Qf�}⍰�  ���  PS���3�_^[��U���SV�uW3��EWW�]PWWh��V�u�}�}��}�S�8�����$����   �v�d	��   j�E�5��E�P�vS�a������uY�}~�v�d	��   Y�E��}~j�E�WP�vS�za������u$�u��E��u�P�u�u��u�����uS�
j��YjX�-�u�d	���   Y�d	PS���   ���  YPS���3�_^[��U���  SV�uW3��]WWWht�V�}��u�}�S�C���������   j�E�5P�vS��`������udj�E��5P�vS�`������uH�}~j�E��5�P�vS�`������u&�u�������h   P�u��u�����uS�i��YjX�'�d	������j�Qf�}����  ���  PS���3�_^[��U���SVW3��EW�uP�EWP�E�]WPWh��V�u�}�}��}�S�M�����,����   j�E��5�P�vS��_������utj�E�WP�vS�_������u]j�E�WP�vS�_������uFj�E��5P�vS�_������u*�u��E�P�u�u��u�u��u�u��$���uS�h��YjX�-�u�d	���   Y�d	PS���   ���  YPS���3�_^[��U���V�u�Ej P�E�PhT�V�u�u�U�������t:�EP�d	�v���  �} YYt%�M�u�QP�X���tj P�u��Y����jX�3�V�u�u��u���  ��^��U��V�uj h��V�u�u�ݸ������t�EP�d	�v�u���   ����tjX��u�u��  YY^]�h���t$�t$�t$莸������u��t$�'r��Y�h���t$�t$�t$�d�������u��t$�s��Y�U��V�uW�}j h��V�uW�4�������t)�v�d	��   Y�MQP�i�  ��tj PW��X����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�h$��t$�t$�t$跷������u��t$��t��Y�U��W�}h@��u�uW苷������t�EP���  ��tj PW�NX����jX�/�d	V�u���   Y�d	PW���   ���  YPW���3�^_]�U��EPh`��u�u�u��������u]��u�u�]s��YY]�U��EPh���u�u�u��������u]��u�u��t��YY]�U��Q�E��e� Ph���u�u�u讶������u���u��u�u��YY��U��Q�E��e� Ph���u�u�u�v�������u���u��u��t��YY��U��Q�E��e� Ph��u�u�u�>�������u���u��u��t��YY��U��Q�E��e� Ph8��u�u�u��������u���u��u�t��YY��U��EPhl��u�u�u�ӵ������t�u�%�  ��tj P�u�V����jX]�3�]�U��EP�EPh���u�u�u芵������u]��u�u�u��v����]�U��EP�EPh���u�u�u�O�������u]��u�u�u��w����]�U���V�uj h�V�u�u��������t1�E�P�v�u�,   ����u�E�P�V�  ��tj P�u��U����jX�3�^��U��QSV�E�]WP�E�P�d	�uS���   ����u-�}�t/��t#�d	j �u��   ��X  YPh$�S���jX_^[�Ëu�EV�0�d	S���   ����u܍FP�E�pS�   ����uŋE�~W�p�d	S���   ����u��FP�E�pS�K   ����u��E��V�p�d	S���   �����p���f����P�����f�P�����3��P����d	VW�t$��X  Y��V��������u7Vh`���  Y��Yt&�|$ t�d	j VhD��t$��   ��jX��D$�83�_^�U���SV�u�E�W�}3�PSh��V�uW�A���������   �EP�EP�d	�vW���   ������   9]f�E� �]�f�]�~�E�0�d	��X  YP����E��}~3�EP�E�p�d	W���   ����u+�}��  w"�u���f�E��u��E�PW�v����_^[�ád	Shp�W���  ��jX��U��Q�EP�EP�E�Ph���u�u�u�[�������u���u�u�u��u�u������U��EP�EPh���u�u�u��������u]��u�u�u耱  ��]�U��EP�EPh,��u�u�u��������u]��u�u�u��  ��]�U��V�uW�}j j h`�V�uW觱������t(�EP�vW���������u�EP�vW��������tjX��u�uW������_^]�U��V�uW�}j h��V�uW�C�������t0�EP�vW�d�������u�EP�u��  ��tj PW��Q����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U����EVP�E�uP�E��e� P�E�Pj h��V�u�u褰����$��tj�E�j P�v�u�2V������tjX��u�u�u��u��u��u�p����^��U��Q�EV�uP�E�e� Pj h��V�u�u�9�������tj�E�j P�v�u��U������tjX��u�u�u��u�f����^��U����EVP�E�uP�E��e� P�E�Pj h4�V�u�u�ʯ����$��tj�E�j P�v�u�XU������tjX��u�u�u��u��u��u�ip����^��U��Q�EV�uP�E�e� Pj h|�V�u�u�_�������tj�E�j P�v�u��T������tjX��u�u�u��u�?f����^��U���SVW3��uW�E�WP�E�WPWWh��V�u�}��u������,��tj�E�}P�d	�v���  9}YY�Eu�}�v�d	��   �v�ءd	��   �v�E��d	��   �E�E�P�v�u�=�������t9}�t	�u��k���YjX��u��u�u��u��u�S�u�u�~���� _^[��h��t$�t$�t$�4�������u��t$�a���Y�U��V�uj j h(�V�u�u��������u�?�e �ESP�v�d	���  �} YY��u3��v�d	��   PS�u�������[^]�U��V�uW�E3�PWWh\�V�u�u藭������tL�ESP�d	�v�}���  9}YY��u3��v�d	��   Y�uPS�Y�  ;�[tWP�u�'N����jX�3�_^]�U��V�uj h��V�u�u��������u�+�e �EP�d	�v���  �} YYu3�P�u�>}��YY^]�U��V�uj j h��V�u�u�ʬ������u�?�e �ESP�v�d	���  �} YY��u3��v�d	��   PS�u��}����[^]�U��EV�uPj j h��V�u�u�^�������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u��}����[^]�U��QQSV�uW3��E�WPWWWh(�V�}��u�u������$��tY�E�}P�d	�v���  9}YY�Eu�}�v�d	��   �v�ءd	��   �E�E�P�v�u�B�������t9}�t	�u��p���YjX��u��u��uS�u�u��~����_^[��U��EV�uPj j hp�V�u�u�5�������u�B�e �ESP�v�d	���  �} YY��u3��v�d	��   �uPS�u舏����[^]�U��QV�E�W�}3�PVVVh��W�u�u�ê���� ��u�u�E�uP�d	�w���  9uYY�Eu�u�ESP�d	�w�u���  9uYY��u3ۍE�uP�d	�w���  9uYYu3��u�PS�u�u臑����[_^��U��Q�EV�uP�E�Pj h��V�u�u��������u�2�e �EP�d	�v���  �} YYu3��u�u�P�u�9�����^��U��EV�uPj h�V�u�u���������t;�e �EP�d	�v���  �} YYu3��uP��  ��tj P�u�aJ����jX�3�^]�U��QV�E�W�}3�PVVVh4�W�u�u�P����� ��u�u�E�uP�d	�w���  9uYY�Eu�u�ESP�d	�w�u���  9uYY��u3ۍE�uP�d	�w���  9uYYu3��u�PS�u�u�Ɉ����[_^��U��V�uW�E3�PWWWhh�V�u�u諨���� ��u�Q�ESP�d	�v�}���  9}YY��u3��v�d	��   �v���d	��   �uPWS�u蓌����[_^]�U��V3�W�}VVVh��W�u�u�.�������t}�E�uP�d	�w���  9uYY�Eu�u�ESP�d	�w�u���  9uYY��u3ۍE�uP�d	�w���  9uYYu3�PS�u���  ;�[tVP�u�H����jX�3�_^]�U���V�E�WP3��E��uWPWWW�E�WPWh��V�u�u�n�����4��t�E�P�d	�v�u���   ����tjX��   �E��}�E�EP�d	�v���  9}YY�E�u�}��v�d	��   �E�EP�d	�v�}���  ��9}�Eu�}�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v ���  9}YYu3��u�P�u�S�u�u��u��u��u��u��z���d	P���  ���   P�u���43�[_^��U��EV�uP�EPj hP�V�u�u�C�������t*�v�d	��   Y�u�uP���  ��tP�u�tH��YYjX�3�^]�V�t$j h��V�t$�t$��������u^��v�d	��   P�t$��z����^�V�t$j h��V�t$�t$謥������u^��v�d	��   P�t$�u�����^�U��V�uW3�WWh��V�u�u�h�������u�M�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v���  9}YYu3�PS�u�]�����[_^]�U��EV�uPj h �V�u�u��������u�/�e �EP�d	�v���  �} YYu3��uP�u�W�����^]�U��SV�u3�WSSh4�V3��u�u蓤������t5�E�]P�d	�v���  9]YY�Eu�]�v�u�;   ��Y;�YuW�   YjX�W�u�u誂����_^[]Ã|$ t�t$��Y�U���V�E�uWP�E�P�d	�uV���   �����  �}�t"����   P�d	h`�V���  ����   �E�P�E�p�d	���  ���EP�E��D Pj V�j3��������   �u�E�0�d	V���   ������   �E��P�E�p�d	V���   ����ua�E�P�E�p�d	V���   ����uD�E�P�E�p�d	V���   ����u'�E�M�W�H�E�M��H	�E��P�`��EYY��u����Y3�_^��U��Q�EV�uP�E�Pj h��V�u�u�Ƣ������t>�e �EP�d	�v���  �} YYu3��u�u�P��  ��tj P�u�dC����jX�3�^��U��V�uj h��V�u�u�\�������u�+�e �EP�d	�v���  �} YYu3�P�u����YY^]�U��EV�uPj j h��V�u�u��������u�C�d	S�v��   �e �؍EP�d	�v���  ���} u3��uPS�u�w����[^]�U��QSV�uW3��E�]WPWh@�V�u�}�S荡������tR�E�P�vS��������u>�v�d	��   YP�u�u��(�;�u1�d	S��l  YW���PS�B����9}�t	�u��4���YjX�0�d	W�5����  P�S���PS���9}�t	�u�����Y3�_^[��U��SV�u�Ej P�]�EPh��V�uS�Ǡ������t?�v�d	��   YP�u�u�,���u$�d	S��l  Yj ���PS�dA����jX�#�d	j �5����  P譃��PS���3�^[]�U��V�uj h��V�u�u�:�������t4j�E�5�P�v�u��E������u�u�0���u�u�bN��YjX�3�^]�U��QSVW�u3��EWP�E�]PWh��V�u�}�S�ɟ���� ��tU�E�P�vS���������uA�v�d	��   YP�u�u�u��4�;�u1�d	S��l  YW���PS�P@����9}�t	�u��m���YjX�0�d	W�5����  P茂��PS���9}�t	�u��:���Y3�_^[��U��SV�u�Ej P�]�EPh4�V�uS� �������t?�v�d	��   YP�u�u�8���u$�d	S��l  Yj ���PS�?����jX�#�d	j �5����  P����PS���3�^[]�U��V�u�EW�}Pj ht�V�uW�m�������t7j�E�5�P�vW��C������u�EP�u�u�<���uW�L��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U���  V�u�EWP�E��}Pj h��V�uW�Ν������tw�EP�EP�d	�vW���   ����tX�}@wR3�9uv)j��������5�P�E�4�W�'C������u(F;ur��u�������u�P�u�@����uW�K��YjX��d	P���  ���   PW���3�_^��U��V�uj j j h��V�u�u��������u�c�d	S�v��   �v�ءd	��   �v�E�d	��   P�uS�5����d	j �5H���  P�u�Ƞ��P�u���03�[^]�U��QV�uj �e� hD�V�u�u�}�������tj�E��5HP�v�u�B������tjX��u�菎��Y3�^��hx��t$�t$�t$�.�������u��t$�]���Y�U��� SV3�W�}V�EV�]PVVh��W�u�u�S������$����   �E�uP�d	�w���  9uYY�Eu�u�w�d	��   �w�E��d	���  Y��Yu�u�V�wS�ݻ������uK�E��Ej�E�VP�wS�A������u.�E�P�E�PVV�u��u�u�u��u�,�;�tVPS�<����jX�X�d	���   �E�P�Є��YP�d	S���  YPS��u��d	�u����   ���  ��P�d	S���  YPS���3�_^[��U��QQV�uj h�V�u�u轚������t2�E�P�v�u蕄������u�E�P�0���tj P�u�g;����jX�3�^��U���$SV�EWP3ۍESP�E��uP�E��}PSSSh,�V�uW�E�����0��tx�E�P�vW��������ud�EP�d	�vW���   ����uJ9]t�E�P�vW��������u1�E��E��]�v�d	��   �؍E�jP�vW�"�������tjX�*�E��u����M�#�P�E��u�u��u�S�uPW�k�����$_^[��U���SV�E�uWP�E3�P�}SSSh��V�uW�f�����$��t`�E�P�vW�@�������uL�EP�d	�vW���   ����u29]t�E�P�vW��������u�]��E�jP�vW�[�������tjX�!�E��u���u�M��#�P�E�SPW������_^[��U��QQV�uj h�V�u�u跘������t2�E�P�v�u菂������u�E�P�4���tj P�u�a9����jX�3�^��U��QQV�uW�}j hD�V�uW�U�������t2�E�P�vW�/�������u�EP�E�P�8���tj PW��8����jX�5�d	j �5����   �u�G{����P�d	W���  YPW���3�_^��U��QQV�uj hp�V�u�u���������t2�E�P�v�u虁������u�E�P�<���tj P�u�k8����jX�3�^��U��QQ�EV�uPj h��V�u�u�]�������t�E�P�v�u�5�������tjX��u�E�P�u胉����^��U����EV�uP�E�j Pj h��V�u�u������� ��t�E�P�v�u�ր������tjX�+�EP�d	�v���   �uP�E��u�u�P�u裋���� ^��U���V�u�EW�}Pj j h�V�uW舖������tX�E�P�vW�b�������uD�E�jP�vW賂������u.�E��M����#��MQ�uP�E�P�@���tj PW�7����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U����EV�uP�E�j Pj hD�V�u�u�˕���� ��t�E�P�v�u�������tjX�+�EP�d	�v���   �uP�E��u�u�P�u芋���� ^��U���V�u�EW�}Pj j h��V�uW�U�������tM�E�P�vW�/������u9P�E�P�vW聁������u$�EP�E��uP�E�P���  ��tj PW��5����jX�V�d	���   �E�P藂��YP�d	W���  YPW��u�d	���   �d	��PW���   ���  YPW���3�_^��U��QQV�u�EWP�E�3�PWWh��V�u�u�z����� ��t_�ESP�d	�v�}���  9}YY��u3ۍE�}P�d	�v���  9}YYu3��u�u�P�E�SP�(���[u�u�wB��YjX�%�d	W�54���  �u��@w��P�u���3�_^��U��Q�E�V�uPj �e� h��V�u�u�������t7j�E�54P�v�u�L9������u�u��u�$���u�u��A��YjX�3�^��U��EV�uPj h0�V�u�u�[�������tj�E�54P�v�u��8������tjX��u�u�u�������^]�U��EP�EPhX��u�u�u���������u]��u�u�u�ؑ����]�U��QQ�EP�EP�E�P�E�Ph���u�u�u蹒���� ��u���u�u�u��u��u�ь������U��V�uW�}j h��V�uW�z�������t4j�E�5�P�vW�8������u�EP�u�D���uW�@��YjX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^]�U��Q�EV�uP�EPj h��V�u�u��������t:j�E��5�P�v�u�o7������u�u�u�u��H���u�u�@��YjX�3�^��U���$SV�EWP�EP�u�E��}P3�PPPh0�V�uW�j�����(��tzj�E��5�P�vW��6������u^�EP�d	�vW���   ����uDj�]�5��E�P�vW�6������u%�u�E��u�u�P�u�S�u��p���uW�L?��YjX�)�u��E�h�#P����E�jP�d	W���  ��3�_^[��U��QV�uj �e� h��V�u�u薐������tj�E�j P�v�u�$6������tjX�'�E�P��Q�d	P���  ���   P�u���3�^��U��QV�uj �e� h��V�u�u�&�������tj�E�j P�v�u�5������tjX�'�E�P��Q�d	P���  ���   P�u���3�^��U��QV�uW�}�e� j h��V�uW贏������t|j�E��5�P�vW�@5������t6j�E��5$P�vW�$5������tj�E��5�P�vW�5�����*�d	W��l  �E�Y�U�RP�Q��tj PW�0����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EWP�E�}P�e� j h(�V�uW�ю��������   j�E��5�P�vW�Y4������t6j�E��5$P�vW�=4������tj�E��5�P�vW�!4�����0�d	W��l  �E�Y�U�R�u�uP�Q��tj PW�'/����jX�5�d	j �5����   �u�oq����P�d	W���  YPW���3�_^��U��QSV�u�EW3ۋ}PSSh`�V�u�]�W�ލ������t_j�E��5$P�vW�j3������uC�EP�d	�v���  YY�uP�P��U�E�E�R�u��uP�Q;�tSPW�[.����j[�+�u�d	���   Y�d	PW���   ���  YPW����u�X�_��^[��U��QQS�E�]V�uP�e� �e� j h��V�uS��������t<j�E��5$P�vS�2������u �E��U�R�u�P�Q0��tj PS�-����jX�%�d	�u����  ���PS����u��X�3�^[��U��QV�u�EWP�E�}P�e� j h��V�uW�r�������t?j�E��5$P�vW��1������u#�E��UR�u��uP�Q,��tj PW�-����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h �V�uW�ԋ������t9j�E��5$P�vW�`1������u�E��URP��Q8��tj PW�w,����jX�5�d	j �5����   �u�n����P�d	W���  YPW���3�_^��U��QV�u�EWP�E�}P�e� j hX�V�uW�,�������t?j�E��5$P�vW�0������u#�E��UR�u��uP�Q4��tj PW��+����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EW�}P�e� j h��V�uW芊������t<j�E��5�P�vW�0������u �E��UR�u�P�Q ��tj PW�*+����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EW�}P�e� j h��V�uW��������t<j�E��5�P�vW�w/������u �E��UR�u�P�Q8��tj PW�*����jX�5�d	j �5����   �u��l����P�d	W���  YPW���3�_^��U��QV�uW�}�e� j h�V�uW�H�������t9j�E��5�P�vW��.������u�E��URP��Q��tj PW��)����jX�5�d	j �50���   �u�3l����P�d	W���  YPW���3�_^��U��QV�uW�}�e� j h4�V�uW計������t=j�E��5�P�vW�4.������u!�E��UR�U�RP�QH��tj PW�G)����jX�_�d	j �5����   �u�k����P�d	W���  YPW��u�d	���   �d	��PW���   ���  YPW���3�_^��U���S�]V�EW�}3�PVhh�S�u��u�u��u��u�W�ʇ������tGj�E��5�P�sW�V-������u+�U�E�R�UR�U��R�U�R�uP�Q0;�tVPW�_(����jX�   �d	�u����   �N��YP�d	W���  YPW��5X����u��֡d	�u����   ���YP�d	W���  YPW����u����u�d	���   Y�d	PW���   ���  YPW��d	�u􍘸   ������P�d	W���  YPW����u���3�_^[��U��QV�u�EW�}P�e� j h��V�uW荆������t<j�E��5�P�vW�,������u �E��UR�u�P�Q$��tj PW�-'����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U���S�]V�EW�}3�PVh��S�u��u�u��u��u�W��������tGj�E��5�P�sW�n+������u+�U�E�R�UR�U��R�U�R�uP�Q$;�tVPW�w&����jX�   �d	�u����   �f��YP�d	W���  YPW��5X����u��֡d	�u����   �2��YP�d	W���  YPW����u����u�d	���   Y�d	PW���   ���  YPW��d	�u􍘸   ������P�d	W���  YPW����u���3�_^[��U��QV�uj �e� h�V�u�u諄������tj�E��5�P�v�u�5*������tjX�'�E�P��Q�d	P���  ���   P�u���3�^��U��QV�u�EW�}P�e� j h<�V�uW�1�������t<j�E��5�P�vW�)������u �E��UR�u�P�Q��tj PW��$����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EW�}P�e� j hp�V�uW蒃������t<j�E��5�P�vW�)������u �E��UR�u�P�Q��tj PW�2$����jX�5�d	j �5����   �u�zf����P�d	W���  YPW���3�_^��U���SV�uW3��]WWh��V�u�}�S��������tZj�E��5�P�vS�w(������u>�E�P�d	�v��   YP�X�;�u�E��UR�U�RP�Q;�tWPS�m#����jX�4�d	W�5����   �u�e����P�d	S���  YPS���3�_^[��U���SVW�E�3�P�}��}��d��u�]WWWh��V�uS��������tbj�E��5tP�vS�'������uFj�E�WP�vS�'������u/�v�d	��   Y�u�M�VP�u��Q�R(;�tWPS�"����jX�.�d	���  �E�P����PS���f�}�u
�E�P��3�_^[��U���V�uW�}�e� j h�V�uW�S�������t9j�E��5tP�vW��&������u�E��U�RP��Q��tj PW��!����jX��d	���  �E�P���PW���3�_^��U��QQS�]V�u�e� �e� j h@�V�uS�ƀ������t9j�E��5tP�vS�R&������u�E��U�RP��Q��tj PS�i!����jX�%�d	�u����  �[��PS����u��X�3�^[��U��QV�uW�}�e� j hl�V�uW�6�������t9j�E��5tP�vW��%������u�E��URP��Q ��tj PW�� ����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h��V�uW�������t9j�E��5tP�vW�*%������u�E��URP��Q$��tj PW�A ����jX�5�d	j �5����   �u�b����P�d	W���  YPW���3�_^��U��QQV�u3�W�}PPh��V�E��u�E�W��~������t8j�E��5tP�vW�$������uj�E��5tP�vW�i$������tjX�(�E��u��P�Q<�d	P���  ���   PW���3�_^��U��QQSV�uW3��]WWh�V�u�}��}�S�a~������tNj�E��5tP�vS��#������u2j�E�WP�vS��#������u�E��u��P�Q;�tWPS������jX�3�_^[��U���SV�uW3��]WWWh8�V�}��u�}�}�S��}������thj�E��5tP�vS�_#������uLj�E�WP�vS�H#������u5j�E�WP�vS�1#������u�u��E��u�P�Q;�tWPS�G����jX�3�_^[��U��QV�uW�}�e� j hx�V�uW�6}������tj�E��5tP�vW��"������tjX�-�E�P��Q@�d	j �5@���  PW����PW���3�_^��U���SV3��]W�}VVh��W�u�u��u��u�S�|������tRj�E��5tP�wS�="������u6j�E�VP�wS�&"������u�E��U�R�u��P�QD;�tVPS�;����jX�#�d	V�5@���  �u��_��PS���3�_^[��U��QQSV�uW3��]WWh��V�u�}��}�S�|������tSj�E��5tP�vS�!������u7j�E��5@P�vS�s!������u�E��u��P�QH;�tWPS�����jX�3�_^[��U��QQSV�uW3��]WWh�V�u�}��}�S�u{������tNj�E��5tP�vS�!������u2j�E�WP�vS�� ������u�E��u��P�Q;�tWPS�����jX�3�_^[��U��QQSV�uW3��]WWhP�V�u�}��}�S��z������tXj�E��5�P�vS�x ������u<j�E��5lP�vS�\ ������u �E��URW�u��P�QP;�tWPS�p����jX�J9}t�d	j��u���  Y��Y�u�0���d	Wh����   Y��Y�d	VS���  Y3�Y_^[��U��QQSV�uW3��]WWh��V�u�}��}�S�z������tSj�E��5|P�vS�������u7j�E��5�P�vS�������u�E��u��P�Q;�tWPS�����jX�3�_^[��U��QV�uj �e� h��V�u�u�y������t9j�E��5|P�v�u�������u�E�P��Q��tj P�u�.����jX�3�^��U��Q�EV�uPj �e� h��V�u�u�y������t<j�E��5|P�v�u�������u�E��u�P�Q��tj P�u�����jX�3�^��U��QQSV�uW3��]WWh�V�u�}��}�S�x������tRj�E��5$P�vS�4������u6j�E�WP�vS�������u�E��UR�u��P�Q;�tWPS�2����jX�-�u�d	���   Y�d	PS���   ���  YPS���3�_^[��U��QQSV�uW3��]WWhP�V�u�}��}�S��w������tSj�E��5$P�vS�|������u7j�E��5�P�vS�`������u�E��u��P�Q;�tWPS�y����jX�3�_^[��U��Q�EV�uPj �e� h��V�u�u�fw������t<j�E��5$P�v�u��������u�E��u�P�Q��tj P�u�����jX�3�^��U��QV�uW�}�e� j h��V�uW��v������t9j�E��5�P�vW�������u�E��URP��Q��tj PW�����jX�5�d	j �5����   �u��Y����P�d	W���  YPW���3�_^��U���SV�uW3��]WWh0�V�u�}�S�Sv������tZj�E��5�P�vS��������u>�E�P�d	�v��   YP�X�;�u�E��UR�U�RP�Q;�tWPS������jX�4�d	W�5$���   �u�Y����P�d	S���  YPS���3�_^[��U��QV�u�EW�}P�e� j h��V�uW�u������t@j�E��5�P�vW�������u$�E��UR�U�R�uP�Q��tj PW�*����jX�_�d	j �5$���   �u�rX����P�d	W���  YPW��u�d	���   �d	��PW���   ���  YPW���3�_^��U��QV�uj �e� h��V�u�u�t������t9j�E��5�P�v�u�I������u�E�P��Q��tj P�u�b����jX�3�^��U��Q�EV�uPj �e� h�V�u�u�Qt������t<j�E��5�P�v�u��������u�E��u�P�Q��tj P�u������jX�3�^��U��QV�uW�}�e� j hP�V�uW��s������t9j�E��5�P�vW�n������u�E��URP��Q��tj PW�����jX�5�d	j �5����   �u��V����P�d	W���  YPW���3�_^��U���V�u�EW�}P�e� j h��V�uW�<s������t<j�E��5�P�vW��������u �E��U�R�u�P�Q��tj PW������jX��d	���  �E�P����PW���3�_^��U���SV�uW3��]WWWh��V�}��uS�r������toj�E��5LP�vS�8������uS�v�d	��   �EY�E�P�d	�v��   YP�X�;�u�E��UR�U�R�uP�Q;�tWPS�����jX�4�d	W�5����   �u�bU����P�d	S���  YPS���3�_^[��U��QQSV�u3�W�}SSSh�V�]��u�]�W��q��������   j�E��5LP�vW�W������ug�v�d	��   j�E�5��E�P�vW�*������tj�E��5�P�vW�������u�u��E��u�P�Q$;�tSPW�$����jX�3�_^[��U��QV�uj j �e� hP�V�u�u�q������tIj�E��5LP�v�u�������u+�v�d	��   Y�M�PQ��R��tj P�u�����jX�3�^��U��QV�uW�}�e� j h��V�uW�p������t9j�E��5LP�vW�#������u�E��URP��Q��tj PW�:����jX�5�d	j �5����   �u�S����P�d	W���  YPW���3�_^��U���SV�uW3��]WWWh��V�}��uS��o������tWj�E��5LP�vS�~������u;�v�d	��   �EY�E�P�d	�v��   YP�X�;�tWPS�w����jX�,�E��U�R�u�P�Q(�d	P���  ���   PS���3�_^[��U���$SV�u3�WSSSSh��V�]��u�u�7o���� ����   j�E��5LP�v�u�������uu�v�d	��   �EY�E�P�d	�v��   �=X�YP��;�u6�E�P�d	�v��   YP��;�u�U�E�R�U�R�U�R�uP�Q ;�tSP�u�|����jX�8�d	S�5����   �u��Q����P�d	�u���  YP�u���3�_^[��U��QV�uW3�WWhD�V�u�}��u�5n������tWj�E��5LP�v�u�������u9�E�}P�d	�v���  9}YYu3��M�PQ��R;�tWP�u�����jX�3�_^��U��QV�uW�}�e� j h��V�uW�m������t9j�E��5LP�vW�6������u�E��URP��Q��tj PW�M����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j h��V�uW�m������t9j�E��5�P�vW�������u�E��URP��Q��tj PW�����jX�5�d	j �5����   �u��O����P�d	W���  YPW���3�_^��U��QV�uj �e� h��V�u�u�sl������t9j�E��5�P�v�u��������u�E�P��Q��tj P�u�����jX�3�^��U��Q�EV�uPj �e� h$�V�u�u�l������t<j�E��5�P�v�u�������u�E��u�P�Q��tj P�u�����jX�3�^��U��QV�uW�}�e� j hX�V�uW�k������tYj�E��5�P�vW�"������tj�E��5�P�vW�������u!�E��UR�U�RP�Q��tj PW�����jX�_�EP�d	���   Y�d	PW���   ���  YPW��d	j �5����   �u�7N����P�d	W���  YPW���3�_^��U��QV�u�EW�}P�e� j h��V�uW�j������tTj�E��5�P�vW�4������tj�E��5�P�vW�������u�E��u�P�Q��tj PW�0����jX�3�_^��U��QSV�u3�W�}SSh��V�u�]�W�j������tnj�E��5�P�vW�������tj�E��5�P�vW�������u6�EP�d	�vW���   ����u�E�S�u�P�Q8;�tSPW�
����jX�3�_^[��U��QV�uW�}�e� j h$�V�uW�{i������tUj�E��5�P�vW�������tj�E��5�P�vW��������u�E��URP��Q|��tj PW�
����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j hl�V�uW��h������tUj�E��5�P�vW�R������tj�E��5�P�vW�6������u�E��URP��QL��tj PW�M	����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j h��V�uW�h������tUj�E��5�P�vW�������tj�E��5�P�vW�������u�E��URP��QT��tj PW�����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j h��V�uW�\g������tUj�E��5�P�vW��������tj�E��5�P�vW��������u�E��URP��QD��tj PW������jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h �V�uW�f������tUj�E��5�P�vW�4������tj�E��5�P�vW�������u�E��URP��Qt��tj PW�/����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h\�V�uW��e������tYj�E��5�P�vW�������tj�E��5�P�vW�d������u!�E��UR�U�RP�Q,��tj PW�w����jX�[�EP�d	���   Y�d	PW���   ���  YPW��EP�d	���   �d	��PW���   ���  YPW���3�_^��U���V�uW�}�e� j h��V�uW�e������tUj�E��5�P�vW�
������tj�E��5�P�vW�|
������u�E��U�RP��Q<��tj PW�����jX��d	���  �E�P�5���PW���3�_^��U���V�uW�}�e� j h��V�uW�fd������tUj�E��5�P�vW��	������tj�E��5�P�vW��	������u�E��U�RP��Q$��tj PW������jX��d	���  �E�P����PW���3�_^��U��QV�uW�}�e� j h �V�uW��c������tUj�E��5�P�vW�N	������tj�E��5�P�vW�2	������u�E��URP��Q@��tj PW�I����jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EW�}P�e� j h\�V�uW�
c������tXj�E��5�P�vW�������tj�E��5�P�vW�z������u �E��UR�u�P�Q��tj PW�����jX�5�d	j �5����   �u��E����P�d	W���  YPW���3�_^��U��QV�uW�}�e� j h��V�uW�Kb������tUj�E��5�P�vW��������tj�E��5�P�vW�������u�E��URP��Q��tj PW������jX�/�EP�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�u�EW�}P�e� j h��V�uW�a������tXj�E��5�P�vW�������tj�E��5�P�vW�������u �E��UR�u�P�Q��tj PW�����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j h,�V�uW��`������tQj�E��5�P�vW�e������tj�E��5�P�vW�I������u�E�P��Q0��tj PW�d����jX�3�_^��U��QV�uW3�WWWh`�V�}��u�u�S`��������   j�E��5�P�v�u��������tj�E��5�P�v�u�������uS�d	S�v��   �v�ءd	��   ��h,$V�������u3��E�VSP��Qx;�[tWP�u� ����jX�3�_^��U��QS�]V�uj �e� j h��V�uS�_������taj�E��5�P�vS�������tj�E��5�P�vS��������u)�v�d	��   Y�M�PQ��RH��tj PS� ����jX�3�^[��U��QS�]V�uj �e� j h �V�uS��^������taj�E��5�P�vS�������tj�E��5�P�vS�c������u)�v�d	��   Y�M�PQ��RP��tj PS�n�����jX�3�^[��U��QV�u�EW�}P�e� j hH�V�uW�Z^������tTj�E��5�P�vW��������tj�E��5�P�vW��������u�E��u�P�Q`��tj PW�������jX�3�_^��U��QV�u�EW�}P�e� j h��V�uW��]������tTj�E��5�P�vW�Z������tj�E��5�P�vW�>������u�E��u�P�Qh��tj PW�V�����jX�3�_^��U��QV�u�EW�}P�e� j h��V�uW�B]������tTj�E��5�P�vW��������tj�E��5�P�vW�������u�E��u�P�Qp��tj PW�������jX�3�_^��U��QV�u�EWP�E�}P�e� j h$�V�uW�\������tWj�E��5�P�vW�>������tj�E��5�P�vW�"������u�u�E��u�P�Q(��tj PW�7�����jX�3�_^��U��QSV�uW3��]WWh��V�u�}�S�%\��������   j�E��5�P�vS�������tj�E��5�P�vS�������uM�EP�d	�v���   �}��  YY~�d	Whp�S���  ��M�P�u�Q�RX;�tWPS�x�����jX�3�_^[��U��QV�uW�}�e� j h��V�uW�g[������tQj�E��5�P�vW�� ������tj�E��5�P�vW�� ������u�E�P��Q4��tj PW�������jX�3�_^��U��QV�uW�}�e� j h�V�uW��Z������t<j�E��5�P�vW�n ������u �E��URP����   ��tj PW������jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j hD�V�uW�FZ������t<j�E��5�P�vW���������u �E��URP����   ��tj PW�������jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j hh�V�uW�Y������t<j�E��5�P�vW�7�������u �E��URP����   ��tj PW�K�����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uW�}�e� j h��V�uW�Y������t<j�E��5�P�vW��������u �E��URP����   ��tj PW������jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h��V�uW�tX������t<j�E��5�P�vW� �������u �E��URP����   ��tj PW������jX�-�u�d	���   Y�d	PW���   ���  YPW���3�_^��U��QV�uW�}�e� j h��V�uW��W������t<j�E��5�P�vW�e�������u �E��URP����   ��tj PW�y�����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U��QV�uj j �e� h �V�u�u�=W������tLj�E��5�P�v�u���������u.�v�d	��   Y�M�PQ����   ��tj P�u�������jX�3�^��U��Q�EV�uPj �e� h0�V�u�u�V������t?j�E��5�P�v�u�F�������u!�E��u�P���   ��tj P�u�Y�����jX�3�^��U��QV�uj j �e� h`�V�u�u�JV������tLj�E��5�P�v�u���������u.�v�d	��   Y�M�PQ����   ��tj P�u�������jX�3�^��U��Q�EV�uPj �e� h��V�u�u��U������t?j�E��5�P�v�u�S�������u!�E��u�P���   ��tj P�u�f�����jX�3�^��U��Q�EV�uPj �e� h��V�u�u�UU������t?j�E��5�P�v�u���������u!�E��u�P���   ��tj P�u�������jX�3�^��U��QV�uj j �e� h��V�u�u��T������tLj�E��5�P�v�u�m�������u.�v�d	��   Y�M�PQ����   ��tj P�u�s�����jX�3�^��U���4V�uW�}�e� j h�V�uf�E�0 W�\T������t9j�E��5�P�vW���������u�E��U�RP��Q��tj PW�������jX��d	���  �E�P�@���PW���3�_^��U��QV�uW�}�e� j hD�V�uW��S������t9j�E��5�P�vW�`�������u�E��URP��Q��tj PW�w�����jX�.�} t&�d	j��u���  ���  PW����u�0�3�_^��U���4S�]V�uj �e� j h|�V�uS�7S������tMj�E��5�P�vS���������u1�E�P�vS���������u�E��U�RP��Q��tj PS�������jX�3�^[��U��QSV�u3�W�}Sh��V�]��uW�R������tj�E��5xP�vW�A�������tjX�}�E��URP��Q �d	P���  ���   PW���9]t�d	j��u���  Y��Y�u�0���d	Sh����   Y��Y�d	SW���   ���  YPW���3�_^[��U��QV�uj �e� h��V�u�u��Q������tj�E��5xP�v�u�u�������tjX�'�E�P��Q�d	P���  ���   P�u���3�^��U��Q�EV�uPj j �e� h�V�u�u�qQ������tLj�E��5xP�v�u���������u.�v�d	��   Y�M��u�PQ�R��tj P�u������jX�3�^��U��QV�uW�E3�PWWhL�V�u�}��u��P������tZj�E��5xP�v�u�x�������u<�E�}P�d	�v���  9}YYu3��M��u�PQ�R;�tWP�u�p�����jX�3�_^��U��QV�uj j �e� h��V�u�u�`P������tIj�E��5xP�v�u���������u+�v�d	��   Y�M�PQ��R��tj P�u�������jX�3�^��S�\$��tj h��S��y  ����ujX[ád	Vh��h��S��L  �d	h��S��  ���=� u/�<���t3�P��   �����@���Y��u���   �pL��t&�tLj �v�6P�d	S���  �F������uߡ���tZW����jh�P�d	S���  �6�d	�vj�7S���  �6�d	�vj!�7S���  ����8�F��~���u�_h�S�u   Y3�Y^[á<V�t$W����t�6�7�,�  Y��Yt0���u�<�F��3��5<�N�9 t�J�Q�у���G��t�F�׋�؅�t�W�z_^�U��QW3�9=Du�d	Wh����  Y�D   Y�E98��   SV�p� Ht^HtEHt1HtH��   �FW�0�v��6�   ���H�FW�0�6�G1�����6�d	j��6���   ��F��d	QQ�$���   Y��v�d	���   Y��;�t=�d	jSj j���  �v����   YYP�u��E�P�v�h��(�� �X3��� 9~�F��<���^[_��U���   V�u�6��  Y�M�DH=�  v3��6Q������uƅ ���_P��0���6P��  �� ���j�P�d	���   ��^��U���S�]3�V�u��W�E��E�E��E��E�   �J  �EP�d	�v�u���   �����_  �EP�d	�v�u���   �����?  �Ej_��   j#�Zt4��t%��t��t%;��[  ��v�Q  �E$��E$E�   9E��   ��  �} @��  �}   ���  �}��   �}�  9}�v  �}�l  �}�0�E��@�Z  ��@�Q  -�   �F  -   �;  -   �0  �  �   9E��   t_�E=   �  =    �  = @  ��   = �  t=   �;���   �E�P�d	�v�u���   ������  ��  ;���   �E#�t-;��#  �v�d	��   �v�E��d	��   Y�?  �E�P�v�u�]���������  �E�P�v�u�C���������  �E��E��^  �}8 ��   �}   t+�}   ��   �}��tx�}���toj hL��   ;�}�d	h(�Vj�u��(  ���  �E#�t;�uQ�v�d	��   Y�E���   �E�P�v�u����������   �E���;���   �E#��� tr��tHHHtj h���u�d	���  ���   �v�d	��   ;�Y�E�~r�v�d	��   Y�^�E�P�d	�v�u���   ����u[;�~A�8����E�P�v�u���������u<�E�;߉E�~�E�P�v�u���������u�E��E��u��u��u�u����e� �}� _^[t	�u��C���Y�}� t	�u��4���Y�E���U��V�uj�FP�u�X�  ����t9jh���u�B�  ����t#jh���u�,�  ����t�E�  �@ ���V�P�E�03�^]� �D$�@�@� V�t$�N�Fu<�F��tP�d	��h  Y�F��t��F�8 P�d	���   YV��Y3�^� �D$��t�  3�� �@ �� �@ �� U����   SVW�}3�;�u
�@ ���  �E�P�E�P�d	�wS���   ����t
�@ ��  �E���   P�$���Y;�u
� ��  3�9]�~�M�����@;E�|��u�d	���   �M��u���d	���   �M��D��EP�d	���   �M�SS�D��d	�E����   �M������M;�tB�AHx<����@�E��M�d	���   ��P�Z��P�E��4�j ������Muҋ}�E�3�3�9]�~�֋��� A;M�|�W�P�����P�d	�w���  �d	h   V�u��w���  ��;ÉEt�]$��t&j j S�  �E���C�9] t	�u �d��]�����P�d	�w���  3�Y9]�Y~!����8 P�d	���   YC��;]�|ߋW�P�E_^[��$ U����}St�d	h���uj�u��(  ���H�]�E�P�d	�s��   YP�@���}j P�u���������EPj j �u��������tjX�c�EVW�u�� ���E�x�����}�d	W��,  �E�x�E�@   �C� �M�C�A�d	�u���  � W��PW���3�_^[��U���   S�]VWj3�^���}؉u�}!�d	h���uV�u��(  �����h  �u�E�P�v�u��V�������H  �E�P�E�P�d	�v�uV���   �����#  �}�}Wh`�V�  �E�P�E��0�d	V���   ������  �E�P�E��p�d	V���   ������  �E�P�E��p�d	V���   ������  �E��E�E�P�E��pV�JV��������  �}�|&�E�P�E�P�E��p�d	V���   ����t�b  �C��}ԉE���E�5$��\ �E�����P�]��։E��E�D P��Y�E�Y�M�;��  ;��   ;߉}�~�E���f�<�E�9]�|�E�����E��������#��E��U�t5jY;�t�d	Wh(��u���  ���Q  �M��M��M��E�   ��}��}�;ǉ}�����   �M�����u��A�E�V�d��E����E�P�d��M��A;E|3���U���U�;�t���3�P�E��u����E�PVQ�u�Kt��������  �E��m�K��;�u�j �E�WP�{  ���U�M���E�R�U�Rf�U�f���f���#U�R�U�R�u��u�hx��u�P�Q���}�;��u���   f�}�t�d	�u����  ��U��P�u����E�jY�E�9M�M�~f�M�����u��A�E�9}�tP� t2�d	h   V��  �U��Y�MP�E�W�4��u�������  �E��E��M��M�H��H;M�E�|��}��  ��	 ��N  9}�t�E�P�U��d	WW���   ��d	j
h����   ���   PVW��d	�u����   ����PVW��d	jh����   ���   PVW��d	��@�u����   �\���PVW��d	jh�����   ���   PVW��d	�u����   �'���PVW��d	jh�����   ���   PVW��d	��H�u����   ���   PVW��d	jh�����   ���   PVW��d	�uč��   ���   PVW��d	jh�����   ���   PVW��M��d	��HQ���   ���   PVW�Vh	 ��u�]�����9}�tF�u�d	���  �ءd	jh�GS��  �d	���u���  �0�P�u�S����t9}�to�E�%  �=   t=   t=   t=   uK�u��d�����Y;�t<�u�d	���  ��d	jh�GV��  �d	j�SV��  S���� �u��5X����u����u����XWV�u�z������� �t�� �u;�}��t5�u䍅t���h�VjP�(���t���WP�d	h���u��   �� 9}�|�E�f�8uP���u�jX;��E�~�E���E�P�u�Yw���E�9u�YY|��u��5����u��֋E�YY�Wh���u�d	���  ��jX_^[���   �   �%�%��hvU� y  Yù%�%|��   �   �$�%x�h�U��x  Yù$�%t��   �&   Q�D$j j ���  �% �Y�h�U�x  Y��0u�0��^  Ë ��tV���   V�x  �%  Y^�%���V��x  QV��W�u��~D �=h��E�   t"j j j�vH� �h�  �vD�x��vD�׋F@��tP�׍N0�  �N$�E��y  �e� �N�5  V�L��M�_^d�    ��Q�L��U���  SV�5T�3�WS�,jW��+�tJHt-H��   HSth$��h���u�d	���  ���   j[SSW��;���   j �P��鍅p���Ph  �����tSh���B��   ��uSh|��1��*  ��uShT�� �O  ��uSh���H  ��Su"h���u�d	���  ��jjW��jX��d	hV��|  YYjjW��3�_^[�øl���v  QV��u�����F�e� ��tP�d	��h  Y�M��j�N����M�^d�    ���t$�A���t$PQ�   ��� V�������D$tV�hv  Y��^� ���u)P�d	h1^��$  Y�(Yj j j �X��3Ʌ�����Ã= t�5(�d	��(  Y�5�h�ø���v  ��SVW3ۉe��u�]��u�  Y;�Y�EujX�M�_^d�    [�Ë5���0P�֋}�]�;�t'�E��0P�֋ESSSS�x�\��M�A,�E9X,ty�E��0P�֋5x�j��5�����@�Eu3�덡�MQP�E�P�	  �5(�d	��0  Y�5�0�;�t`�EW�p,��;�t�����E�   �?9]t:�M�E�P�_   �\��E��1�MSP�`�j�M܈]��d��E�@(�E�M��9]t	�u�A  Y�E������3�9]t	�u�)  YSS��t  U��Q�A�e� V�qW�}j �ψ�d��\����0j V�`���_^�� ����[t  Qj4�t  Y�ȉM�3�;ȉE�tP�u�u�   �M�d�    �ø���"t  Q�ESV��3�W;Éu��tP�d	��,  Y�E�]��@;�u�T��E�E�~S�ψ����u��q  YP���u�X��E�N�F�ES�E���d��M�^(�^,�^0��_^[d�    �� ���tP�d	��h  Y�V�t$�F0P�`���u��t���	   V�Ks  Y^ø���Ls  QV��u��F,�E�   ��tP�h�j�N�d��e� j�N����6�M����t�d	V��h  Y�M�^d�    ��U��VW�}� tE�E����ej �Έ�d��u��YP���u�P��u���   �G,��tP�d�W����Y_^]ø���r  3�9A�E�t�U�Q(�\����2P�EP�`��M��j�M�d��M�d�    �� ���=r  �� �Eu3��e  �ESW�x����:  �d	S���  ��Y�%  �E�VP���>  �@�e� �5T���t���Ej �M�E����V��o  YPV�M��X�j�M��E�����E��u�T�P�d	S��  �E�d	S���  ������   �}u[�T�V�o  YPVj �M��H��P�V�o  YPV�M��L��E��u�T��u�P�d	S��  �d	S��8  ���d	S��   ���  P�P�uW�����d	S3���l  ���M��j�M����^��th�jW�������jX_[�M�d�    ��U��Q�A�e� V�qW�}j �ψ����l����0j V�D���_^�� SVW�=x�j��5�ׅ�ul9�0�tV��� �p�"  �5�ӡd	j�Pj � m\�pP�d	��<  ��j��5�ׅ�u9u��5�ӋD$_^[ø���o  ���   �ESVWj �M�����u�e� ���E��E������P�$���Y�E���   j��_~[�u�]�E+މE��3P�d	�6��p  Y���M�Y�|u��dv)W�$���Y�E�u#�E�9E���   �u����   ��4����E��} �u�~5�}�]�E+߉E�4�d	V�7��X  ������ F�Mu�;u�u�& ��f� �5��E�9E�t�u���Y�u��m  Y�M�P�u��X���4���9E�t�u���Y�M�E�_^[d�    �� U���hV�E�WP�u�d	����p  @Y@Y��dvP�$���Y��u�N�u��u��d	V�u��X  �$0 ��� tj j�����V�gl  YPV���L��E�;�tV��Y��_^�� U���V�E��u��h�VjP�(����E��P�J�����^�� �.���m  QSV�5T�3�WS�jW��+�t!HtHtDH3��Dj[SSW��;�t3j �P���jL��m  Y�E�;É]�t	���$   �3�jjW� �֡ �M�_^[d�    �øK��^m  QQSV��WV�u��h��E�3��^WW�ˉ}���2  �C�{�E�^$WW���E���;  �C�E�WW�{W�F0�~4�~8�~<W�~D�~H�\��M�F@��_^[d�    ��QSVW���_�3;�t�Ƌ6P�D$P���  ���w�l  �g �g Y_^[Y�QSVW���_�3;�t�Ƌ6P�D$P���  ���w�sl  �g �g Y_^[Y�QV��FP�D$�Tl  3�Y�F�F�F^Y�QV��FP��D$QP���   �v�&l  �f �f Y^Y�V��F� P�H����P�Q��k  �NY^�j�*l  Y�L$��u�ȉ�L$��u�ȉH� j�l  Y�L$��u�ȉ�L$��u�ȉH� V�t$W���vV�_   �F�H��H��t�T$���L$�G_^���� V�t$W��;t$t�Ƌ6P�H����P�Q�Pk  �OY�ۋD$_�0^� j�rk  Y�L$��u�ȉ�L$��u�ȉH� �D$V��W�H��8P���P�Q��j  �D$�NY�8_^� �D$V��W�H��8P���P�Q��j  �D$�NY�8_^� �   �   Q�D$�P3��T�X�\Y�hd�|j  YùP��  �   �   Q�D$j �`�`���Y�hSd�Cj  Y�j�`���øi��Ij  ��,S3�9]�  �E�0�  ���Y�k  VW�=T�4@P�Eh�f�0�����D>�T9\�Dt7�8�E�   �MȍM�Q�E�   �]ԉ]��E�   �E��  �0� ��=TSSjS�\��D>�T9\��   �`S�M�E�����l��M��0Sh`�D��T�]�Ƌ@;�u�T�P�M������T�M��t�$���hp��M�����h��M������EԍM�P�o   SS�5@�E��E�P��������MԈ]�j����M��j�M�����Tj��t�x��T�t�h��T_�\^�M�[d�    �� U��Q�e� V�uW��j �Ί�����l����0j W�D���_^�� SVW3�3��T��t:�Xj+�[���;�s)��D��u�T��t$P�����tG����������_^[ø���h  �� �TS3�V;�W�  �Xj+�Y����u;���   �EHt?Ht5Ht+Ht!�}�   r�}�   w�4�"jxX��   ����� U������x��`S�M�E�����l��M��0Sh`�D��T�4v��Ɖ]��@;�u�T�P�M������T�M��t�&���W�M������u�M������EԍM�P�w���SS�5@�E��E�P�������MԈ]�j����M��j�M����3��M�_^[d�    �� j����U���SV3�W95DtVh����};�uVh���u�d	���  ��jX��   j[Shqj�l���u�d	Vh���u���  �   �E�D�@P�d	��,  �E�u%0  �8�^d  YYP�`�u�X�;�~M�u�}�E�>j �M�E����W�*d  YPW�M��X��E�PP�  S�M�������Mu�3�hHVVhiVV�t�;ƣ<uV���P�u� ��������3�_^[�ø���e  ��@�E�S3�VW�Eĉ]ȉ]̉]Љ]��]�3��T;�t@�Xj+�_���9E�s.��D;�u�T��E�E�P�M��E�ad�  �E��붍E�M�P�]�]���  �u���;���   9@��   �E�S�MԈE������V�c  YPV�M��X�h4��M��E��������P�M�����h��M�������E��M�P�����SS�5@�E��E�P�w������M��E�j���j�MԈ]�����M���M��  �M�_^3�[d�    �� jX�U����u�������Yuj{��3��Ë8�@�M�M�M�M�M��M�M�E�   �M��M�M��M�Q�T�t�� ����t$�]������Yu�d	j hX��t$���  ��jXËT�@�D���tP�d�3��SV��W�^�~;�t���   �����v�cc  3�Y�F�F�F_^[�j�����t$j�q�4   � QV��FP�D$�(c  3�Y�F�F�F^Y��t$j�q�V  � U���SV��Wj�}�^�F+�Y����]�;��  �N��t��j+�[���;���r�߅�u3���E�j+�Y���Å��E�}3��@��P��b  �^Y�E�E;]tS�u��  �EYY����]��v�}��uS�  Y���M�Yu�M�^����M;ˉMt�E�u�u�  �E�E9]YYu�F�^;؉Et���������;]u��v�b  �E��VY�M�@�ҍ��Fu3���Fj+�[���ǉN�@���F�  �Ë]+�j�Y��;�s~��]���E��;]�t �E�u�u��  �E�E�EY;E�Yu�Fj+�Y���+��ǋ~t�E�uW�  Y���MYu�~;�t�u����  ����E�F�   ��v�M��<�����M+�;��Et ��EP�u�c  �E�E�EY;E�Yu�F�E+�;�t��E�m���MP�E�[  9]u�;؉Et�u���B  ��;]u�~_^[�� U��QQSV��W�}�N�F+���;���   �V��t��+���;�r�ǅ�u3��+�������E�}3���P�`  �ЋFY�U�;Et��t
��
�H�J���������v�M�}��t
���Y�X���Mu�F����9E�E�t"��+�+�E��t
���H�K����;Eu�FP�E��_  �E��VY�M��ҍ��Fu3���F+���ǉN���F��   �U��+���;�sv����;щ]�t"��+Ӆ�t���Z�X�]����;�u�U�F��+���+��Mt�}��t
�9�8�y�x���Mu�F;�t�9�:�y�z����^�k��vg�����ى}+�;�t��t�8�;�x�{�}������N��+�;�t�X�����;�X�Yu�;�t�E���X�Z��;�u�~_^[�� ����^  Q�M�M��e� ��t�u�8   �M�d�    ��ál�VW�|$�0��j W�D��G�F�G�F��_^� VW�|$��j ������l����0j W�D��G�F�G�F��_^� ����%^  QQV���]   ��tV�t��~,>r3��9�E�E�E�E��F(�N$�e� �U� RP�EP�]  V�p��v@�d�jX�M�^d�    �� VW��3�9~Du�FHPWVhzuWW�<����FD3�9~D_^���U��V��V�t��N(�;�t;�P;Uu�U;Pt� ��P�EP�N$�]����M��t���E�EP�N0�  V�p��v@�d�^]� ����]  ���EVW��j j �M�E��%����e� �E�e� W�t��G(�0;�t"�N�F;MuP�E��u�M�P�M  �6;w(u�W�p��E�3��0;�t��u�EP�V�6Y;u��u�M���M�������M��_^d�    �� ����z\  ��$�E�M��e���e��S�ىE�������tHVWS�t��u�}Х��E���E��C�K�e� �UЋ RP�EP�i  S�p��s@�d�jX_^�M�[d�    �� U����E�e� �e� SVW���E�W�t��G�0;�t.�^�E�P���.   ��t�E;Ct�6;w�ݍEVP�O����W�p�_^[�� �D$�P;t�Au�P;Qt�Au�@;At
�At3��jX� ���\[  ���EVW3���VV�M�E��>����E�u�W�u��t��G�0;�t*S�u�^��������tS�E��u�M�P�K  �6;wu�[W�p��E�3��0;�t��u�u�V�6Y;u��u�M���M�������M��_^d�    �� �$��Z  ��4�E�S3�VW��E܉]��]�]�]��=��jSS�E�SP�ׅ�t8�E���P������u�}��	  �E�P����E�P���jSS�E�SP���u�M��u��M  �F@�M�P�u��  V�t��~4;~8t���P�;�t�j�P����F8�V4�N0PR�  �F(�8;�t�G�M܉E�E�P�  �?;~(u�V�p�9]�u3��	�}�+}���h�   j�S�u�W��;��	���;�����v;�r=�   v!�ǀ   ;�sP�M��|   �0���E�����������t
������u��j^�M���M��0   �M��_^[d�    �ËL$�u���� ���t$j�q��  � QV��FP�D$��X  3�Y�F�F�F^Y�V��W�|$�F��t�N+���;�w���  �F��_^� �t$j�q�2  � S�\$VW�s��S�����t$���s�F�0�FP��  �D$�GYY�0_^[� S�\$VW�s��S�����t$���s�F�0�FP�  �D$�GYY�0_^[� U��Q�EV�u;�tW�>���8��;�u�_�Q�A�E�U^]� SV�t$W�t$���_jV�q  �G+���_��^[� U��Q�EV�u;�tW�>���8��;�u�_�Q�A�E�U^]� �9��W  ��0�E�Vj �M��E�������V�U  YPV�M��X��e� �E�P�M�������h(��EčE�P�W  ^U��QSV��W�}�N�F+���;���   �V��t��+���;�r�ǅ�u3��+�������E�}3���P�6W  �ЋFY�U;Et��t��
���������v�υ�t�]����Iu�F����9E�E�t��+�+�E��t������;Eu�FP�E�V  �E��VY�M�ҍ��Fu3���F+���ǉN���F��   �U��+���;�sn����;щ]��E�t#+Ë]��E��t� ��E����;��Eu�]�F��+���+��Mt�}��t�9�8���Mu��F;�t	�9�:����^�W��vS�����ى}+�;�t��t�8�;�}������N��+�;�t�X�����;u�;�t�M�	�
����~_^[�� U��QSV��W�}�N�F+���;���   �V��t��+���;�r�ǅ�u3��+�������E�}3���P�fU  �ЋFY�U;Et��t��
���������v�υ�t�]����Iu�F����9E�E�t��+�+�E��t������;Eu�FP�E�T  �E��VY�M�ҍ��Fu3���F+���ǉN���F��   �U��+���;�sn����;щ]��E�t#+Ë]��E��t� ��E����;��Eu�]�F��+���+��Mt�}��t�9�8���Mu��F;�t	�9�:����^�W��vS�����ى}+�;�t��t�8�;�}������N��+�;�t�X�����;u�;�t�M�	�
����~_^[�� �D$��t�L$VW��������I_�H^ËD$��t�L$���I�H�U��EVHH��   -  tZ��t,-�|  t�u�u�u�u����   �u����M��M�9Eu�E��h��td�u�uh  P����P�u�~ tj j �u�FP��������6��t.�u�uh  V�ȋu�6�u�����t���   V�R  Y3�^]�j������U��QVWj��R  ��Y��t�E�Nj �����3��u�& �~�P  YP���u�X��E�PVh,{�u�t�������t��tj�����V�9R  YjX��d	�u����  ���   P�u���3�_^���t$���3���   �
   �p�  h�|��Q  Yùp��  U���(V�E�u���̉e�P�u����u�M��u�T   �M��  ��uP�d	h���u���  ��j^��d	�u����  ���   P�u���3��M��O  ��^�øU��\Q  QV��u��u �e� �EP�A   �E�f �F�E���E��F ����  �M��j�M����M��^d�    �� �l���P  QS�]VW���j �}��w�Έ����l����0j S�D��E�e� ���GtP�d	��,  Y�M������_^[d�    �� �A�V���o   �D$tV�pP  Y��^� U���,j �E����̉e�Ph����j j �M�������E�p�E�E�P�EP�  ��t�M��>  �M��   3���V��~ ���tf�FP�x����
���^�VW�|$��;�tW�   �G�ΉF�G �F �`   ��_^� �l�SV�t$W���0�F�Oj P�D��^�w;�t(���tP�d	��h  Y����tP�d	��,  Y��_^[� U��� V��~ tf�FP�x��F��u9F t(�v Ph  �E�jP�(����E�P�|����F^��U��Q�=� VW���  uy����������   h  h����f�������   ��Whp��M�����tv��h�  h���4�����t]��jh$�������tG��   ����P�E�j �E�VP�p�E  ��u����P��Pj W�   jX_^��3���U��SVW��������tO�u�5 ��u�u�wH�օ�u2�P�j���u�u�u�wH�օ�uj
���u�u�u�wH�օ�tjX�3�_^[]� �=� t��P��Pj h�  �v���jXø���M  ��,V3�V�E���̉e�Ph����VV�M��-����E�p�u��@�E�E�P�EP�V	  ��tVV�u܍E�P�X������M���M��8����M�jXd�    ^�ø���:M  ��,V3�V�E���̉e�Ph����VV�M������E�p�u��@�E�E�P�E�P��  ��t�u��u��u�V�X��M���M������M�jXd�    ^��U��Ej �p�@�E�EP��  ��t�uj ���jX]�jX�U����E�xt3���VW�p�k   ���w;wt��E��  �E��E�P����Y����_3�^��U��Q�E�V��f ��E��F�  �FP�h���^��V��FP�L����m   ^�U��QQSVW��j�!L  Y3�;�t�U��H��H�H���3ۍ~W�t��N�;��E�t����P�   �M���   �E�;Fu�W�p�_��^[��U��QV��FP��E�QP���Y   �v�lK  �f �f Y3��M������u�5��%� �M������tV�0K  Y^���t$j�q�  � U��QV��M�~ t8�F;u19Eu,�p���'  �F���H�F�f � �F�@�F��%;Mt W���M�   �E�WP���I   �M;Mu�_�E^��� �V�5��B;�t
�;�t�����B�;Pu��@��9Bt�^ø���rJ  ��S�M�VW�}�M�����7���_;��}�]�u�3��;�t�;�t�����q�A�M�E�M�����E�e� ;�tc��A��;u�F��H�U�N�H�1��
��A�]��K9yu�A��O99u���A�O�}�H�W4�H4�P4�O4���   �H�U��N�J9yu�q��O99u�1��q�R�U�9:u$��9u�O�
����;�t�ڋ���M��M��Q9zu%��9u�O�J��^��;�t���_���z�]�j_9x4�  �C;p��   9~4��   �F;0u4�@�x4 u�x4�F�˃`4 �v�  �F�@�9y4uF�H9y4u>�0� �x4 u�x4�F�˃`4 �v�  �F� �H9y4uS�9y4uL�`4 �v�t����H9y4u�P�y4�`4 ���~  �F�@�N�I4�H4�N�y4�@�ˉx4�v�  �<�9y4u�HP�y4�`4 ����  �F� �N�I4�H4�N�y4� �ˉx4�v�  �~4�M���M�����u�N�����V��G  �E�KY_�M^��M�[d�    �� SVW�|$;=��ً�t%�v��������6�O��  W�G  ;5�Y��u�_^[� U��QQSVW��j8�G  Y��3ۍM��^�F4   �u����9�u�5�����]��X���M����9]�t	�u��-G  Y�5�j8�YG  �p�X4�G�_� �GY_^�@[��U��QSV��W�}�N�F+���;���   �V��t��+���;�r�ǅ�u3��+�������E�}3���P��F  �ЋFY�U;Et��t��
���������v�υ�t�]����Iu�F����9E�E�t��+�+�E��t������;Eu�FP�E�?F  �E��VY�M�ҍ��Fu3���F+���ǉN���F��   �U��+���;�sn����;щ]��E�t#+Ë]��E��t� ��E����;��Eu�]�F��+���+��Mt�}��t�9�8���Mu��F;�t	�9�:����^�W��vS�����ى}+�;�t��t�8�;�}������N��+�;�t�X�����;u�;�t�M�	�
����~_^[�� �T$V�B�0�r�0;5�t�V�r�p�I^;Qu�A��J;u���A��B� �T$V��p�2�p;5�t�V�r�p�I^;Qu�A��J;Qu�A���P�B� ����������D  QQSV��W�e��u�~W�t��u�e� �E��P��   �F�U;�t#�M��t	��R�k����u�E��P�����j^�3�W�p��M��_^d�    [�� �E��P�p�j j �ED  ����D  QQSV��W�e��u�~W�t��u�e� �E��P�Q   �v�E;�t�Mj��^t��P������3�W�p��M��_^d�    [�� �E��P�p�j j ��C  U��QVW�}��W�)   �v�E;�t�;H|�E��u��E���E_^��� �A���H;�tV�t$�69q}�I����	;�u�^� ����*C  ��SV��W�e��u�~W�t��u�e� �E��P�e����F�M�;�t$�} t��Q�M������M��u�������j��u���=   �u�������j^W�p��M��_^d�    [�� �E��P�p�j j �B  ����B  ��\S3�VS����E�̉e�Ph����SS�M�������MP�]��	�M��M��@   �E���P�E�P�E��   �M��]������M���M�������E�M�^��d�    [�� ����A  ���EV��Wj �M��u��E������W��?  YPW�M��X��e� �E�j P������j�M��E�����E�f �H�N�@ �ΉF ��������M��_^d�    �� U��QSVW������G�؋p;�t�U�ދ;V��t�6��v�� t
�u�ESV�2�˄҉M�t;u
�u�ESV��M��  �M��E�Q;}PSV�EP���   ��E��@�	�E�` �_^[�� U��SVW��j8��@  �u���u�g4 �w������G�GP�W  ���C;st%�E;�u�E� ;F|�~�C;pu�x��>�C;�u�x�C��;0u�8�C��;x��   �F�x4 ��   �P�
;�uV�J�y4 ujZ�P4�Q4�F�@�`4 �F�p�g;pu
����V�����F���@4   �F�@�`4 �F�p������5�y4 t�;0u
����V������F���@4   �F�@�`4 �F�p�g����C;p�S����C�@�@4   �E�8_^[]� �V�x4 u�P9Bu�@�^Ë�5�;�t�P;�u���@�;u܉����??  Q�E�E��e� ��t�M���Q�H������M�d�    ��U��EHHt.�u-  �ut�u�u���]��u�u�u�.   ��]�V�u�F$��tP�����t���%  V�>  Y3�^]ø9��>  ���   SVW�}3ۍM�S�E�����l��M��0SW�D��M�]���uhh �M������t  � �  ;�t���  ��  �u�V;W�  ;ȸX t�@ P�M��w����FHH�	  H��   HH�N  ��jh�W�=  ����t�FjPW�=  �����   h( �M��"��������j(P�FP�4��=��;�t"SS��T���h�   QP�����PSh��  ��;�u��T�����]Ӎ�T����M�P�����SS��T���h�   P��j�VSh��  ���-h �M�����SS��T���h�   P��j�VSh��  ���;�u��T�����]Ӎ�T���P����h �M��V����v�M�������FP�M�������EԍM�P�.���SS�u�E��E�P�������MԈ]�j����M��j�M�����M�_^3�[d�    ��j����U���$SVWj(�<  ��Y��t�Ej �ˈ����3��u�:  YP���u�X��E�c$ �{���C�E���PS�h���u��9�������t����   j�����S��;  Y�yj^9uuyj �E�_Wj P�.:  3Ƀ�3�9M�}܉u�t�u�}襥�����	;�rgu9�	t]jXP�E�P�u������u!P���P�u�������u����jX�"�C$�d	�u����  ���   P�u���3�_^[�ád	Qh| �u���  ��t$���3���   �   h�  ����  �h����:  Yù���  Vj�1;  ��Y��t%�t$���t$�[   �t$����P�Y�F�3�V����  ��u0��t���i   V�:  Y�d	j h� �t$���  ��jX^�3�^ËD$V����FtP�d	��,  Y�|$ ���t�t$�P�Y�3��F��^� V��F�����tP��Y���   ^�V��F�����tP��Y�v��t�d	V��h  Y^ø]���9  ��HSW��3�9_��  Vj �E�SP�8  �E�w���M��E�   �E�S���V��7  YPV�M��X��w�M܉]�������	�w;�uS�����	�M�Q�M�Qh�V�Ћ�V���;�th� �M�����V�M��8����   hxM�M������E�S�M̈E������V�P7  YPV�M��X��E��E���;�t2�x�Hu�xu�f�9u��q���P�M��@����E�@�E��ʋE�;�u�T�P�M�� ���;�t�	;�uj������	V��j�M̈]�����E̍M�P������SS�E�WP�E��t������M̈]�j����M��j�M����^�M�_[d�    ��Vj�t8  ��Y��t%�t$���t$�����t$� ��P�Y�F�3�V���4  ��u0��t���)   V��7  Y�d	j h �t$���  ��jX^�3�^�V��F� ���tP��Y������^øy��7  ��X  SV��3�9^�J  �E�W�~S�M��E����W�5  YPW�M��X��v�M��]������vf�E� �]�f�]��������E�u*h`��v�5  Y��Yth� �M��}���h,�   �	;�uj�"����	j�M�j Q������h  Q�M�jQ�Ћ�W���;�th� �M��(���W�M������8hxM�M������v������P�4  Y��Yt	������P�h��M�������E��M�P������vSS�E�VP�E��c������M��]�j����M��j�M����_�M�^[d�    ��V���t$�& �N�8   ��^� ����6  V��F4P�t��L$��N�@   �L$^d�    ��U��Q�E�V��P�M   �F0P�h�3�P�uPP����FH��^�� V���vH�h��fH �F0P�L��~, t	���4   ��^Ë��L$�	�3ɉH�H�H�H�H�H�H�H �H$�H(�H,� �A�I,�At;Au�   �U���S��VW�C�H�K�0�(5  3�Y9C,u+�{�u��E��E�E��E������{�u��s$����4  Y�#�C�{�u��E���M���   �M��M�����_^[��SV��W�^4S�t�3�9>u&VWVh|�WW�<���;�t	P�h���>9>t�D$�NP�   ��uj_S�p���_^[� ����s4  QV��W�~0W�}��t��e� j j�vH�<���t�u���)   3��j^W�p��M��_^d�    �� �1�p��V��~, t7�N�V;�t-�A;Fu��t�D$� ����3   �*��t&�D$� �����   �F���H�Nt�L$�	��F,^� U���SVW��h   ��3  �{, ��Y�u�uI���C(   ��   �C$�{�p�C$���E���M��   ��   �M��u�u쥥���{�u��   �K(�S$�C �L��;�s'���u�C �{�0�C �E��u��M��   �M��V+C����@���?P�d   ���{�E��1��U��   �U��S�u�U�������M��E�   �E��E��E�{�u쥥��_^[��V��F(��y3�P��2  Y�F$^�U��QS�]��V����W��}3�P�2  ������Y�N���E��ЋF ��;�t������;�u�]�v$�;2  �E�Y�~$�^(_^[�� �L$�   � U��QSVW���e� �E��_h`�  P���R   ��u"�M���t���M��ɋ�t�����V��1  Y�Íw4V�t����   �؅�t�' V�p���t�_^3�[�ø���1  ��S���u�sH�x���t=  t`j�^�C0VP�E�t��e� �{, u�d	h4�PYj^�#�E��tW�s�}䥥���M�_�	��������3��u�p���^�jX�M�[d�    �� V��W�~0W�t��v,W�p�����_^���U��Q�	V��t�j�j�1  ��Y��t!�u�E����̉eP�u������   �3��	�E�	3�^�ø���0  V���u�e� �EP����jh�����l��M��j�M����M��^d�    �� 3��V���   �D$tV�00  Y��^� V��j h�����l����)���^Ë	��t�j��%	 3�ø����/  �� �	S3�V;�W�  �E+�t.Ht$Ht��tH��   ����������|��t�E�P��   �@A�]�V�-  YPV�M��L�W�-  YPW�M��L��ES�M�E��d��	�M�Q�E��5	�@P�E�P�4�������uB�E�;�u���j
SP�D��������j�M�]����d��M��j�M�������j�M�]��d��M��j�M����3��M�_^[d�    �� U��Q�A�e� V�qW�}j �ψ����l����0j V�D���_^�� jX��   �   �%	�%��hL��J.  Yù%	�%|��   �   �$	�%x�hx��.  Yù$	�%t��   �
   �0	��  h����-  Yù0	�  U���VW�j  ��uP�d	h��u���  ��jX�   h�  ��-  ��3�;�YtB�u�E����̉e�P�u����u�E��u�u �u���̉eP�u������\   �3��E�����R���E�WP�E�0	P�u��  �(	VWh�  ������d	�}�V���  ���   P�u���3�_^�ø-��-  ��SV��W�u��u8�E(�E�   P������E�~3ۋ�S�E���d��\����0�ESP�`��E;�~,��_�_�_�E �ND��NH��F<�E$h 	�E��F@���  �����F�E;�~o�M�E�M �E � ;�tT���+tIIu�E$@�@�]$8t9�u$�U;���̉eRP����M��T   P���E��
  j�M��E�����E �Mu�j�M�]��d��M��j�M(����M��_^d�    [��4 �A���+  V��E�e� j �����l����0�Ej P�D��E�M��j�M�F����M��^d�    �� �A�V���   �D$tV�l+  Y��^� �`��i+  QV��u����N,�E�   ��  �e� j�N�d��M�����B����M�^d�    ��j�����  ��uP�d	h��t$���  ��jX��t$�(	j h�  ����3��SV����W9^H��   9^D��   �F 3�;�u���Wh   BjWjjP���;ÉFHu������  �ZWWjW�\�;ÉFDu����vH���  �h��.�(	Phަ�%�����u �vD���  �=h����vH�^D�׉^H3��jX_^[øt��*  ��V���P�E��E�j P�0	�8  �FD���ujX�%�u��E���e� �M�Q�(	Phަ�B���3��M�^d�    ���(���D$V���(�tV�)  Y��^� V��j��)  ��Yt� (��N�H� �^�3�^�V��N��t�   �N��t�j�^�V��W�=h��FH���tP�׋vD���tV��_^�V���l����D$tV�)  Y��^� V��3ɍ��  QPhX	�v@�VD��FL�v<���  ���  ���  h@  P�vH���  �����tjX^�������  3�^�U��QQ�EV�0	�@�ΉE��EP�E�P�Z  ��tv�M������u<�Mh�7  �M��P�E��E�j P���  �M�����M��t6�j��.�M�)�����u"�Mh���  �u��(	j h�  �����jX^��U��Q�E�0	�@�E��EP�E�P�  ��t�M�������t�M��t�j�jX��U��E�0	P�u�  ��t%�Mj j ��P�M������u�Mh��V  jX]�jXÃ=(	 u\藹�����(	tDh�  h�����������t/�(	h�  h���������t�(	jh��������u
�%(	 3��jXËD$�xt3��V�0	W���*  �΋��  �w;wt����������_3�^ø����&  ��H  SVW���E�j P���  P�wL�wH�������  �e� �E�P��������؊�e� j �MԈE�����l��M��0j S�D�j�M��E�����M�D9L;��`  �F���  ���   �T0�LL;���   3ۍ�����SSh  Q��P�FPSh��  ���;���    �����������P���3  ����   �FHt9Ht-Ht!HtHt	�E��+�E��"�E�t��E�h��E�`��E�X�������MĉE��E�Pj螵��9]��E�t�E�;�u�T�P�M��ж���E�j�M��E�����;�t�M���DL;������3�9]�~J�EčM�P萼���u��E��E��uWP�������Mċ��E�j����M��j�M�������%�M��j�M����3�����3�=�  �����M�_^[d�    �� SV��W�N0��t�F4j+�Y�����ujX�_3�3ۋN0��tR�F4j+�Y���;�sC�F0Ë@��u�T�jP�t$�d	���  ����uG��뺋N0��3�8T����3�_^[� ����9$  ��P  SV��3ۋF;���  �EWS�MԈE�����u�1"  YP�M��u�X����  �]�;�tuP�ǈ��;�Y�EtgSS������h�   Qj�PSh��  ���;�t<��������W��!  YPW�M��L�������P�!  YP������P�M��L��u��Y�E���P�������S�M��E��E�����l��M��0SW�D�j�M��E�����ES�M�E������W�E!  YPW�M��X�����E��PP�M������E�_;�u�T�P�M��?����E�;�u�T�P�M��*����E��M�P�����vSS�E�VP�E�訬�����M��E�j^V���V�M��E����V�MĈ]�����M��V�M�����M�^[d�    �� SV��W�^�~;�t���*��������v�5"  3�Y�F�F�F_^[��t$j�q�?  � U��Q�E�V��f ��E��F�_  �FP�h���^��V��FP�L����   ^�U��QQSVW��j��!  Y3�;�t�U��H��H�H���3ۍ~W�t��N�;��E�t����P�   �M���  �E�;Fu�W�p�_��^[��V��W�~W�t����  W�p�_^�U��QV��FP��E�QP����  �v�)!  �f �f Y3��M�����`	u�5\	�%\	 �M������tV��   Y^���t$j�q��  � U���SV��Wj�}�^�F+�Y����]�;��  �N��t��j+�[���;���r�߅�u3���E�j+�Y���Å��E�}3�����P�   �^Y�E�E;]tS�u�  �EYY����]��v�}��uS�  Y���M�Yu�M�^�����M;ˉMt�E�u�u�U  �E�E9]YYu�F�^;؉Et���������;]u��v��  �E��VY�M���ҍ��Fu3���Fj+�[���ǉN�����F�O  �M��+�j�[��;���   ���M��;M��t#�E��u�u��  �E�E��EY;E�Yu�M�Fj+�Y���+��ǋ~t�E�uW�  Y���MYu�F�};��E��   �l����0j �u�D��E��;}�@�G�u��   ����   �E��������E+�;�tW�u�  �E��;}�YYu�M�~�}+�;�t+�l��m�M���0j W�D��M�G;}�Au؋M���;ȉEt%�l����0j �u�D��E��;}�@�G�u�^_^[�� U��QV��MW�~ t[�F;uT9EuOS�X�\	��;�t�w���B  �?S�
  �\	Y;���u�N[�A�F�f � �F�@�F��E��%;Mt���M�0   �E�WP���Z   �M���E�_^�� Q�AP��D$RP�W���YËV�5\	�B;�t
�;�t�����B�;Pu��@��9Bt�^ø���k  ��S�M�VW�}�M�����7�\	�_;��}�]�u�3��;�t�;�t�����q�A�M�E�M�����E�e� ;�tc��A��;u�F��H�U�N�H�1��
��A�]��K9yu�A��O99u���A�O�}�H�W�H�P�O���   �H�U��N�J9yu�q��O99u�1��q�R�U�9:u$�\	9u�O�
����;�t�ڋ���M��M��Q9zu%�\	9u�O�J��^��;�t���_���z�]�j_9x�  �C;p��   9~��   �F;0u4�@�x u�x�F�˃` �v�  �F�@�9yuF�H9yu>�0� �x u�x�F�˃` �v�  �F� �H9yuS�9yuL�` �v�t����H9yu�P�y�` ���m  �F�@�N�I�H�N�y�@�ˉx�v�  �<�9yu�HP�y�` ����  �F� �N�I�H�N�y� �ˉx�v�
  �~�M���M�����u���  �E�KY_�M^��M�[d�    �� SVW�|$;=\	�ً�t�v��������6W�  ;5\	Y��u�_^[� U��QQSVW��j��  Y��3ۍM��^�F   �u����9\	u�5\	��\	�]��X�`	�M����9]�t	�u��7  Y�5\	j�c  �p�X�G�_� �GY_^�@[��U��QSV��W�}�N�F+���;���   �V��t��+���;�r�ǅ�u3��+�������E�}3���P��  �ЋFY�U;Et��t��
���������v�υ�t�]����Iu�F����9E�E�t��+�+�E��t������;Eu�FP�E�I  �E��VY�M�ҍ��Fu3���F+���ǉN���F��   �U��+���;�sn����;щ]��E�t#+Ë]��E��t� ��E����;��Eu�]�F��+���+��Mt�}��t�9�8���Mu��F;�t	�9�:����^�W��vS�����ى}+�;�t��t�8�;�}������N��+�;�t�X�����;u�;�t�M�	�
����~_^[�� �T$V�B�0�r�0;5\	t�V�r�p�I^;Qu�A��J;u���A��B� �T$V��p�2�p;5\	t�V�r�p�I^;Qu�A��J;Qu�A���P�B� ���  Q�M�M��e� ��t�u�   �M�d�    ��VW�|$��j ������l����0j W�D��G_�F��^� ���Y  ��SV��W�e��u�~W�t��u�e� �E��P��  �N�E�;�t�M��t�P��Mj�	�H��u���  �Mj�	�^W�p��M��_^d�    [�� �E��P�p�j j ��  ���  QQSV��W�e��u�~W�t��u�e� �E��P�c  �F�M;�t�E��t�Q��EQP�������j^�3�W�p��M��_^d�    [�� �E��P�p�j j �c  �(��3  QQSV��W�e��u�~W�t��u�e� �E��P��   �M;Nt�Ej��^t	�I��3�W�p��M��_^d�    [�� �E��P�p�j j ��  U��QSV��W3ۍ~W�t��F�;ȉM�t2�A��t
�U�@D;t�M�������M�;Nu���Ej��[t�I�W�p�_��^[�� U����E�e� � �E��E�P�E�P�D   �E����� U��QVW�}��W�  �v�E;�t�;H|�E��u��E���E_^��� U��QSVW���\	��G�؋p;�t�U�ދ;V��t�6��v�� t
�u�ESV�2�˄҉M�t;u
�u�ESV��M��  �M��E�Q;}PSV�EP���   ��E��@�	�E�` �_^[�� U��SVW��j�x  �u���u�g �w�\	��\	�G�GP�  ���C;st%�E;\	u�E� ;F|�~�C;pu�x��>�C;�u�x�C��;0u�8�C��;x��   �F�x ��   �P�
;�uV�J�y ujZ�P�Q�F�@�` �F�p�g;pu
����V�:����F���@   �F�@�` �F�p�]����5�y t�;0u
����V�G����F���@   �F�@�` �F�p������C;p�S����C�@�@   �E�8_^[]� �A�\	�H;�tV�t$�69q}�I����	;�u�^� �V�x u�P9Bu�@�^Ë�5\	;�t�P;�u���@�;u܉��D$��t�L$���I�H�U���u�}  �uu�u�u�u�   ��]��u�u���]øE��M  �� SV�u3�S�M��E�����l��M��0SV�D��E3����]�w7t.+�t%HHtHHtHH��   �,�D� �=��6j^�x���*��	t HtHt��ua�����������;�tCP�M�������u�M������EԍM�P����SS�u�E��E�P�s������MԈ]�j����M��j�M�����M��^[d�    ��U��QVj�n  ��Y��t�Ej �Έ����3��u�H  YP���u�X��E�PVh*��u�q������t��tj�����V��  YjX��d	�u����  ���   P�u���3�^���t$���3���������������QV�t$W3�V�|$�   ��;ǣd	u_3�^YËT$�L$Q�L$RQh@V�P��;�u_3�^YËL$�d	�Q;�t$�_�h	�Q^�R�l	�I�Q�p	YÉ=h	�=l	�=p	_^YÐ�����������L$�A��t�8Ϻ��t�D�A    3�Ð�������������% ��%��%��%��%��%��%��% ��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%|��%x��%t��%p��%l��%h��%d��%`��%\��%X��%T��%P��%L��%H��%D��%@��%<��%8��%4��%0��%,��%(��%$��% ��%��%��%��%��%��%��%��% ��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���% ��%��%��%��%��%��%��%��% ��%$��%(��%,��%0��%4��%8��%<��%@��%D��%H��%L��%P��%T��%X��%\��%`��%d��%h��%l��%p��%t��%x��%|��%���%���%���%���%p��%��%��%��%��%��%h��%l��% ��%d��%`��%\��%X��%T��%P��%L��%H��%D��%@��%<��%8��%4��%0��%,��%(��%$��% ��%��%��%��%��%��%��%��% ��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%|��%x��%t��%p��%l��%h��%d��%`��%\��%X��%T��%P��%L��%H��%D��%@��%<��%8��%4��%0��%,��%(��%$��% ��%��%��%���%���%���%���%���%���%���%���%\��%X��%T��%P��%L��%H��%D��%@��%���%P��%T��%t��%x��%|��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%`��%d��%h��%l��%p��%t��%x��%|��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%��%p��%l��%h��%d��%`��%\��%@��%��%D��%��%��% ��%���%���%��%<��%8��%4��%0��%,��%(��%$��% ��%��%��%���%���%<��%8��%4��%0��%,��%(��%$��% ��%��%��%��%��%��%��% ��%��%���%���%���%���%���%���%X��%���%���%���%���%���%���%���%���%���%���%���%|��%x��%���%���%���%���%���%|��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%|��%x��%t��%p��%l��%��%���%���%��%��%h��%��% ��%���%���%���%���%���%���%���%���%���%|��%x��%t��%p��%l��%h��%d��%���%`��%p��%<��%8��%4��%0��%,��%(��%���%���%���%���%���%���%���%���%���%���%���%���%���%(��%,��%0��%4��%8��%<��%@��%D��%H��%X��%L��%P��%T��%0��%X��%\��%`��%d��%h��%l��%T��%L��%P��%��%H��%D��%@��%<��%8��%4��%,��%(��%$��% ��%��%���%���%���%���%���%���%���%x��%\��%d��%h��%`��%���%���%��%��% ��%��%��%��%��%��% ��%���%���%���%���%���%���%t��%(��%$��% ��%��%��%D��%��%��%��%��%��%,��%0��%4��%8��%<��%@��%H��%T��%L��%P��%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%���%,�����Q=   �L$r��   -   �=   s�+ȋą���@P���%(��%$��% ��%��%��%��%��%��%�����������SV�D$�u�L$�D$3���؋D$����A�ȋ\$�T$�D$���������u�����d$�ȋD$���r;T$wr;D$vN3ҋ�^[� �������̋D$�L$ȋL$u	�D$��� S��؋D$�d$؋D$���[� �����������̀�@s�� s����Ë�3Ҁ����3�3��̀�@s�� s����Ë�3������3�3����%���%���%���%���%�����%���%���%���%���%���%���%���%���%���%`��%���%���=@
�u�t$�L�Y�h<
h@
�t$��  ����t$��������Y��H��%���%����j�Pd�    P�D$d�%    �l$�l$P���%0��%4��%8��%<��%@���� ��� V���m  �D$tV����Y��^� ��� �%D��D$��u9t	~.�t	�\����	�4
u?h�   �$���Y�@
u3��f�  �@
h,@h @�<
��   �t	YY�=��u9�@
��t0�<
V�q�;�r���t�ѡ@
����P���%@
 Y^jX� U��S�]V�uW�}��u	�=t	 �&��t��u"�8
��t	WVS�Ѕ�tWVS������u3��NWVS�_   ���Eu��u7WPS�������t��u&WVS�������u!E�} t�8
��tWVS�ЉE�E_^[]� �%H��%T��%X��|$u�=8
 u
�t$��jX� ���%���%|��%x��%t��%p��%���%h��%d��%`��%X��%P��%L��%H��%D��%���%���%���%���%���%���%���%���%���%��%P��̋M��q����M���醐���M���$鳐�����L����M����%p��@��6����̍M��%h��h��!�����u�����Yø�������M��{����M����%p����������̋M��[����M����%p�� �������̍M�%h��P�����̍M��%p��M��%p��x������M��%p����������u��z���Yø���t����M��q����M��醏��� ��W�����̍M��y����M��%p��0��9���̍M��]����M��%p��`�����̍M��՘���M��9����M��%p�����������u�u��a���YYø��������M�鳢�����������̍M��!����������̍M�銢���@������̍M�������h������̍M��u�������~����̍M��%p��8��i���̍M�%p��M��n����`��M���̋M����%p�����6����̍M���������"����̍M�������������̍M��%���������̸0�������̸��������̸��������̍M�鸪���M������8������̍M��%p��M�龃���h�������u�u�����YYø�������M�驓���M��%p�����i���̍M�鍓���M�酓���M��%p�����E���̍M��i����M��%p��0��)���̋M����b����`�������̍M���������������̍M��������������̍M�%p���������̍M��%p��M��%h�� ������M(�%p��M�%h��M�鵂���M����%h��M���,�)����M��a����0��u���̍M�%p�����a���̋M��o����M����%h�����B����̍M��~�������.����̍M��%p��M��H����M��@����M��%p�� �� ����M��%p��M��%p��M������M������M��%p��H��������̍M��%�����������u�u�����YYø��������������̸@������̸���z����̍M�靑���M��%p�����]���                                                                                                                                                                                                                                                                                                                                                                                                                                                 �    0 > H � � � � � f H 6 $  � � � � � � v ` H 2  
 � � � � � � � n V > $  � � � � � � � | d D & 
 � � � � � � z f T @ .   � � � � � v ` <      � � � � � z \ @ $  � � � � b x �     �" �" �" �" �"     R n � � � � � � �  . H V r � � � � � �  . P ` | � � � � �   8 X p � � � � � � �   2 L d | � � � � � � �  2 J b v � � � � : $ 
 �
 �
 �
 �
 �
 �
 �
 �
 d
 J
 2
 
 �	 �	 �	 �	 �	 �	 �	 p	 Z	 H	 2	 	 
	 � � � � � � � z d P 8    � � � � � � h L > 0    � � � � � � � � n \ P @ 0     � � � � � � � f P .    � � � � � � � t ^ L < 0   �9 � � � �  �     �( �( �( �( ~( j(     �6 `6 6 �5 T5 �4 �4 V4 4 �3 7 "3 
3 �2 �2 �2 �9 $9 
9 �8 ^7 �7 �7 �7 8 68 l3 �8     �1 �1 �1 �1 �1 �1 �1 �1 z1 p1 f1 \1 H1 >1 41 *1 1 1 1 �0 �0 �0 �0 �0 �0 �0 �0 �0 �0 �0 �1 �1 2 "2 42 P2 f2 t2 : ~2 �2 �2 �1     �& $& & �% �% �% �% �% �% �% z% h% V% F% 6% (% % �$ �$ �$ �$ �$ �$ �$ t$ f$ R$ 8$  $ $ �# �# �# �# D& R& �& �& �& `& t& 2& �&     	  ��  ��  �B �C ��  �  ��  ��  ��  ��  �#  ��  �  �  �M  �  ��  ��  �  �  �  �    `,     l# V# �# *# # # ># �#     T" f" D" 2" t"     f0 F0 (0 0 �/ �/ �/ �/ p/ N/     �) (* <* Z* r* �* *     `- F- .- - p- �, �, �, �, �, �- �- �- �- �- . �, .     2 J �! F 6 &  � � ` p � � � � � � � �  $ 6 D T j z � � � � � � �   ( 8 �! �! �! t! `! L!  !  ! �  �  �  �  �  �  �  z  \  H  .        � � � � � � � D P b n � � � � � � � �   * @ R d r � � � � � � � � � z f T D 2    �! �! " � � � � � 0! ~ � � � � � � p Z F 2 " d �     L. `. 8.     �* 
+ �* �*     R(     �*     8  �  �  �p  �s  �7  �	  �  �o  �4  �3  �  �t  �    �. �. ./ �. �. �. / / ~.     (+ >, 0, , <+ , �+ �+ �+ �+ �+ �+ �+ �+ N+ b+ v+     ) ) ,) <) N) b) p) �) �) �) �) �) �)     6( ( �' �' �' �' �' �' x' Z' B' ,' ' ' �&  (                     ��J       j        R     �����n �n    )X��X!~~X������a�^�X%�!�ʧ�=�~�������         �      F�     �      F@;������ � >V����W���t  �חb                      �      F      �      F        �      F�����        ����        ��               ��            ���     �   (�                    ����8�    @�   K� �   `�                    ����`� �   ��   ��            ����        x�����                 ��                �Y �   ��                    ������ �   �                    ������    �� �   @�                    ������    �� �   p�                    ������ �   ��                    ������    �������� �   ��                    ����� �   ��                    ����$� �    �                    ����8�    @� �   P�                    ����X�    `� �   ��                    ����t�    |� �   ��                    ������    ��   �� �   ��                    ������ �   �                    ������ �   8�                    ������ �   `�                    ������ �   ��                    ����� �   ��                    �����    p�    ����       ��        ��    ����       ��        ��    ����        �       ������    �    � �   X�                    ����0� �   ��                    ����D�    M� �   ��                    ����`� �   ��                    ����x� �    �                    ������ �   (�                    ������ �   P�   `�            ����    ����                  x�                � �   ��   ��            ����    ����                  ��                � �    �   �            ����    ����                  (�                � �   X�                    ������    �� �   ��                    ������    �������� �   ��                    ����� �   ��                    ����(�    0� �   �                    ����D�    L�    T� �   P�                    ����h�    p� �   ��                    ������ �   ��                    ������ �   ��                    ������ �   ��                    ������ �    �                    ������    �� �   P�                    ������    ��   �   �   �   %� �   ��                    ����8� �   ��                    ����L�    T� �   ��                    ����l� �    �                    ������    ��������   ��   �� �   h�                    ������    ��   ��    ��   ��   �� �   ��                    ������ �   ��                    ������ �   �   �            ����    ����                  0�                շ �   `�   p�            ����    ����                  ��                a� �   ��   ��            ����    ����                  ��                ߸ �   �                    ����4�    <���         � �� �            � d          &" P� ��         �" �� ��         �" x� ��         �# |� |�         �& h� t         J( `� �         `( p� <�         �( (� �         �( �� <         �) (� ,�         �) � ��         �* �� �         �* x� p         + \� �         R, �� ��         r, t�           ,. � `         r. L� �         @/ �� ��         �0 �� ��         Z2 �� X�         �9 D�                     �    0 > H � � � � � f H 6 $  � � � � � � v ` H 2  
 � � � � � � � n V > $  � � � � � � � | d D & 
 � � � � � � z f T @ .   � � � � � v ` <      � � � � � z \ @ $  � � � � b x �     �" �" �" �" �"     R n � � � � � � �  . H V r � � � � � �  . P ` | � � � � �   8 X p � � � � � � �   2 L d | � � � � � � �  2 J b v � � � � : $ 
 �
 �
 �
 �
 �
 �
 �
 �
 d
 J
 2
 
 �	 �	 �	 �	 �	 �	 �	 p	 Z	 H	 2	 	 
	 � � � � � � � z d P 8    � � � � � � h L > 0    � � � � � � � � n \ P @ 0     � � � � � � � f P .    � � � � � � � t ^ L < 0   �9 � � � �  �     �( �( �( �( ~( j(     �6 `6 6 �5 T5 �4 �4 V4 4 �3 7 "3 
3 �2 �2 �2 �9 $9 
9 �8 ^7 �7 �7 �7 8 68 l3 �8     �1 �1 �1 �1 �1 �1 �1 �1 z1 p1 f1 \1 H1 >1 41 *1 1 1 1 �0 �0 �0 �0 �0 �0 �0 �0 �0 �0 �0 �1 �1 2 "2 42 P2 f2 t2 : ~2 �2 �2 �1     �& $& & �% �% �% �% �% �% �% z% h% V% F% 6% (% % �$ �$ �$ �$ �$ �$ �$ t$ f$ R$ 8$  $ $ �# �# �# �# D& R& �& �& �& `& t& 2& �&     	  ��  ��  �B �C ��  �  ��  ��  ��  ��  �#  ��  �  �  �M  �  ��  ��  �  �  �  �    `,     l# V# �# *# # # ># �#     T" f" D" 2" t"     f0 F0 (0 0 �/ �/ �/ �/ p/ N/     �) (* <* Z* r* �* *     `- F- .- - p- �, �, �, �, �, �- �- �- �- �- . �, .     2 J �! F 6 &  � � ` p � � � � � � � �  $ 6 D T j z � � � � � � �   ( 8 �! �! �! t! `! L!  !  ! �  �  �  �  �  �  �  z  \  H  .        � � � � � � � D P b n � � � � � � � �   * @ R d r � � � � � � � � � z f T D 2    �! �! " � � � � � 0! ~ � � � � � � p Z F 2 " d �     L. `. 8.     �* 
+ �* �*     R(     �*     8  �  �  �p  �s  �7  �	  �  �o  �4  �3  �  �t  �    �. �. ./ �. �. �. / / ~.     (+ >, 0, , <+ , �+ �+ �+ �+ �+ �+ �+ �+ N+ b+ v+     ) ) ,) <) N) b) p) �) �) �) �) �) �)     6( ( �' �' �' �' �' �' x' Z' B' ,' ' ' �&  (     �GetVersionExA ,InterlockedIncrement  (SetLastError  � FreeLibrary �GetProcAddress  RLoadLibraryA  �GetSystemTime \LocalFree qGetLastError  TLoadLibraryExW  uMultiByteToWideChar � FormatMessageA  � FormatMessageW  
GlobalUnlock  �GlobalFree  GetComputerNameW  GetComputerNameExW  �GetSystemInfo �GetVersionExW GlobalMemoryStatus  GlobalMemoryStatusEx  �GetPrivateProfileSectionNamesW  �GetProfileSectionW  �GetPrivateProfileSectionW � FindNextVolumeW � FindNextVolumeMountPointW �QueryDosDeviceW fGetFileType �GetVersion  �GetNumberFormatW  =GetCurrencyFormatW  �lstrcmpiA �lstrlenW  �WriteConsoleW �GetStdHandle  �ReadConsoleW  HeapFree  �GetProcessHeap  �GetSystemDirectoryA [GetExitCodeThread _TerminateThread �WaitForSingleObject o CreateThread  � DuplicateHandle �OpenProcess 4 CloseHandle BGetCurrentProcess �GlobalAlloc GlobalReAlloc GlobalLock  GlobalSize  � ExpandEnvironmentStringsW �GetPrivateProfileIntW �GetProfileIntW  �GetPrivateProfileStringW  �GetProfileStringW �WritePrivateProfileStringW  �WriteProfileStringW �GetSystemTimeAsFileTime �GetTickCount  � FileTimeToSystemTime  [SystemTimeToFileTime  ^TerminateProcess  FGetCurrentThreadId  EGetCurrentThread  �OpenThread  i CreateProcessW  �ResumeThread  XSuspendThread 1SetPriorityClass  �GetPriorityClass  DSetThreadPriority �GetThreadPriority �ReadProcessMemory ZGetExitCodeProcess  GetCommandLineW OGetDiskFreeSpaceExW TGetDriveTypeW xGetLogicalDrives  �GetVolumeInformationW NSetVolumeLabelW ~ DefineDosDeviceW  � FindFirstVolumeW  � FindVolumeClose � FindFirstVolumeMountPointW  � FindVolumeMountPointClose PSetVolumeMountPointW  � DeleteVolumeMountPointW �GetVolumeNameForVolumeMountPointW �GetVolumePathNameW  V CreateFileW |VerLanguageNameW  pMoveFileExW eGetFileTime SetFileTime  Beep  �GetUserDefaultLangID  �GetSystemDefaultLangID  �GetUserDefaultLCID  �GetSystemDefaultLCID  �GetUserDefaultUILanguage  �GetSystemDefaultUILanguage  �GetThreadLocale uGetLocaleInfoW  � GetACP  �GetOEMCP  
 AllocConsole  J CreateConsoleScreenBuffer � FillConsoleOutputAttribute  � FillConsoleOutputCharacterW � FlushConsoleInputBuffer � FreeConsole � GenerateConsoleCtrlEvent  "GetConsoleCP  3GetConsoleMode  5GetConsoleOutputCP  7GetConsoleScreenBufferInfo  :GetConsoleTitleW  ;GetConsoleWindow  pGetLargestConsoleWindowSize �GetNumberOfConsoleInputEvents �GetNumberOfConsoleMouseButtons  �SetConsoleCP  �SetConsoleCursorPosition  �SetConsoleMode  SetConsoleOutputCP  SetConsoleScreenBufferSize  SetConsoleTextAttribute SetConsoleTitleW  SetConsoleWindowInfo  7SetStdHandle  �WriteConsoleOutputCharacterW  �SetConsoleActiveScreenBuffer  �ProcessIdToSessionId  LGetDevicePowerState �GetSystemPowerStatus  ASetThreadExecutionState � DeviceIoControl a CreateMutexW  �OpenMutexW  �ReleaseMutex  l CreateSemaphoreW  �OpenSemaphoreW  �ReleaseSemaphore  �WaitForMultipleObjects  nGetHandleInformation  %SetHandleInformation  � DeleteCriticalSection VSleep &InterlockedCompareExchange  ` CreateMutexA  O CreateEventA  (InterlockedDecrement  SetEvent  #InitializeCriticalSection �SetConsoleCtrlHandler QLeaveCriticalSection  � EnterCriticalSection  �GlobalDeleteAtom  �GlobalAddAtomA  �WideCharToMultiByte k CreateSemaphoreA  �ReadDirectoryChangesW �GetOverlappedResult KERNEL32.dll  O ConvertSidToStringSidA  sLsaNtStatusToWinError � GetLengthSid  @IsValidSid  Z CopySid W ConvertStringSidToSidA  HLookupAccountNameW  �PrivilegeCheck  GetTokenInformation FSetTokenInformation NLookupPrivilegeNameW  LLookupPrivilegeDisplayNameW  AdjustTokenPrivileges 4InitializeSecurityDescriptor  GetSecurityDescriptorSacl 	GetSecurityDescriptorDacl 
GetSecurityDescriptorGroup  GetSecurityDescriptorOwner  GetSecurityDescriptorControl  � GetAce  � GetAclInformation GetNamedSecurityInfoW GetSecurityInfo uLsaOpenPolicy dLsaFreeMemory ]LsaEnumerateAccountRights _LsaEnumerateAccountsWithUserRight SLsaAddAccountRights �LsaRemoveAccountRights  }LsaQueryInformationPolicy �QueryServiceStatusEx  GetServiceKeyNameW  GetServiceDisplayNameW  ReportEventW  � GetEventLogInformation  �ReadEventLogW � CryptGenRandom  �OpenProcessToken  �OpenThreadToken JLookupAccountSidW PLookupPrivilegeValueW >IsValidAcl   AddAce  3InitializeAcl GetSidLengthRequired  ?IsValidSecurityDescriptor >SetSecurityDescriptorSacl :SetSecurityDescriptorDacl <SetSecurityDescriptorOwner  9SetSecurityDescriptorControl  6SetNamedSecurityInfoW ?SetSecurityInfo FLogonUserW  0ImpersonateLoggedOnUser RevertToSelf  2ImpersonateSelf ESetThreadToken  � DuplicateTokenEx   AllocateLocallyUniqueId VLsaClose  9InitiateSystemShutdownW  AbortSystemShutdownW  ` CreateProcessAsUserW  �OpenSCManagerW  BLockServiceDatabase �UnlockServiceDatabase �QueryServiceLockStatusW �OpenServiceW  e CreateServiceW  � DeleteService LStartServiceW B ControlService  �QueryServiceStatus  �QueryServiceConfigW 7 ChangeServiceConfigW  � EnumServicesStatusW � EnumServicesStatusExW � EnumDependentServicesW  > CloseServiceHandle  
RegisterEventSourceW  � DeregisterEventSource �OpenEventLogW �OpenBackupEventLogW = CloseEventLog " BackupEventLogW : ClearEventLogW  GetNumberOfEventLogRecords  GetOldestEventLogRecord � CryptAcquireContextW  � CryptReleaseContext DSetServiceStatus  RegisterServiceCtrlHandlerExA JStartServiceCtrlDispatcherA ADVAPI32.dll  � DefWindowProcA  �SetWindowLongW  oGetWindowLongW  PostMessageA  a CreateWindowExW RegisterClassExW  �wsprintfA �WaitForInputIdle   BlockInput  � EnumWindows � EnumChildWindows  zGetWindowTextW  :SendInput �VkKeyScanW  � EnumWindowStationsW � EnumDesktopsW � EnumDesktopWindows  � EnumClipboardFormats  � EnumDisplayMonitors � ExitWindowsEx �LockWorkStation �SystemParametersInfoW EGetParent � GetAncestor jGetWindow GetDesktopWindow  XGetShellWindow  GetForegroundWindow WSetForegroundWindow CSetActiveWindow � GetActiveWindow � FindWindowW � FindWindowExW RealGetWindowClassW � GetClassNameW �SetWindowPos  {GetWindowThreadProcessId  GetGUIThreadInfo  �SetWindowTextW  �ShowWindow  �ShowWindowAsync �ShowOwnedPopups � EnableWindow  �OpenIcon  D CloseWindow � DestroyWindow �IsIconic  �IsZoomed  �IsWindowVisible �IsWindow  �IsWindowUnicode �IsWindowEnabled �IsChild ?SendMessageTimeoutW BSendNotifyMessageW  PostMessageW  VSetFocus  � GetClientRect tGetWindowRect mGetWindowInfo sGetWindowPlacement  �SetWindowPlacement  �WindowFromPoint �InvalidateRect  �MoveWindow  �UpdateWindow  � FlashWindow �MessageBeep � GetCaretBlinkTime ESetCaretBlinkTime HideCaret �ShowCaret � GetCaretPos FSetCaretPos  AttachThreadInput 
 ArrangeIconicWindows  GetCursorPos  OSetCursorPos  [SetLayeredWindowAttributes  HGetProcessWindowStation hSetProcessWindowStation �OpenWindowStationW  c CreateWindowStationW  E CloseWindowStation  �OpenDesktopW  Q CreateDesktopW  �OpenInputDesktop  C CloseDesktop  �SwitchDesktop aGetThreadDesktop  ySetThreadDesktop  GetDoubleClickTime  )GetLastInputInfo  � GetAsyncKeyState  !GetKeyState �MapVirtualKeyA  �OpenClipboard B CloseClipboard  � EmptyClipboard  JSetClipboardData  GetClipboardData  DGetOpenClipboardWindow  GetClipboardFormatNameW GetClipboardOwner �IsClipboardFormatAvailable  RegisterClipboardFormatW  GetDC lGetWindowDC *ReleaseDC � EnumDisplayDevicesW �MonitorFromWindow �MonitorFromRect �MonitorFromPoint  @GetMonitorInfoW PostThreadMessageA  �MsgWaitForMultipleObjects � DispatchMessageA  �TranslateMessage   PeekMessageA   ChangeClipboardChain  ;SendMessageA  KSetClipboardViewer  RegisterHotKey  �UnregisterHotKey  �UnregisterDeviceNotification  RegisterDeviceNotificationA USER32.dll  �RpcStringFreeA  �UuidToStringA �UuidFromStringA �UuidCreate  �UuidCreateNil RPCRT4.dll  OGetObjectA  %GetDeviceCaps  AddFontResourceExW  �RemoveFontResourceExW L CreateScalableFontResourceW GDI32.dll  EnumProcesses  EnumProcessModules   EnumDeviceDrivers  GetModuleFileNameExW   GetModuleBaseNameW  	 GetDeviceDriverFileNameW   GetDeviceDriverBaseNameW   GetModuleInformation  PSAPI.DLL i NetApiBufferFree  � NetUserEnum � NetGroupEnum  � NetLocalGroupEnum � NetUserGetGroups  � NetUserGetLocalGroups � NetLocalGroupGetMembers � NetGroupGetUsers  � NetUserAdd  � NetUserGetInfo  � NetGroupGetInfo � NetLocalGroupGetInfo  � NetUserSetInfo  � NetGroupAdd � NetLocalGroupAdd  � NetLocalGroupAddMembers � NetLocalGroupDelMembers  DsGetDcNameW  � NetShareAdd � NetShareEnum  � NetShareCheck � NetShareGetInfo � NetShareSetInfo � NetUseEnum  � NetUseGetInfo � NetGetDCName  � NetScheduleJobGetInfo � NetScheduleJobAdd � NetScheduleJobEnum  � NetSessionEnum  � NetSessionGetInfo s NetConnectionEnum � NetFileEnum � NetFileGetInfo  � NetUserDel  � NetGroupDel � NetLocalGroupDel  � NetGroupAddUser � NetGroupDelUser � NetShareDel � NetFileClose  � NetSessionDel � NetScheduleJobDel NETAPI32.dll  I PdhLookupPerfNameByIndexW " PdhEnumObjectsW  PdhEnumObjectItemsW K PdhMakeCounterPathW S PdhParseCounterPathW  ; PdhGetFormattedCounterValue 
 PdhBrowseCountersW  8 PdhGetDllVersion   PdhConnectMachineW  } PdhSetDefaultRealTimeDataSource Q PdhOpenQueryW  PdhCloseQuery  PdhAddCounterW  y PdhRemoveCounter   PdhCollectQueryData � PdhValidatePathW  pdh.dll  PlaySoundW  WINMM.dll - WNetGetLastErrorW L WNetUseConnectionW  < WNetGetUniversalNameW 7 WNetGetResourceInformationW > WNetGetUserW   WNetCancelConnection2W  MPR.dll WS2_32.dll  . CoInitializeEx  N CoTaskMemAlloc  O CoTaskMemFree StringFromGUID2  CoCreateInstance  $ CoGetObject � IIDFromString  CLSIDFromProgID � ProgIDFromCLSID  CLSIDFromString Y CreateBindCtx ^ CreateFileMoniker � OleRun  ole32.dll OLEAUT32.dll   CommandLineToArgvW  B SHFreeNameMappings  @ SHFileOperationW  S SHGetSpecialFolderLocation  Q SHGetPathFromIDListW  Z SHInvokePrinterCommandW ; SHChangeNotify  SHELL32.dll a EnumPrintersW WINSPOOL.DRV   GetFileVersionInfoW  GetFileVersionInfoSizeW 
 VerQueryValueA   VerQueryValueW  VERSION.dll : GetNetworkParams   GetAdaptersInfo @ GetPerAdapterInfo . GetInterfaceInfo  ) GetIfEntry  + GetIfTable  / GetIpAddrTable  4 GetIpNetTable 2 GetIpForwardTable G GetTcpTable N GetUdpTable   GetBestRoute   GetAdapterIndex ; GetNumberOfInterfaces  FlushIpNetTable � SetTcpEntry  GetBestInterface  iphlpapi.dll   SetSuspendState POWRPROF.dll   GetUserNameExW  % LsaFreeReturnBuffer $ LsaEnumerateLogonSessions & LsaGetLogonSessionData   FreeContextBuffer  EnumerateSecurityPackagesW    InitializeSecurityContextW    AcceptSecurityContext . QueryContextAttributesW , MakeSignature  EncryptMessage   AcquireCredentialsHandleW  FreeCredentialsHandle  DeleteSecurityContext 1 QuerySecurityContextToken  ImpersonateSecurityContext  O VerifySignature  DecryptMessage  Secur32.dll ! LoadUserProfileW  , UnloadUserProfile  GetProfileType  USERENV.dll   WTSCloseServer   WTSFreeMemory  WTSEnumerateProcessesW   WTSEnumerateSessionsW  WTSQuerySessionInformationW  WTSDisconnectSession  	 WTSLogoffSession   WTSOpenServerW   WTSSendMessageW WTSAPI32.dll  SetupDiCreateDeviceInfoListExW  SetupDiDestroyDeviceInfoList  3SetupDiGetClassDevsExW   SetupDiEnumDeviceInfo JSetupDiGetDeviceRegistryPropertyW !SetupDiEnumDeviceInterfaces HSetupDiGetDeviceInterfaceDetailW  SetupDiClassNameFromGuidExW SetupDiClassGuidsFromNameExW  ESetupDiGetDeviceInstanceIdW SETUPAPI.dll  �strcmp  �_snprintf �malloc  �strlen  �memmove ^free  �wcslen  �memset  � _errno  �_pctype _isctype  a __mb_cur_max  �sprintf �_snwprintf  �_wcsdup �strstr  �strchr  � _except_handler3  �strcpy  �realloc �wcscmp  �setlocale �strcat  �strtoul @calloc  �strncpy �wcscpy  �printf  �memcmp   ??3@YAXPAX@Z  I __CxxFrameHandler �_purecall A _CxxThrowException   ??2@YAPAXI@Z  � _beginthreadex   ??0exception@@QAE@ABV0@@Z �wcstol  MSVCRT.dll  U __dllonexit �_onexit  ??1type_info@@UAE@XZ  _initterm � _adjust_fdiv  � ??0Init@ios_base@std@@QAE@XZ  	??1Init@ios_base@std@@QAE@XZ  � ??0_Winit@std@@QAE@XZ ??1_Winit@std@@QAE@XZ � ??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAE@XZ  �?_Tidy@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@AAEX_N@Z  � ??1?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAE@XZ  �?_Tidy@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@AAEX_N@Z  "?assign@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAEAAV12@ABV12@II@Z  b?npos@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@2IB   ?assign@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@PBDI@Z  -?_C@?1??_Nullstr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@CAPBDXZ@4DB &?assign@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAEAAV12@PBGI@Z  ?append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@PBDI@Z  �?insert@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@IPBDI@Z ?assign@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@ABV12@II@Z  a?npos@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@2IB  ?append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAEAAV12@ID@Z  � ??0logic_error@std@@QAE@ABV01@@Z  � ??0out_of_range@std@@QAE@ABV01@@Z ??1out_of_range@std@@UAE@XZ �??_7out_of_range@std@@6B@ � ??0logic_error@std@@QAE@ABV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@1@@Z L ??0?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QAE@PBDABV?$allocator@D@1@@Z  ??1_Lockit@std@@QAE@XZ  � ??0_Lockit@std@@QAE@XZ  .?_C@?1??_Nullstr@?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@CAPBGXZ@4GB S ??0?$basic_string@GU?$char_traits@G@std@@V?$allocator@G@2@@std@@QAE@PBGABV?$allocator@G@1@@Z  MSVCP60.dll � DisableThreadLibraryCalls �_strdup                   ��J    \:          H: P: X: 'D   f: p:    twapi.dll SWIG_init Twapi_Init                                                                                                                                                                                                                                                                                                                                                                                                          UU�U�U�c$d�|w�+�W���                    global  twapi::SHChangeNotify   twapi::ComEventSink twapi::IDispatch_Invoke twapi::get_build_config twapi::kl_get   twapi::try  twapi::parseargs    Could not get OS version    ,   . Must be one of    Invalid Non-boolean Non-integer enumeration Non-integer     Command has extra arguments specified:  Unknown option '    No value supplied for option '  Invalid option type '   Badly formed option descriptor: '   switch  bool    arg int Extra argument or unknown option '  '   Non-integer value specified for -maxleftover    Missing value for -maxleftover  Too many options specified  -maxleftover    -nulldefault    -ignoreunknown  argvVar optlist ?-ignoreunknown? ?-nulldefault? ?-?  value '    ' specified for option '-   errorResult Invalid syntax: should be    SCRIPT ?onerror ERROR ERRORSCRIPT? ...?finally FINALSCRIPT?    script ?onerror ERROR errorscript? ...?finally FINALSCRIPT? errorCode   finally onerror KEYLIST KEY ?DEFAULT?   No field     found in keyed list.   Invalid keyed list format. Must have even number of elements.   errorInfo   can't find "global" command invalid TclX result save object Failed to allocate %d bytes.    DllGetVersion   Integer '%d' not within range %d-%d Invalid item id list format CoTaskMemAlloc failed in SHChangeNotify Could not convert SID pointer:  Integer value must be less than 65536   T w a p i H i d d e n W i n d o w    	ddddddd
 !"#dddddd
 !"#     �F   �F   �F   xF   XF   <F    FInvalid option specified.   Internal limit exceeded.    Incorrect number of arguments.  Extra arguments specified.  Attempt to write past the end of memory buffer. Invalid arguments specified.    No error.   Twapi error %d  TWAPI   W i n d o w s   e r r o r :   % l d     f u n c t i o n   n o t   s u p p o r t e d   u n d e r   t h i s   W i n d o w s   v e r s i o n   p d h . d l l   n e t m s g . d l l     Windows error: %ld  TWAPI_WIN32     :       0123456789abcdef           �A   �   �   �   �   �   �   �   �	   �
   �   �   �   �   �   �   |   x   t   p   �A   h   `   X   P   H$   @   4a��0���� ������p����@������x���T����0����
���|����            hPY��P�HX    `0�X��P�oH�?                @��`�Ih    8)�,� ��~�N�~�N�������                �x' p�Ix    �� 3 �a!!�1"�!t-#�"d1$�#P$%�$                @��%K&��J�    <�&W&8�'%'                0��'�(�K�    8l22�;3�2$%4�35�46�5�
7�6�8�7��8~8��9u9            � h:;�XK�    ������\����,�x\���\,�̂L����@̄l�            0X<����K�    ��    �b�    ���    ��    ���    x͙    X+�    8��    ��    �d�    �ћ    �O�    �Ȝ    �J�    pΝ    \t�    Hٞ    4O�     ��    #�    ���    ��    ���    ��    ���    �%�    t��    \أ    @ť    "�     ��    �T�    �W�    �Ш    �*�    �|�    tΩ    T6�    4��    �    u�    ��    �S�    �¬    �S�    `�    8f�    ��    ���    �
�    ���    x�    L��     0�    ���    �C�    �Գ    ��    t��    `P�    D׶     �    t�    ��    ���    �1�    ���    �:�    tʼ    P[�    $�    �    �
��    �
J�    �
��    �
(�    t
��    `
"�    @
��    ,
Y�    
��    �	��    �	S�    �	L�    �	��    �	�    �	}�    h	��    P	��    4	}�    $	b�    ���    �N�    ���    ���    `+�    @U�    ��    ��    �a�    ���    `0�    4��     �    �p�    ���    �@�    X��    ,�     ��    ��    �x�    p��    @T�    ��    �0�    ���    �
�    p��    H��    ,Y�    ��    �}7 pI��    �|�    ���    �r�    p�    Pn�    0�    �    ���    ���    ���    ��    ���    x�    `�    <��     ��     t�    ���    �/�    �Y�    |��    T��    4$�    ��     :�    � ��    � ��    � <�    � ��    l 0�    D q�     ��     9�    ����    ��9�    ����    ��U�    |�
�    \���    @�2�    (�S�    �}�    ����    ����    ��C�    ����    ��C�    x���    \���    H��    0���    ��     �t�    ����    ��T�    ����    X�%�    <�z�     �Q     ��     ��>    ��    ���    ���    ���    l�D    T��    <�    $�q    ��    ���    ��\    ���    ���    t�O	    X��	    8�
    �c
    ���
    ��w    ��|    ��I    x�|    T�    <�W    ��    ��(    ���    ���    ��M    ���    t��    \��    D�0    0��    ��    �o    ���    ��?    ���    ��    ��e    ��}7 �Il��    L�)    ,��    �    ���    ��    ��~    ���    l�N    L��    $�    ��~    ���    ��N    ���    \�    4��    �    ���    ��    ��x    ���    t�}7 xJP�3     ,��     �!    ��a!    ���!    ��1"    p��"    D�-#    ��#    ��1$    ���$    ��$%    x��%    X��%    @�}7 �J,�W&    ��&    �%'    ���'    ���'    ��K(    ��}7 8K���(    ���(    x�-)    d��)    P�**    8��*     � +    �T+    ���+    ��,    ���,    ��-    ���-    t��.    `�(/    H��/    0�10    ��0    ��s1    ��2    ��l2    ���2    |�;3    X��3    4�%4    ��4    ��5    ���5    ��6    t��6    L�
7    $��7    ��8    ��~8    ���8    ��u9    l��9    P�h:    4��:    �}7 �K�#;    ���;    ��/<    ���<    ��=    ���=    |��=    l�c>    X��>    @�?    0�}?     ��?    �W@    ���@    ��1A    ���A    ��B    ���B    ��KC    l��C    \�5D    D��D    ,�/E    ��E    ��<F    ���F    ��XG    ���G    ��vH    ���H    p�XI    d��I    P�J    4�cJ    ��J    ��J    ��IK    ���K    ��L    ��NL    ���L    |�M    `�LM    L�M    8�N    $�zN    ��N    ��O    ��8O    ��kO    ���P    ��Q    d��Q    H��Q    ,��R    �YS    ���S    ���S    ��8T    ���T    ��+U    ��BV    l��V    T�-W    <��W    $�
X    �jX    ���X    ��Y    ��iY    ���Y    ��Z    |�yZ    d��Z    L��Z    4��[    �\    ��[\    ���\    ��]    ��V]    p��]    P�^    4�C^    ��^    ���^    ��(_    ��o_    ���_    |�`    d�j`    H�a    0��a    �	b    ��b    ���b    ��1c    ���c    ��!d    ���d    x�Qe    `�f    @��f     �=g     ��g    ���h    ��|i    ���i    ��8j    h��j    L�ok    4��k    �Jl    ��l    ���m    ��n    ���n    ��7o    p��o    P�1p    ,�q    �hq    ���q    ��Er    ���r    ��7s    ���s    t�3t    T��t    0��u    �(v    ���v    ��Vw    ��x    ��Zx    ���x    ���x    h�y    T�}y    4�;z    �nz    ���z    ��|    ���|    ���|    |�8}    \��}    <�g~    ��    ���    ��\�    ����    d�,�    4���    ���    ��\�    ��̂    t�,�    L���    $���    ��l�    ��̄    ��<�    ����    ��}7 PLh���    L��    ,�v�    �և    ����    ��Y�    ��A�    ����    ����    ��.�    d���    H�P�    (��    ���    ��Y�    ����    ��l�    ����    |�!�    `�~�    @�.�     ���    �ʞ    ��{�    ���    ��F�    ����    ����    t��    \�m�    D�ߣ     �a�     ��    ��}�    ���    ��E�    ���    d�v�    D�8�    0���    �ҩ    ���    ��a�    ���    ��7�    ��Ԭ    t�J�    P�ȭ    (�Y�     ��    ��T�    ��ѯ    ���    ����    ���    `�4�    @���    (��    �d�    ��γ    ��6�    ��ߴ    ����    ���    d�_�    <���    $�Ķ    �5�    ����    ��U�    ���    ��ѹ    ���    X�u�    D���    ,�`�    �Ż    ��z�    ��޼    ��B�    ����    ���    t�M�    `��    L�y�    8�	�     ���    ��    ����    ��[�    ����    ����    ���    h���    L�A�    (���    �U�    ����    ��h�    ����    x��    `���    D���    $�D�    ���    ����    ��\�    ����    ��H�    ��)�    p��    T�c�    4���    �$�    ��w�    ��G�    ����    ����    l�$�    L���    $�4�     �~�    ��h�    ����    ����    l���    T���    ,���    �5�    ����    ����    ����    ��_�    ����    l���    X�,�    D�_�    ,���    ���    ���    ��?�    ����    ����    t���    `���    L���    (���    �,�    ��g�    ����    ��W�    ����    |�1�    X���    D��    0���    ��     �t�    ����    ��F�    ����    ���    |���    h�F�    P���    <�N�    $���    �_�    ����    ����    ����    ��%�    ��f�    l���    L��    0�y�    �C�    ����    ���    ��x�    ��A�    ����    |�8�    d��    L���    ,�4�    ���    ����    ����    ���    l�S�    H���    (���    �Y�    ����    ��O�    ����    ���    p��    X�:�    @���    $���    �G     ���     ��    ��K    ���    x�$    `��    H�w    0��    �W    ��2    ��'    ���    ���    X�7    4��    �}	    ��
    ���
    ��c    ��1    \�z    8�    �b    ���    ��u    ��    ���    |��    `�@    D��    $�m     �    ���    ��-    ���    |�P    X�    8��    �    ���    ���    ���    ��]    t�    P��    �    ��    ��y    ��N    t��    L�)     (��     �Z!    �5"    ľ�"    ��t#    ��$    d��$    <��%    �a&    ���&    ܽ�'    ��(    ��u(    p�_)    H��)    ��*    �E+    ȼ�+    ���,    |�c-    T�.    $��.    ���/    ԻI0    ���0    ���1    T�v2    4�23    ��3    ܺ4    ��5    ���5    T�96    0��6    �Q7    ܹ�7    ���8    ��)9    |��9    `�`:    D��:    (��;    �2<    ��<    ȸM=    ���=    ��@>    t��>    P�(?    0��?    �7@    ��@    ȷUA    ��"B    ���B    t�C    P��C                    H�    @�                H�                                                        4�    ,�8K            4�                                                         �    �                �                        ��                        �                         �                        ܶ                                                        ȶ    ��                ȶ                                                        ��    ��                ��                                                        ��    ��                ��                                                        ��    x�                ��                                                        l�    d�                l�                                                        X�    L�                X�                                                        D�    4��I            D�                                                        $�    �                $�                                                        �    �                �                        ��                        �                         �                        ܶ                                                         �    ��                 �                                                        �    �                �                                                        Ե    ̵                Ե                                                        ��    ��                ��                                                        ��    ��                ��                                                        ��    x�                ��                                                        X�    <�                X�                                                        $�    �                $�                                                         �    �                 �                                                        �    �                �                                                        ش    Դ                ش                                                        ��    ��                ��                                                        ��    ��                ��                                                        |�    l�                |�                                                        X�    D�                X�                                                        4�    $�xJ            4�                                                        �    �                �                        �                        �                                                        �    ܳ                �                                                        ĳ    ��                ĳ                                                        ��    ��                ��                                                        ��    x�                ��                                                        l�    `�                l�                                                        T�    L�                T�                                                        D�    <�                D�                                                        4�    ,�                4�                                                         �    �                 �                                                        ��    ز                ��                                                        Ĳ    ��                Ĳ                                                        ��    ��                ��                                                        ��    ��                ��                                                        |�    p�                |�                                                        X�    @�                X�                                                        $�    �                $�                                                        �    �                �                        ��                        �                         �                        ܶ                                                        ��    �                ��                                                        ܱ    б                ܱ                                                        ��    ��                ��                                                        ��    |�                ��                                                        l�    \�                l�                                                        L�    <�                L�                                                        4�    ,�                4�                                                         �    �                 �                                                         �    �                 �                                                        �    ذ                �                                                        Ȱ    ��                Ȱ                                                        ��    ��                ��                                                        ��    ��                ��                                                        ��    l�                ��                                                        `�    T�                `�                                                        L�    D�                L�                                                        8�    ,�                8�                                                         �    �                 �                                                         �    �                 �                                                        �    Я                �                                                        ȯ    ��                ȯ                                                        ��    ��                ��                                                        �    ��                �                        �                        �                                                        ��    ��                ��                                                        t�    \�                t�                                                        P�    H�                P�                                                        0�    �                0�                                                        ��    �                ��                                                        Į    ��                Į                                                        ��    ��                ��                                                        ��    p�                ��                                                        H�    $�                H�                                                        �    �                �                                                         �    �                 �                                                        ܭ    ̭                ܭ                                                        ��    ��                ��                                                        ��    |�                ��                                                        p�    d�                p�                                                        T�    H�                T�                                                        <�    0�                <�                                                         �    �                 �                                                        �    ��                �                                                        �    ج                �                                                        Ĭ    ��                Ĭ                                                        ��    ��                ��                                                        |�    t�                |�                                                        `�    P��K            `�                                                        @�    0�                @�                                                        �    �                �                                                        ��    �                ��                                                        Ы    ī                Ы                                                        ��    ��                ��                                                        ��    ��                ��                                                        t�    d�                t�                                                        T�    D�                T�                                                        4�    $�                4�                                                        �    ��                �                                                        ܪ    ��                ܪ                                                        ��    ��pI            ��                                                        ��    t�                ��                                                        `�    L�PL            `�                        8�                                                    8�    $�PL            8�                        `�                                                    �    ��                �                                                        �    Щ                �                                                        ��    ��                �                        ��                        �                         �                        ܶ                                                        ��    ��                ��                                                        ܶ    ��                �                        ��                        �                         �                        ܶ                                                        ��    p�                ��                                                        \�    L�                \�                                                        4�    �                4�                                                         �    �                 �                                                        �    ب                �                                                        Ȩ    ��                Ȩ                                                        ��    ��                ��                                                        |�    h�                |�                                                        \�    P�                \�                                                        D�    8�                D�                                                        (�    �                (�                                                        �    �                �                        �                        �                                                         �    ��J             �                                                        ا    ħ                ا                                                        ��    ��                ��                                                        ��    x�                ��                                                        l�    `�                l�                                                        X�    P�                X�                                                        @�    0�                @�                                                         �    �                 �                                                        �     �                �                                                        ��    �                ��                                                        ܦ    ̦                ܦ                                                        ��    ��                ��                                                        ��    ��                ��                                                        ��    l�                ��                                                    pq�q r�r@s�s�sHt�t�tPu�upv�v wxw�w(x�x�x0y�y�y8z�z�z@{�{�{�|�|0}�}�}8~�~�~@��H�����P��� �Ȃ �x�Ѓ(���؄0�����8����@�����H�����P��� �X��@�����H�����P��� �X����`����h����p�ȑ �x�В(���ؓ0�����8����@����H������ؘ0���P��p�ț �x�М(���؝0�����p�ȟ �x�Р(���ء0����8����    IScheduledWorkItem *    _p_IScheduledWorkItem   IID *   _p_IID  MIB_TCPROW *    _p_MIB_TCPROW   STARTUPINFOW *  _p_STARTUPINFOW HGLOBAL _HGLOBAL    ACL *   _p_ACL  TASK_TRIGGER *  _p_TASK_TRIGGER LPMODULEINFO *  _p_LPMODULEINFO ATOM *  _p_ATOM IUnknown *  _p_IUnknown IUnknown ** _p_p_IUnknown   PROCESS_INFORMATION *   _p_PROCESS_INFORMATION  TOKEN_PRIVILEGES *  _p_TOKEN_PRIVILEGES WINDOWPLACEMENT *   _p_WINDOWPLACEMENT  BOOL *  IMoniker ** _p_p_IMoniker   IMoniker *  _p_IMoniker HINSTANCE   _HINSTANCE  IEnumWorkItems **   _p_p_IEnumWorkItems IEnumWorkItems *    _p_IEnumWorkItems   unsigned int *  _p_unsigned_int BSTR *  _p_BSTR LSA_OBJECT_ATTRIBUTES * _p_LSA_OBJECT_ATTRIBUTES    SECURITY_ATTRIBUTES *   _p_SECURITY_ATTRIBUTES  IRecordInfo **  _p_p_IRecordInfo    IRecordInfo *   _p_IRecordInfo  ULONG * DISPLAY_DEVICEW *   _p_DISPLAY_DEVICEW  unsigned long * LASTINPUTINFO * _p_LASTINPUTINFO    SYSTEM_POWER_STATUS *   _p_SYSTEM_POWER_STATUS  LPSERVICE_STATUS    _LPSERVICE_STATUS   SERVICE_STATUS *    _p_SERVICE_STATUS   Tcl_Interp *    _p_Tcl_Interp   OSVERSIONINFOEXW *  _p_OSVERSIONINFOEXW CONSOLE_SCREEN_BUFFER_INFO *    _p_CONSOLE_SCREEN_BUFFER_INFO   LPCWSTR_MULTISZ *   _p_LPCWSTR_MULTISZ  RECORDDATA **   _p_p_RECORDDATA RECORDDATA *    _p_RECORDDATA   ITypeComp **    _p_p_ITypeComp  ITEMIDLIST *    _p_ITEMIDLIST   ITEMIDLIST **   _p_p_ITEMIDLIST ITypeComp * _p_ITypeComp    struct sockaddr_in *    _p_sockaddr_in  LPWSTR_CoTaskMem *  _p_LPWSTR_CoTaskMem IDispatchEx *   _p_IDispatchEx  GUITHREADINFO * _p_GUITHREADINFO    COORD * _p_COORD    LPCWSTR_WITH_NULL * _p_LPCWSTR_WITH_NULL    LARGE_INTEGER * _p_LARGE_INTEGER    OVERLAPPED *    _p_OVERLAPPED   HDEVINFO    _HDEVINFO   MONITORINFO *   _p_MONITORINFO  LPWSTR *    _p_LPWSTR   ITypeLib ** _p_p_ITypeLib   ITypeLib *  _p_ITypeLib HMODULE_LITERAL *   _p_HMODULE_LITERAL  ADDRESS_LITERAL *   _p_ADDRESS_LITERAL  HWND_LITERAL *  _p_HWND_LITERAL ULARGE_INTEGER *    _p_ULARGE_INTEGER   HMENU   _HMENU  SP_DEVICE_INTERFACE_DETAIL_DATA_W * _p_SP_DEVICE_INTERFACE_DETAIL_DATA_W    ITypeInfo **    _p_p_ITypeInfo  ITypeInfo * _p_ITypeInfo    IEnumConnectionPoints * _p_IEnumConnectionPoints    IEnumConnectionPoints **    _p_p_IEnumConnectionPoints  IProvideClassInfo2 *    _p_IProvideClassInfo2   char ** _p_p_char   LSA_UNICODE_STRING *    _p_LSA_UNICODE_STRING   CLSID * _p_CLSID    long *  wchar_t *   _p_wchar_t  HDESK   _HDESK  ITaskTrigger *  _p_ITaskTrigger ITaskTrigger ** _p_p_ITaskTrigger   SC_HANDLE   _SC_HANDLE  LSA_HANDLE  _LSA_HANDLE HANDLE  _HANDLE HANDLE *    _p_HANDLE   NONNEGATIVE_HANDLE  _NONNEGATIVE_HANDLE ITask * _p_ITask    WORD *  _p_WORD SMALL_RECT *    _p_SMALL_RECT   FILETIME *  _p_FILETIME IEnumVARIANT ** _p_p_IEnumVARIANT   VARIANT *   _p_VARIANT  BYTE *  _p_BYTE IEnumVARIANT *  _p_IEnumVARIANT IPersistFile *  _p_IPersistFile SP_DEVICE_INTERFACE_DATA *  _p_SP_DEVICE_INTERFACE_DATA IBindCtx ** _p_p_IBindCtx   IBindCtx *  _p_IBindCtx SecHandle * _p_SecHandle    LPDWORD LPCWSTR_NULL_IF_EMPTY * _p_LPCWSTR_NULL_IF_EMPTY    LPWSTR_NULL_IF_EMPTY *  _p_LPWSTR_NULL_IF_EMPTY LPOLESTR *  _p_LPOLESTR HMONITOR    _HMONITOR   int *   _p_int  ITaskScheduler *    _p_ITaskScheduler   SEC_WINNT_AUTH_IDENTITY_W * _p_SEC_WINNT_AUTH_IDENTITY_W    double *    _p_double   HTHEME  _HTHEME void *  _p_void void ** _p_p_void   HCRYPTPROV  _HCRYPTPROV HCRYPTPROV *    _p_HCRYPTPROV   LOGFONTW *  _p_LOGFONTW IConnectionPoint ** _p_p_IConnectionPoint   IConnectionPoint *  _p_IConnectionPoint _p_BOOL _p_long LONG *  _p_LONG WINDOWINFO *    _p_WINDOWINFO   SP_DEVINFO_DATA *   _p_SP_DEVINFO_DATA  SecBufferDesc * _p_SecBufferDesc    HGDIOBJ _HGDIOBJ    SECURITY_DESCRIPTOR *   _p_SECURITY_DESCRIPTOR  HDC _HDC    PSID *  _p_PSID SYSTEMTIME *    _p_SYSTEMTIME   IProvideClassInfo * _p_IProvideClassInfo    IConnectionPointContainer * _p_IConnectionPointContainer    HMODULE *   _p_HMODULE  IDispatch **    _p_p_IDispatch  IDispatch * _p_IDispatch    SC_LOCK _SC_LOCK    LPCWSTR *   _p_LPCWSTR  WCHAR * _p_WCHAR    DWORD * LPDEVMODEW *    _p_LPDEVMODEW   RECT const *    _p_RECT AT_INFO *   _p_AT_INFO  HWINSTA _HWINSTA    GUID *  _p_GUID LPCOLESTR * _p_LPCOLESTR    UUID *  _p_UUID Twapi_fileverptr_t  _Twapi_fileverptr_t _p_ULONG    _p_DWORD    _p_unsigned_long    _LPDWORD    HREFTYPE *  _p_HREFTYPE POINT * _p_POINT    LUID *  _p_LUID twapi::IPersistFile_SaveCompleted   twapi::IPersistFile_Save    twapi::IPersistFile_Load    twapi::IPersistFile_IsDirty twapi::IPersistFile_GetCurFile  twapi::ITaskTrigger_SetTrigger  twapi::ITaskTrigger_GetTriggerString    twapi::ITaskTrigger_GetTrigger  twapi::ITask_SetWorkingDirectory    twapi::ITask_SetTaskFlags   twapi::ITask_SetPriority    twapi::ITask_SetParameters  twapi::ITask_SetMaxRunTime  twapi::ITask_SetApplicationName twapi::ITask_GetWorkingDirectory    twapi::ITask_GetTaskFlags   twapi::ITask_GetPriority    twapi::ITask_GetParameters  twapi::ITask_GetMaxRunTime  twapi::ITask_GetApplicationName twapi::IScheduledWorkItem_Terminate twapi::IScheduledWorkItem_SetWorkItemData   twapi::IScheduledWorkItem_SetIdleWait   twapi::IScheduledWorkItem_SetFlags  twapi::IScheduledWorkItem_SetErrorRetryInterval twapi::IScheduledWorkItem_SetErrorRetryCount    twapi::IScheduledWorkItem_SetCreator    twapi::IScheduledWorkItem_SetComment    twapi::IScheduledWorkItem_SetAccountInformation twapi::IScheduledWorkItem_Run   twapi::IScheduledWorkItem_GetTriggerString  twapi::IScheduledWorkItem_GetTriggerCount   twapi::IScheduledWorkItem_GetTrigger    twapi::IScheduledWorkItem_GetStatus twapi::IScheduledWorkItem_GetNextRunTime    twapi::IScheduledWorkItem_GetMostRecentRunTime  twapi::IScheduledWorkItem_GetIdleWait   twapi::IScheduledWorkItem_GetFlags  twapi::IScheduledWorkItem_GetExitCode   twapi::IScheduledWorkItem_GetCreator    twapi::IScheduledWorkItem_GetComment    twapi::IScheduledWorkItem_GetAccountInformation twapi::IScheduledWorkItem_EditWorkItem  twapi::IScheduledWorkItem_DeleteTrigger twapi::IScheduledWorkItem_CreateTrigger twapi::IEnumWorkItems_Skip  twapi::IEnumWorkItems_Reset twapi::IEnumWorkItems_Clone twapi::ITaskScheduler_GetTargetComputer twapi::ITaskScheduler_SetTargetComputer twapi::ITaskScheduler_NewWorkItem   twapi::ITaskScheduler_IsOfType  twapi::ITaskScheduler_Enum  twapi::ITaskScheduler_Delete    twapi::ITaskScheduler_AddWorkItem   twapi::ITaskScheduler_Activate  twapi::IProvideClassInfo2_GetGUID   twapi::IProvideClassInfo_GetClassInfo   twapi::IEnumConnectionPoints_Skip   twapi::IEnumConnectionPoints_Reset  twapi::IEnumConnectionPoints_Next   twapi::IConnectionPointContainer_FindConnectionPoint    twapi::IConnectionPointContainer_EnumConnectionPoints   twapi::IConnectionPoint_Unadvise    twapi::IConnectionPoint_GetConnectionInterface  twapi::IConnectionPoint_Advise  twapi::IEnumVARIANT_Skip    twapi::IEnumVARIANT_Reset   twapi::IEnumVARIANT_Clone   twapi::IMoniker_GetDisplayName  twapi::IRecordInfo_RecordInit   twapi::IRecordInfo_RecordDestroy    twapi::IRecordInfo_RecordCreateCopy twapi::IRecordInfo_RecordCreate twapi::IRecordInfo_RecordCopy   twapi::IRecordInfo_RecordClear  twapi::IRecordInfo_IsMatchingType   twapi::IRecordInfo_GetTypeInfo  twapi::IRecordInfo_GetSize  twapi::IRecordInfo_GetName  twapi::IRecordInfo_GetGuid  twapi::IRecordInfo_GetField twapi::ITypeLib_GetTypeInfoOfGuid   twapi::ITypeLib_GetTypeInfo twapi::ITypeLib_GetTypeInfoType twapi::ITypeLib_GetTypeInfoCount    twapi::ITypeLib_GetDocumentation    twapi::ITypeInfo_GetImplTypeFlags   twapi::ITypeInfo_GetDocumentation   twapi::ITypeInfo_GetContainingTypeLib   twapi::ITypeInfo_GetTypeComp    twapi::ITypeInfo_GetRefTypeInfo twapi::ITypeInfo_GetRefTypeOfImplType   twapi::IDispatchEx_GetNextDispID    twapi::IDispatchEx_GetNameSpaceParent   twapi::IDispatchEx_GetMemberProperties  twapi::IDispatchEx_GetMemberName    twapi::IDispatchEx_GetDispID    twapi::IDispatch_GetTypeInfo    twapi::IDispatch_GetTypeInfoCount   twapi::IUnknown_AddRef  twapi::IUnknown_Release twapi::DuplicateHandle  twapi::SetHandleInformation twapi::GetHandleInformation twapi::Twapi_GetHandleInformation   twapi::Tcl_GetChannelHandle twapi::CryptGenRandom   twapi::CryptReleaseContext  twapi::CryptAcquireContext  twapi::DecryptMessage   twapi::EncryptMessage   twapi::VerifySignature  twapi::MakeSignature    twapi::QueryContextAttributes   twapi::ImpersonateSecurityContext   twapi::QuerySecurityContextToken    twapi::DeleteSecurityContext    twapi::AcceptSecurityContext    twapi::InitializeSecurityContext    twapi::FreeCredentialsHandle    twapi::AcquireCredentialsHandle twapi::EnumerateSecurityPackages    twapi::Twapi_Free_SEC_WINNT_AUTH_IDENTITY   twapi::Twapi_Allocate_SEC_WINNT_AUTH_IDENTITY   twapi::WaitForMultipleObjects   twapi::ReleaseSemaphore twapi::OpenSemaphore    twapi::CreateSemaphore  twapi::ReleaseMutex twapi::OpenMutex    twapi::CreateMutex  twapi::Twapi_WNetGetResourceInformation twapi::NetScheduleJobEnum   twapi::NetScheduleJobDel    twapi::NetScheduleJobAdd    twapi::NetScheduleJobGetInfo    twapi::NetGetDCName twapi::WNetGetUser  twapi::WNetGetUniversalName twapi::WNetCancelConnection2    twapi::Twapi_WNetUseConnection  twapi::NetSessionDel    twapi::NetSessionGetInfo    twapi::NetSessionEnum   twapi::NetFileClose twapi::NetFileGetInfo   twapi::NetFileEnum  twapi::NetConnectionEnum    twapi::NetShareSetInfo  twapi::NetShareGetInfo  twapi::Twapi_NetShareCheck  twapi::Twapi_NetShareEnum   twapi::NetShareDel  twapi::Twapi_NetUseGetInfo  twapi::NetUseEnum   twapi::NetShareAdd  twapi::Twapi_FormatExtendedUdpTable twapi::GetExtendedUdpTable  twapi::Twapi_FormatExtendedTcpTable twapi::GetExtendedTcpTable  twapi::GetBestInterface twapi::GetBestRoute twapi::Twapi_ResolveAddressAsync    twapi::Twapi_ResolveHostnameAsync   twapi::getaddrinfo  twapi::getnameinfo  twapi::SetTcpEntry  twapi::AllocateAndGetUdpExTableFromStack    twapi::AllocateAndGetTcpExTableFromStack    twapi::FlushIpNetTable  twapi::GetIpForwardTable    twapi::GetIpNetTable    twapi::GetIpAddrTable   twapi::GetIfTable   twapi::GetIfEntry   twapi::GetPerAdapterInfo    twapi::GetNumberOfInterfaces    twapi::GetInterfaceInfo twapi::GetAdapterIndex  twapi::GetAdaptersInfo  twapi::GetNetworkParams twapi::Twapi_DeviceChangeNotifyStop twapi::Twapi_DeviceChangeNotifyStart    twapi::DeviceIoControl  twapi::SetupDiGetDeviceInstanceId   twapi::SetupDiClassGuidsFromNameEx  twapi::SetupDiClassNameFromGuidEx   twapi::SetupDiGetDeviceInterfaceDetail  twapi::SetupDiEnumDeviceInterfaces  twapi::SetupDiGetDeviceRegistryProperty twapi::SetupDiEnumDeviceInfo    twapi::SetupDiGetClassDevsEx    twapi::SetupDiDestroyDeviceInfoList twapi::SetupDiCreateDeviceInfoListEx    twapi::SetThreadExecutionState  twapi::GetSystemPowerStatus twapi::Twapi_PowerNotifyStop    twapi::Twapi_PowerNotifyStart   twapi::GetDevicePowerState  twapi::SetSuspendState  twapi::DsGetDcName  twapi::WTSSendMessage   twapi::WTSQuerySessionInformation   twapi::WTSOpenServer    twapi::WTSLogoffSession twapi::WTSEnumerateSessions twapi::WTSEnumerateProcesses    twapi::WTSDisconnectSession twapi::WTSCloseServer   twapi::ProcessIdToSessionId twapi::Twapi_EnumPrinters_Level4    twapi::IScheduledWorkItem_GetWorkItemData   twapi::IScheduledWorkItem_GetRunTimes   twapi::IEnumWorkItems_Next  twapi::CreateScalableFontResource   twapi::RemoveFontResourceEx twapi::AddFontResourceEx    twapi::EnumDisplayMonitors  twapi::GetMonitorInfo   twapi::MonitorFromPoint twapi::MonitorFromRect  twapi::MonitorFromWindow    twapi::EnumDisplayDevices   twapi::GetDeviceCaps    twapi::GetObject    twapi::ReleaseDC    twapi::GetWindowDC  twapi::GetDC    twapi::PdhLookupPerfNameByIndex twapi::PdhValidatePath  twapi::PdhGetFormattedCounterValue  twapi::PdhCollectQueryData  twapi::PdhRemoveCounter twapi::PdhAddCounter    twapi::PdhCloseQuery    twapi::PdhOpenQuery twapi::PdhSetDefaultRealTimeDataSource  twapi::PdhBrowseCounters    twapi::PdhParseCounterPath  twapi::PdhMakeCounterPath   twapi::PdhEnumObjectItems   twapi::PdhEnumObjects   twapi::PdhConnectMachine    twapi::PdhGetDllVersion twapi::UnregisterConsoleEventNotifier   twapi::RegisterConsoleEventNotifier twapi::ReadConsole  twapi::SetConsoleActiveScreenBuffer twapi::WriteConsoleOutputCharacter  twapi::WriteConsole twapi::SetStdHandle twapi::SetConsoleWindowInfo twapi::SetConsoleTitle  twapi::SetConsoleTextAttribute  twapi::SetConsoleScreenBufferSize   twapi::SetConsoleOutputCP   twapi::SetConsoleMode   twapi::SetConsoleCursorPosition twapi::SetConsoleCP twapi::GetStdHandle twapi::GetNumberOfConsoleMouseButtons   twapi::GetNumberOfConsoleInputEvents    twapi::GetLargestConsoleWindowSize  twapi::GetConsoleWindow twapi::GetConsoleTitle  twapi::GetConsoleScreenBufferInfo   twapi::GetConsoleOutputCP   twapi::GetConsoleMode   twapi::GetConsoleCP twapi::GenerateConsoleCtrlEvent twapi::FreeConsole  twapi::FlushConsoleInputBuffer  twapi::FillConsoleOutputCharacter   twapi::FillConsoleOutputAttribute   twapi::CreateConsoleScreenBuffer    twapi::AllocConsole twapi::Twapi_IsEventLogFull twapi::GetOldestEventLogRecord  twapi::GetNumberOfEventLogRecords   twapi::ClearEventLog    twapi::BackupEventLog   twapi::CloseEventLog    twapi::ReadEventLog twapi::OpenBackupEventLog   twapi::OpenEventLog twapi::DeregisterEventSource    twapi::ReportEvent  twapi::RegisterEventSource  twapi::Twapi_StopServiceThread  twapi::Twapi_SetServiceStatus   twapi::Twapi_BecomeAService twapi::QueryServiceStatusEx twapi::CloseServiceHandle   twapi::EnumDependentServices    twapi::EnumServicesStatusEx twapi::EnumServicesStatus   twapi::ChangeServiceConfig  twapi::GetServiceDisplayName    twapi::GetServiceKeyName    twapi::QueryServiceConfig   twapi::QueryServiceStatus   twapi::ControlService   twapi::StartService twapi::DeleteService    twapi::CreateService    twapi::OpenService  twapi::QueryServiceLockStatus   twapi::UnlockServiceDatabase    twapi::LockServiceDatabase  twapi::OpenSCManager    twapi::SERVICE_STATUS   twapi::delete_SERVICE_STATUS    twapi::new_SERVICE_STATUS   twapi::SERVICE_STATUS_dwWaitHint_get    twapi::SERVICE_STATUS_dwWaitHint_set    twapi::SERVICE_STATUS_dwCheckPoint_get  twapi::SERVICE_STATUS_dwCheckPoint_set  twapi::SERVICE_STATUS_dwServiceSpecificExitCode_get twapi::SERVICE_STATUS_dwServiceSpecificExitCode_set twapi::SERVICE_STATUS_dwWin32ExitCode_get   twapi::SERVICE_STATUS_dwWin32ExitCode_set   twapi::SERVICE_STATUS_dwControlsAccepted_get    twapi::SERVICE_STATUS_dwControlsAccepted_set    twapi::SERVICE_STATUS_dwCurrentState_get    twapi::SERVICE_STATUS_dwCurrentState_set    twapi::SERVICE_STATUS_dwServiceType_get twapi::SERVICE_STATUS_dwServiceType_set twapi::Twapi_SHFileOperation    twapi::SHInvokePrinterCommand   twapi::Twapi_InvokeUrlShortcut  twapi::Twapi_ReadUrlShortcut    twapi::Twapi_WriteUrlShortcut   twapi::Twapi_ReadShortcut   twapi::Twapi_WriteShortcut  twapi::Twapi_GetShellVersion    twapi::TwapiThemeDefineValue    twapi::GetThemeFont twapi::GetThemeColor    twapi::GetCurrentThemeName  twapi::IsAppThemed  twapi::IsThemeActive    twapi::CloseThemeData   twapi::OpenThemeData    twapi::SHObjectProperties   twapi::SHGetPathFromIDList  twapi::SHGetSpecialFolderLocation   twapi::SHGetSpecialFolderPath   twapi::SHGetFolderPath  twapi::SystemTimeToVariantTime  twapi::VariantTimeToSystemTime  twapi::OleRun   twapi::CreateFileMoniker    twapi::CreateBindCtx    twapi::IEnumVARIANT_Next    twapi::IRecordInfo_GetFieldNames    twapi::GetRecordInfoFromGuids   twapi::GetRecordInfoFromTypeInfo    twapi::ITypeLib_GetLibAttr  twapi::QueryPathOfRegTypeLib    twapi::UnRegisterTypeLib    twapi::RegisterTypeLib  twapi::LoadRegTypeLib   twapi::LoadTypeLibEx    twapi::ITypeComp_Bind   twapi::ITypeInfo_GetNames   twapi::ITypeInfo_GetIDsOfNames  twapi::ITypeInfo_GetFuncDesc    twapi::ITypeInfo_GetVarDesc twapi::ITypeInfo_GetTypeAttr    twapi::ConvertToIUnknown    twapi::IDispatch_GetIDsOfNames  twapi::Twapi_GetObjectIDispatch twapi::IUnknown_QueryInterface  twapi::GetActiveObject  twapi::Twapi_CoCreateInstance   twapi::CLSIDFromString  twapi::ProgIDFromCLSID  twapi::CLSIDFromProgID  twapi::IIDFromString    twapi::GetOEMCP twapi::GetACP   twapi::GetLocaleInfo    twapi::GetThreadLocale  twapi::GetCurrencyFormat    twapi::GetNumberFormat  twapi::GetSystemDefaultUILanguage   twapi::GetUserDefaultUILanguage twapi::GetSystemDefaultLCID twapi::GetUserDefaultLCID   twapi::GetSystemDefaultLangID   twapi::GetUserDefaultLangID twapi::MonitorClipboardStop twapi::MonitorClipboardStart    twapi::RegisterClipboardFormat  twapi::IsClipboardFormatAvailable   twapi::GetClipboardOwner    twapi::GetClipboardFormatName   twapi::Twapi_EnumClipboardFormats   twapi::GetOpenClipboardWindow   twapi::GetClipboardData twapi::SetClipboardData twapi::EmptyClipboard   twapi::CloseClipboard   twapi::OpenClipboard    twapi::MapVirtualKey    twapi::GetKeyState  twapi::GetAsyncKeyState twapi::GetLastInputInfo twapi::GetDoubleClickTime   twapi::SetThreadDesktop twapi::GetThreadDesktop twapi::SwitchDesktop    twapi::CloseDesktop twapi::OpenInputDesktop twapi::CreateDesktop    twapi::OpenDesktop  twapi::EnumDesktops twapi::EnumDesktopWindows   twapi::EnumWindowStations   twapi::CloseWindowStation   twapi::CreateWindowStation  twapi::OpenWindowStation    twapi::SetProcessWindowStation  twapi::GetProcessWindowStation  twapi::SetLayeredWindowAttributes   twapi::CreateWindowEx   twapi::BlockInput   twapi::UnregisterHotKey twapi::RegisterHotKey   twapi::SetCursorPos twapi::GetCursorPos twapi::PlaySound    twapi::Twapi_SendUnicode    twapi::SendInput    twapi::ArrangeIconicWindows twapi::AttachThreadInput    twapi::SetCaretPos  twapi::GetCaretPos  twapi::ShowCaret    twapi::HideCaret    twapi::SetCaretBlinkTime    twapi::GetCaretBlinkTime    twapi::MessageBeep  twapi::Beep twapi::FlashWindow  twapi::UpdateWindow twapi::MoveWindow   twapi::InvalidateRect   twapi::WindowFromPoint  twapi::SetWindowPlacement   twapi::GetWindowPlacement   twapi::GetWindowInfo    twapi::GetWindowRect    twapi::GetClientRect    twapi::SetFocus twapi::PostMessage  twapi::SendNotifyMessage    twapi::SendMessageTimeout   twapi::IsChild  twapi::IsWindowEnabled  twapi::IsWindowUnicode  twapi::IsWindow twapi::IsWindowVisible  twapi::IsZoomed twapi::IsIconic twapi::DestroyWindow    twapi::CloseWindow  twapi::OpenIcon twapi::EnableWindow twapi::ShowOwnedPopups  twapi::ShowWindowAsync  twapi::ShowWindow   twapi::SetWindowText    twapi::GetWindowText    twapi::GetGUIThreadInfo twapi::GUITHREADINFO    twapi::delete_GUITHREADINFO twapi::new_GUITHREADINFO    twapi::GUITHREADINFO_rcCaret_get    twapi::GUITHREADINFO_rcCaret_set    twapi::GUITHREADINFO_hwndCaret_get  twapi::GUITHREADINFO_hwndCaret_set  twapi::GUITHREADINFO_hwndMoveSize_get   twapi::GUITHREADINFO_hwndMoveSize_set   twapi::GUITHREADINFO_hwndMenuOwner_get  twapi::GUITHREADINFO_hwndMenuOwner_set  twapi::GUITHREADINFO_hwndCapture_get    twapi::GUITHREADINFO_hwndCapture_set    twapi::GUITHREADINFO_hwndFocus_get  twapi::GUITHREADINFO_hwndFocus_set  twapi::GUITHREADINFO_hwndActive_get twapi::GUITHREADINFO_hwndActive_set twapi::GUITHREADINFO_flags_get  twapi::GUITHREADINFO_flags_set  twapi::GUITHREADINFO_cbSize_get twapi::GUITHREADINFO_cbSize_set twapi::GetWindowThreadProcessId twapi::SetWindowPos twapi::SetWindowLong    twapi::GetWindowLong    twapi::GetClassName twapi::RealGetWindowClass   twapi::FindWindowEx twapi::FindWindow   twapi::GetActiveWindow  twapi::SetActiveWindow  twapi::SetForegroundWindow  twapi::GetForegroundWindow  twapi::GetShellWindow   twapi::GetDesktopWindow twapi::GetWindow    twapi::GetAncestor  twapi::GetParent    twapi::EnumChildWindows twapi::EnumWindows  twapi::POINT    twapi::delete_POINT twapi::new_POINT    twapi::POINT_y_get  twapi::POINT_y_set  twapi::POINT_x_get  twapi::POINT_x_set  twapi::WINDOWPLACEMENT  twapi::delete_WINDOWPLACEMENT   twapi::new_WINDOWPLACEMENT  twapi::WINDOWPLACEMENT_rcNormalPosition_get twapi::WINDOWPLACEMENT_rcNormalPosition_set twapi::WINDOWPLACEMENT_ptMaxPosition_get    twapi::WINDOWPLACEMENT_ptMaxPosition_set    twapi::WINDOWPLACEMENT_ptMinPosition_get    twapi::WINDOWPLACEMENT_ptMinPosition_set    twapi::WINDOWPLACEMENT_showCmd_get  twapi::WINDOWPLACEMENT_showCmd_set  twapi::WINDOWPLACEMENT_flags_get    twapi::WINDOWPLACEMENT_flags_set    twapi::WINDOWPLACEMENT_length_get   twapi::WINDOWPLACEMENT_length_set   twapi::WINDOWINFO   twapi::delete_WINDOWINFO    twapi::new_WINDOWINFO   twapi::WINDOWINFO_wCreatorVersion_get   twapi::WINDOWINFO_wCreatorVersion_set   twapi::WINDOWINFO_atomWindowType_get    twapi::WINDOWINFO_atomWindowType_set    twapi::WINDOWINFO_cyWindowBorders_get   twapi::WINDOWINFO_cyWindowBorders_set   twapi::WINDOWINFO_cxWindowBorders_get   twapi::WINDOWINFO_cxWindowBorders_set   twapi::WINDOWINFO_dwWindowStatus_get    twapi::WINDOWINFO_dwWindowStatus_set    twapi::WINDOWINFO_dwExStyle_get twapi::WINDOWINFO_dwExStyle_set twapi::WINDOWINFO_dwStyle_get   twapi::WINDOWINFO_dwStyle_set   twapi::WINDOWINFO_rcClient_get  twapi::WINDOWINFO_rcClient_set  twapi::WINDOWINFO_rcWindow_get  twapi::WINDOWINFO_rcWindow_set  twapi::WINDOWINFO_cbSize_get    twapi::WINDOWINFO_cbSize_set    twapi::RECT twapi::delete_RECT  twapi::new_RECT twapi::RECT_bottom_get  twapi::RECT_bottom_set  twapi::RECT_right_get   twapi::RECT_right_set   twapi::RECT_top_get twapi::RECT_top_set twapi::RECT_left_get    twapi::RECT_left_set    twapi::SetFileTime  twapi::GetFileTime  twapi::MoveFileEx   twapi::GetFileType  twapi::Twapi_VerQueryValue_TRANSLATIONS twapi::Twapi_VerQueryValue_STRING   twapi::Twapi_VerQueryValue_FIXEDFILEINFO    twapi::VerLanguageName  twapi::Twapi_FreeFileVersionInfo    twapi::Twapi_GetFileVersionInfo twapi::UnregisterDirChangeNotifier  twapi::RegisterDirChangeNotifier    twapi::CreateFile   twapi::GetVolumePathName    twapi::GetVolumeNameForVolumeMountPoint twapi::DeleteVolumeMountPoint   twapi::SetVolumeMountPoint  twapi::FindVolumeMountPointClose    twapi::FindNextVolumeMountPoint twapi::FindFirstVolumeMountPoint    twapi::FindVolumeClose  twapi::FindNextVolume   twapi::FindFirstVolume  twapi::DefineDosDevice  twapi::QueryDosDevice   twapi::SetVolumeLabel   twapi::GetVolumeInformation twapi::GetLogicalDrives twapi::GetDriveType twapi::GetDiskFreeSpaceEx   twapi::Twapi_GetProcessList twapi::CommandLineToArgv    twapi::GetCommandLineW  twapi::GetExitCodeProcess   twapi::ReadProcessMemory    twapi::Twapi_NtQueryInformationThreadBasicInformation   twapi::Twapi_NtQueryInformationProcessBasicInformation  twapi::GetThreadPriority    twapi::SetThreadPriority    twapi::GetPriorityClass twapi::SetPriorityClass twapi::SuspendThread    twapi::ResumeThread twapi::CreateProcessAsUser  twapi::CreateProcess    twapi::WaitForInputIdle twapi::OpenThread   twapi::GetCurrentThread twapi::GetCurrentThreadId   twapi::EnumDeviceDrivers    twapi::EnumProcessModules   twapi::EnumProcesses    twapi::GetModuleInformation twapi::GetDeviceDriverBaseName  twapi::GetDeviceDriverFileName  twapi::GetModuleBaseName    twapi::GetModuleFileNameEx  twapi::TerminateProcess twapi::GetCurrentProcess    twapi::OpenProcess  twapi::Wow64RevertWow64FsRedirection    twapi::Wow64DisableWow64FsRedirection   twapi::Wow64EnableWow64FsRedirection    twapi::SystemTimeToFileTime twapi::FileTimeToSystemTime twapi::GetTickCount twapi::GetSystemTimeAsFileTime  twapi::GetProfileType   twapi::UnloadUserProfile    twapi::Twapi_LoadUserProfile    twapi::Twapi_SystemPagefileInformation  twapi::Twapi_SystemProcessorTimes   twapi::SystemParametersInfo twapi::GlobalMemoryStatus   twapi::GetPrivateProfileSectionNames    twapi::GetPrivateProfileSection twapi::WriteProfileString   twapi::WritePrivateProfileString    twapi::GetProfileString twapi::GetPrivateProfileString  twapi::GetProfileInt    twapi::GetPrivateProfileInt twapi::GetSystemInfo    twapi::FreeLibrary  twapi::LoadLibraryEx    twapi::FormatMessageFromString  twapi::FormatMessageFromModule  twapi::ExpandEnvironmentStrings twapi::AbortSystemShutdown  twapi::InitiateSystemShutdown   twapi::GetComputerNameEx    twapi::GetComputerName  twapi::GetVersionEx twapi::OSVERSIONINFOEXW twapi::delete_OSVERSIONINFOEXW  twapi::new_OSVERSIONINFOEXW twapi::OSVERSIONINFOEXW_wReserved_get   twapi::OSVERSIONINFOEXW_wReserved_set   twapi::OSVERSIONINFOEXW_wProductType_get    twapi::OSVERSIONINFOEXW_wProductType_set    twapi::OSVERSIONINFOEXW_wSuiteMask_get  twapi::OSVERSIONINFOEXW_wSuiteMask_set  twapi::OSVERSIONINFOEXW_wServicePackMinor_get   twapi::OSVERSIONINFOEXW_wServicePackMinor_set   twapi::OSVERSIONINFOEXW_wServicePackMajor_get   twapi::OSVERSIONINFOEXW_wServicePackMajor_set   twapi::OSVERSIONINFOEXW_szCSDVersion_get    twapi::OSVERSIONINFOEXW_szCSDVersion_set    twapi::OSVERSIONINFOEXW_dwPlatformId_get    twapi::OSVERSIONINFOEXW_dwPlatformId_set    twapi::OSVERSIONINFOEXW_dwBuildNumber_get   twapi::OSVERSIONINFOEXW_dwBuildNumber_set   twapi::OSVERSIONINFOEXW_dwMinorVersion_get  twapi::OSVERSIONINFOEXW_dwMinorVersion_set  twapi::OSVERSIONINFOEXW_dwMajorVersion_get  twapi::OSVERSIONINFOEXW_dwMajorVersion_set  twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_get twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_set twapi::Twapi_LsaQueryInformationPolicy  twapi::LsaGetLogonSessionData   twapi::LsaEnumerateLogonSessions    twapi::Twapi_LsaRemoveAccountRights twapi::Twapi_LsaAddAccountRights    twapi::Twapi_LsaEnumerateAccountsWithUserRight  twapi::Twapi_LsaEnumerateAccountRights  twapi::LsaClose twapi::Twapi_LsaOpenPolicy  twapi::GetUserNameEx    twapi::LockWorkStation  twapi::ExitWindowsEx    twapi::AllocateLocallyUniqueId  twapi::UuidCreateNil    twapi::UuidCreate   twapi::DuplicateTokenEx twapi::SetThreadToken   twapi::ImpersonateSelf  twapi::RevertToSelf twapi::ImpersonateLoggedOnUser  twapi::LogonUser    twapi::SetSecurityInfo  twapi::Twapi_GetSecurityInfo    twapi::SetNamedSecurityInfo twapi::Twapi_GetNamedSecurityInfo   twapi::IsValidSecurityDescriptor    twapi::IsValidAcl   twapi::Twapi_InitializeSecurityDescriptor   twapi::Twapi_NetLocalGroupDelMember twapi::Twapi_NetLocalGroupAddMember twapi::NetGroupDelUser  twapi::NetGroupAddUser  twapi::NetLocalGroupDel twapi::NetGroupDel  twapi::NetLocalGroupAdd twapi::NetGroupAdd  twapi::Twapi_AdjustTokenPrivileges  twapi::Twapi_PrivilegeCheck twapi::IsValidSid   twapi::LookupPrivilegeValue twapi::LookupPrivilegeDisplayName   twapi::LookupPrivilegeName  twapi::Twapi_NetUserSetInfo_home_dir_drive  twapi::Twapi_NetUserSetInfo_profile twapi::Twapi_NetUserSetInfo_country_code    twapi::Twapi_NetUserSetInfo_acct_expires    twapi::Twapi_NetUserSetInfo_full_name   twapi::Twapi_NetUserSetInfo_auth_flags  twapi::Twapi_NetUserSetInfo_script_path twapi::Twapi_NetUserSetInfo_flags   twapi::Twapi_NetUserSetInfo_comment twapi::Twapi_NetUserSetInfo_home_dir    twapi::Twapi_NetUserSetInfo_priv    twapi::Twapi_NetUserSetInfo_password    twapi::Twapi_NetUserSetInfo_name    twapi::NetLocalGroupGetInfo twapi::NetGroupGetInfo  twapi::NetUserGetInfo   twapi::NetGroupGetUsers twapi::NetLocalGroupGetMembers  twapi::NetUserGetLocalGroups    twapi::NetUserGetGroups twapi::NetLocalGroupEnum    twapi::NetGroupEnum twapi::Twapi_NetUserEnum    twapi::NetUserDel   twapi::NetUserAdd   twapi::Twapi_SetTokenOwner  twapi::Twapi_SetTokenPrimaryGroup   twapi::GetTokenInformation  twapi::LookupAccountSid twapi::LookupAccountName    twapi::TwapiGetSidStringRep twapi::OpenThreadToken  twapi::OpenProcessToken twapi::free twapi::malloc   twapi::CastToHANDLE twapi::CloseHandle  twapi::GlobalSize   twapi::GlobalUnlock twapi::GlobalLock   twapi::GlobalFree   twapi::GlobalReAlloc    twapi::GlobalAlloc  twapi::Twapi_WriteMemoryUnicode twapi::Twapi_WriteMemoryChars   twapi::Twapi_WriteMemoryBinary  twapi::Twapi_WriteMemoryInt twapi::Twapi_ReadMemoryUnicode  twapi::Twapi_ReadMemoryChars    twapi::Twapi_ReadMemoryBinary   twapi::Twapi_ReadMemoryInt  twapi::win32_error  twapi::Twapi_MapWindowsErrorToString    twapi::Twapi_AddressToPointer   twapi::ADDRESS_LITERAL2HANDLE   twapi::HANDLE2ADDRESS_LITERAL   SERVICE_STATUS  -dwWaitHint -dwCheckPoint   -dwServiceSpecificExitCode  -dwWin32ExitCode    -dwControlsAccepted -dwCurrentState -dwServiceType  GUITHREADINFO   -rcCaret    -hwndCaret  -hwndMoveSize   -hwndMenuOwner  -hwndCapture    -hwndFocus  -hwndActive POINT   -y  -x  WINDOWPLACEMENT -rcNormalPosition   -ptMaxPosition  -ptMinPosition  -showCmd    -flags  -length WINDOWINFO  -wCreatorVersion    -atomWindowType -cyWindowBorders    -cxWindowBorders    -dwWindowStatus -dwExStyle  -dwStyle    -rcClient   -rcWindow   -cbSize RECT    -bottom -right  -top    -left   OSVERSIONINFOEXW    -wReserved  -wProductType   -wSuiteMask -wServicePackMinor  -wServicePackMajor  -szCSDVersion   -dwPlatformId   -dwBuildNumber  -dwMinorVersion -dwMajorVersion -dwOSVersionInfoSize    userdefined record  lpwstr  lpstr   void    hresult uint    ui8 i8  ui4 ui2 i1  decimal ui1 iunknown    variant error   idispatch   bstr    date    cy  r8  r4  ptr i4  i2  No constructor available.   wrong # args.   -args   -this   swig: internal runtime error. No class object defined.  Type error. Expected a pointer  Type error. Expected    cget    NULL    Invalid method. Must be one of: configure cget -acquire -disown -delete Invalid attribute name. 0   1   configure   -thisown    -delete -disown -acquire    RtlNtStatusToDosError   ntdll.dll   Buffer too small    % s \ % s   Error looking up account name:  Unknown token information type  Unsupported token information type  Could not convert token source to LUID  Error getting security token information:   %.8x-%.8x    invalid     field.     user name   password    privilege level home directory  comment flags   script path Error adding user account:  Invalid or unsupported user or group information level specified    Could not retrieve global user or group information:    Internal error: bad type passed to TwapiNetUserOrGroupGetInfoHelper usri3_name  usri3_script_path   usri3_flags usri3_comment   usri3_home_dir  usri3_priv  usri3_password_age  usri3_password  usri3_code_page usri3_country_code  usri3_logon_server  usri3_num_logons    usri3_bad_pw_count  usri3_logon_hours   usri3_units_per_week    usri3_max_storage   usri3_acct_expires  usri3_last_logoff   usri3_last_logon    usri3_workstations  usri3_parms usri3_usr_comment   usri3_full_name usri3_auth_flags    usri3_password_expired  usri3_home_dir_drive    usri3_profile   usri3_primary_group_id  usri3_user_id   grpi3_name  grpi3_comment   grpi3_group_sid grpi2_group_id  grpi3_attributes    lgrpi1_comment  lgrpi1_name Could not allocate memory   Unsupported SECURITY_DESCRIPTOR version Could not allocate Tcl object   null    NULL ACE pointer    Could not enumerate account rights:     Could not enumerate accounts with specified privileges:     Could not add account rights:   Could not remove account rights:    Upn DnsDomainName   LogonServer LogonTime   Sid Session LogonType   AuthenticationPackage   LogonDomain UserName    LogonId Invalid or unsupported information class passed to Twapi_LsaQueryInformationPolicy  Access violation in FormatMessage. Most likely, number of supplied arguments do not match those in format string    Exception %x raised by FormatMessage    InterruptCount  InterruptTime   DpcTime UserTime    KernelTime  IdleTime    NtQuerySystemInformation    FileName    PeakUsed    TotalUsed   CurrentSize Wow64EnableWow64FsRedirection   kernel32.dll    Wow64DisableWow64FsRedirection  Wow64RevertWow64FsRedirection   ContextSwitchCount  WaitTime    WaitReason  State   StartAddress    Priority    ClientId.UniqueThread   ClientId.UniqueProcess  Threads IoCounters.OtherTransferCount   IoCounters.WriteTransferCount   IoCounters.ReadTransferCount    IoCounters.OtherOperationCount  IoCounters.WriteOperationCount  IoCounters.ReadOperationCount   VmCounters.PeakPagefileUsage    VmCounters.PagefileUsage    VmCounters.QuotaNonPagedPoolUsage   VmCounters.QuotaPeakNonPagedPoolUsage   VmCounters.QuotaPagedPoolUsage  VmCounters.QuotaPeakPagedPoolUsage  VmCounters.WorkingSetSize   VmCounters.PeakWorkingSetSize   VmCounters.PageFaultCount   VmCounters.VirtualSize  VmCounters.PeakVirtualSize  CreateTime  ThreadCount HandleCount ProcessName BasePriority    SessionId   InheritedFromProcessId  ProcessId   0x%X    error retrieving process/module/driver ids:     Invalid number of standard handles in STARTUPINFO structure _ _ n u l l _ _     Invalid number of list elements for STARTUPINFO structure   NtQueryInformationProcess   NtQueryInformationThread    dwFileDateLS    dwFileDateMS    dwFileSubtype   dwFileType  dwFileOS    dwFileFlags dwFileFlagsMask dwProductVersionLS  dwProductVersionMS  dwFileVersionLS dwFileVersionMS dwStrucVersion  dwSignature \   \ S t r i n g F i l e I n f o \ % s \ % s   %04x%04x    \VarFileInfo\Translation    Need to specify exactly 4 integers for a RECT structure Need to specify exactly 2 integers for a POINT structure    lfFaceName  lfPitchAndFamily    lfQuality   lfClipPrecision lfOutPrecision  lfCharSet   lfStrikeOut lfUnderline lfItalic    lfWeight    lfOrientation   lfEscapement    lfWidth lfHeight    Error sending input events:     Invalid value specified for virtual key code. Must be between 1 and 254 Invalid value specified for scan code. Must be between 1 and 65535  Missing field in event of type key  Missing field in event of type mouse    Unknown field event type    Invalid or empty element specified in input event list  input event type    mouse   key Invalid or unsupported VARTYPE token (%s)   <null pointer>  _p_%s   idldescType tdescAlias  wMinorVerNum    wMajorVerNum    wTypeFlags  cbAlignment cbSizeVft   cImplTypes  cVars   cFuncs  typekind    cbSizeInstance  lpstrSchema memidDestructor memidConstructor    dwReserved  lcid    guid    Internal error: ObjFromTYPEDESC: NULL TYPEDESC pointer  wVarFlags   varkind elemdescVar.paramdesc   elemdescVar.tdesc   oInst   lpvarValue  memid   lprgelemdescParam   lprgscode   elemdescFunc.paramdesc  elemdescFunc.tdesc  wFuncFlags  oVft    cParamsOpt  cParams callconv    invkind funckind    wLibFlags   syskind Internal error while constructing referenced VARIANT parameter  Insufficient memory Missing value and no default for IDispatch invoke parameter Unknown parameter modifiers out in  Unsupported or invalid type information format in parameter Invalid or unsupported VARTYPE (%d) funcdesc    vardesc typecomp    Unsupported ITypeComp desckind value    %u.%u.%u    shell32.dll SHGetSpecialFolderPathW SHGetFolderPathW    SHObjectProperties  Invalid theme symbol '  TMT_FONT    TMT_GLYPHTYPE   TMT_BLENDCOLOR  TMT_ACCENTCOLORHINT TMT_BORDERCOLORHINT TMT_FILLCOLORHINT   TMT_GLYPHTRANSPARENTCOLOR   TMT_GLYPHTEXTCOLOR  TMT_TEXTSHADOWCOLOR TMT_TEXTBORDERCOLOR TMT_GLOWCOLOR   TMT_SHADOWCOLOR TMT_GRADIENTCOLOR5  TMT_GRADIENTCOLOR4  TMT_GRADIENTCOLOR3  TMT_GRADIENTCOLOR2  TMT_GRADIENTCOLOR1  TMT_TRANSPARENTCOLOR    TMT_EDGEFILLCOLOR   TMT_EDGEDKSHADOWCOLOR   TMT_EDGESHADOWCOLOR TMT_EDGEHIGHLIGHTCOLOR  TMT_EDGELIGHTCOLOR  TMT_TEXTCOLOR   TMT_FILLCOLOR   TMT_BORDERCOLOR VTS_PUSHED  VTS_NORMAL  VTS_HOT VTS_DISABLED    WP_VERTTHUMB    VSS_PUSHED  VSS_NORMAL  VSS_HOT VSS_DISABLED    WP_VERTSCROLL   WP_SYSBUTTON    WP_SMALLMINCAPTION  WP_SMALLMAXCAPTION  WP_SMALLFRAMERIGHTSIZINGTEMPLATE    WP_SMALLFRAMERIGHT  WP_SMALLFRAMELEFTSIZINGTEMPLATE WP_SMALLFRAMELEFT   WP_SMALLFRAMEBOTTOMSIZINGTEMPLATE   WP_SMALLFRAMEBOTTOM WP_SMALLCLOSEBUTTON WP_SMALLCAPTIONSIZINGTEMPLATE   WP_SMALLCAPTION WP_RESTOREBUTTON    MNCS_INACTIVE   MNCS_DISABLED   MNCS_ACTIVE WP_MINCAPTION   WP_MINBUTTON    SBS_PUSHED  SBS_NORMAL  SBS_HOT SBS_DISABLED    WP_MDISYSBUTTON RBS_PUSHED  RBS_NORMAL  RBS_HOT RBS_DISABLED    WP_MDIRESTOREBUTTON MINBS_PUSHED    MINBS_NORMAL    MINBS_HOT   MINBS_DISABLED  WP_MDIMINBUTTON WP_MDIHELPBUTTON    WP_MDICLOSEBUTTON   MXCS_INACTIVE   MXCS_DISABLED   MXCS_ACTIVE WP_MAXCAPTION   MAXBS_PUSHED    MAXBS_NORMAL    MAXBS_HOT   MAXBS_DISABLED  HTS_PUSHED  HTS_NORMAL  HTS_HOT HTS_DISABLED    WP_HORZTHUMB    HSS_PUSHED  HSS_NORMAL  HSS_HOT HSS_DISABLED    WP_HORZSCROLL   HBS_PUSHED  HBS_NORMAL  HBS_HOT HBS_DISABLED    WP_HELPBUTTON   WP_FRAMERIGHTSIZINGTEMPLATE WP_FRAMERIGHT   WP_FRAMELEFTSIZINGTEMPLATE  WP_FRAMELEFT    WP_FRAMEBOTTOMSIZINGTEMPLATE    FS_INACTIVE FS_ACTIVE   WP_FRAMEBOTTOM  WP_DIALOG   CBS_PUSHED  CBS_NORMAL  CBS_HOT CBS_DISABLED    WP_CLOSEBUTTON  WP_CAPTIONSIZINGTEMPLATE    CS_INACTIVE CS_DISABLED CS_ACTIVE   WP_CAPTION  TREIS_SELECTEDNOTFOCUS  TREIS_SELECTED  TREIS_NORMAL    TREIS_HOT   TREIS_DISABLED  TVP_TREEITEM    GLPS_OPENED GLPS_CLOSED TVP_GLYPH   TVP_BRANCH  TNP_BACKGROUND  TNP_ANIMBACKGROUND  TRVS_NORMAL TKP_TRACKVERT   TRS_NORMAL  TKP_TRACK   TSVS_NORMAL TKP_TICSVERT    TSS_NORMAL  TKP_TICS    TUVS_PRESSED    TUVS_NORMAL TUVS_HOT    TUVS_FOCUSED    TUVS_DISABLED   TKP_THUMBVERT   TUTS_PRESSED    TUTS_NORMAL TUTS_HOT    TUTS_FOCUSED    TUTS_DISABLED   TKP_THUMBTOP    TUVRS_PRESSED   TUVRS_NORMAL    TUVRS_HOT   TUVRS_FOCUSED   TUVRS_DISABLED  TKP_THUMBRIGHT  TUVLS_PRESSED   TUVLS_NORMAL    TUVLS_HOT   TUVLS_FOCUSED   TUVLS_DISABLED  TKP_THUMBLEFT   TUBS_PRESSED    TUBS_NORMAL TUBS_HOT    TUBS_FOCUSED    TUBS_DISABLED   TKP_THUMBBOTTOM TUS_PRESSED TUS_NORMAL  TUS_HOT TUS_FOCUSED TUS_DISABLED    TKP_THUMB   TTP_STANDARDTITLE   TTSS_NORMAL TTSS_LINK   TTP_STANDARD    TTCS_PRESSED    TTCS_NORMAL TTCS_HOT    TTP_CLOSE   TTP_BALLOONTITLE    TTBS_NORMAL TTBS_LINK   TTP_BALLOON TP_SEPARATORVERT    TP_SEPARATOR    TP_SPLITBUTTONDROPDOWN  TP_SPLITBUTTON  TP_DROPDOWNBUTTON   TS_PRESSED  TS_NORMAL   TS_HOTCHECKED   TS_HOT  TS_DISABLED TS_CHECKED  TP_BUTTON   TBP_SIZINGBARTOP    TBP_SIZINGBARRIGHT  TBP_SIZINGBARBOTTOM TBP_BACKGROUNDTOP   TBP_BACKGROUNDRIGHT TBP_BACKGROUNDLEFT  TBP_BACKGROUNDBOTTOM    TDP_FLASHBUTTONGROUPMENU    TDP_FLASHBUTTON TDP_GROUPCOUNT  TTIRES_SELECTED TTIRES_NORMAL   TTIRES_HOT  TTIRES_FOCUSED  TTIRES_DISABLED TABP_TOPTABITEMRIGHTEDGE    TTILES_SELECTED TTILES_NORMAL   TTILES_HOT  TTILES_FOCUSED  TTILES_DISABLED TABP_TOPTABITEMLEFTEDGE TTIBES_SELECTED TTIBES_NORMAL   TTIBES_HOT  TTIBES_FOCUSED  TTIBES_DISABLED TABP_TOPTABITEMBOTHEDGE TTIS_SELECTED   TTIS_NORMAL TTIS_HOT    TTIS_FOCUSED    TTIS_DISABLED   TABP_TOPTABITEM TIRES_SELECTED  TIRES_NORMAL    TIRES_HOT   TIRES_FOCUSED   TIRES_DISABLED  TABP_TABITEMRIGHTEDGE   TILES_SELECTED  TILES_NORMAL    TILES_HOT   TILES_FOCUSED   TILES_DISABLED  TABP_TABITEMLEFTEDGE    TIBES_SELECTED  TIBES_NORMAL    TIBES_HOT   TIBES_FOCUSED   TIBES_DISABLED  TABP_TABITEMBOTHEDGE    TIS_SELECTED    TIS_NORMAL  TIS_HOT TIS_FOCUSED TIS_DISABLED    TABP_TABITEM    TABP_PANE   TABP_BODY   SP_GRIPPERPANE  SP_PANE SP_GRIPPER  SPP_USERPICTURE SPP_USERPANE    SPP_PROGLISTSEPARATOR   SPP_PROGLIST    SPP_PREVIEW SPP_PLACESLISTSEPARATOR SPP_PLACESLIST  SPS_PRESSED SPS_NORMAL  SPS_HOT SPP_MOREPROGRAMSARROW   SPP_MOREPROGRAMS    SPLS_PRESSED    SPLS_NORMAL SPLS_HOT    SPP_LOGOFFBUTTONS   SPP_LOGOFF  SPNP_UPHORZ SPNP_UP SPNP_DOWNHORZ   SPNP_DOWN   SZB_RIGHTALIGN  SZB_LEFTALIGN   SBP_SIZEBOX SBP_UPPERTRACKVERT  SBP_UPPERTRACKHORZ  SBP_THUMBBTNVERT    SBP_THUMBBTNHORZ    SBP_LOWERTRACKVERT  SCRBS_PRESSED   SCRBS_NORMAL    SCRBS_HOT   SCRBS_DISABLED  SBP_LOWERTRACKHORZ  SBP_GRIPPERVERT SBP_GRIPPERHORZ ABS_RIGHTPRESSED    ABS_RIGHTNORMAL ABS_RIGHTHOT    ABS_RIGHTDISABLED   ABS_LEFTPRESSED ABS_LEFTNORMAL  ABS_LEFTHOT ABS_LEFTDISABLED    ABS_UPPRESSED   ABS_UPNORMAL    ABS_UPHOT   ABS_UPDISABLED  ABS_DOWNPRESSED ABS_DOWNNORMAL  ABS_DOWNHOT ABS_DOWNDISABLED    SBP_ARROWBTN    RP_GRIPPERVERT  RP_GRIPPER  RP_CHEVRONVERT  CHEVS_PRESSED   CHEVS_NORMAL    CHEVS_HOT   RP_CHEVRON  RP_BAND PP_CHUNKVERT    PP_CHUNK    PP_BARVERT  PP_BAR  UPHZS_PRESSED   UPHZS_NORMAL    UPHZS_HOT   UPHZS_DISABLED  PGRP_UPHORZ UPS_PRESSED UPS_NORMAL  UPS_HOT UPS_DISABLED    PGRP_UP DNHZS_PRESSED   DNHZS_NORMAL    DNHZS_HOT   DNHZS_DISABLED  PGRP_DOWNHORZ   DNS_PRESSED DNS_NORMAL  DNS_HOT DNS_DISABLED    PGRP_DOWN   MDP_SEPERATOR   MDS_PRESSED MDS_NORMAL  MDS_HOTCHECKED  MDS_HOT MDS_DISABLED    MDS_CHECKED MDP_NEWAPPBUTTON    MP_SEPARATOR    MP_MENUITEM MP_MENUDROPDOWN MP_CHEVRON  MP_MENUBARITEM  MS_SELECTED MS_NORMAL   MS_DEMOTED  MP_MENUBARDROPDOWN  LVP_LISTSORTEDDETAIL    LIS_SELECTEDNOTFOCUS    LIS_SELECTED    LIS_NORMAL  LIS_HOT LIS_DISABLED    LVP_LISTITEM    LVP_LISTGROUP   LVP_LISTDETAIL  LVP_EMPTYTEXT   HSAS_SORTEDUP   HSAS_SORTEDDOWN HP_HEADERSORTARROW  HIRS_PRESSED    HIRS_NORMAL HIRS_HOT    HP_HEADERITEMRIGHT  HILS_PRESSED    HILS_NORMAL HILS_HOT    HP_HEADERITEMLEFT   HIS_PRESSED HIS_NORMAL  HIS_HOT HP_HEADERITEM   EBP_SPECIALGROUPHEAD    EBSGE_PRESSED   EBSGE_NORMAL    EBSGE_HOT   EBP_SPECIALGROUPEXPAND  EBSGC_PRESSED   EBSGC_NORMAL    EBSGC_HOT   EBP_SPECIALGROUPCOLLAPSE    EBP_SPECIALGROUPBACKGROUND  EBP_NORMALGROUPHEAD EBNGE_PRESSED   EBNGE_NORMAL    EBNGE_HOT   EBP_NORMALGROUPEXPAND   EBNGC_PRESSED   EBNGC_NORMAL    EBNGC_HOT   EBP_NORMALGROUPCOLLAPSE EBP_NORMALGROUPBACKGROUND   EBM_PRESSED EBM_NORMAL  EBM_HOT EBP_IEBARMENU   EBHP_SELECTEDPRESSED    EBHP_SELECTEDNORMAL EBHP_SELECTEDHOT    EBHP_PRESSED    EBHP_NORMAL EBHP_HOT    EBP_HEADERPIN   EBHC_PRESSED    EBHC_NORMAL EBHC_HOT    EBP_HEADERCLOSE EBP_HEADERBACKGROUND    ETS_SELECTED    ETS_READONLY    ETS_NORMAL  ETS_HOT ETS_FOCUSED ETS_DISABLED    ETS_ASSIST  EP_EDITTEXT EP_CARET    CBXS_PRESSED    CBXS_NORMAL CBXS_HOT    CBXS_DISABLED   CP_DROPDOWNBUTTON   CLS_NORMAL  CLP_TIME    BP_USERBUTTON   RBS_UNCHECKEDPRESSED    RBS_UNCHECKEDNORMAL RBS_UNCHECKEDHOT    RBS_UNCHECKEDDISABLED   RBS_CHECKEDPRESSED  RBS_CHECKEDNORMAL   RBS_CHECKEDHOT  RBS_CHECKEDDISABLED BP_RADIOBUTTON  PBS_PRESSED PBS_NORMAL  PBS_HOT PBS_DISABLED    PBS_DEFAULTED   BP_PUSHBUTTON   GBS_NORMAL  GBS_DISABLED    BP_GROUPBOX CBS_UNCHECKEDPRESSED    CBS_UNCHECKEDNORMAL CBS_UNCHECKEDHOT    CBS_UNCHECKEDDISABLED   CBS_MIXEDPRESSED    CBS_MIXEDNORMAL CBS_MIXEDHOT    CBS_MIXEDDISABLED   CBS_CHECKEDPRESSED  CBS_CHECKEDNORMAL   CBS_CHECKEDHOT  CBS_CHECKEDDISABLED BP_CHECKBOX -workdir    -showcmd    -path   -idl    -iconpath   -iconindex  -hotkey -desc   OpenThemeData   uxtheme.dll CloseThemeData  IsThemeActive   IsAppThemed GetCurrentThemeName #%2.2x%2.2x%2.2x    GetThemeColor   GetThemeFont    SHFileOperation failed  dwServiceFlags  dwProcessId dwWaitHint  dwCheckPoint    dwServiceSpecificExitCode   dwWin32ExitCode dwControlsAccepted  dwCurrentState  dwServiceType   Attempt to read more than 1024 console characters   C   error retrieving performance counter and instance names:    szCounterName   dwInstanceIndex szParentInstance    szInstanceName  szObjectName    szMachineName   Error (0x%x/0x%x) retrieving counter value:     Invalid PDH counter format value    0x%x    wRandomMinutesInterval  Reserved2   type    rgFlags MinutesInterval MinutesDuration wStartMinute    wStartHour  wEndDay wEndMonth   wEndYear    wBeginDay   wBeginMonth wBeginYear  Reserved1   Unknown TASK_TRIGGER field '    Invalid task trigger type format    Invalid TASK_TRIGGER format - must have even number of elements success disabled    notriggers  oneventonly Attributes  pServerName pPrinterName    pUserSid    pProcessName    Could not enumerate terminal server processes.  pWinStationName Could not enumerate terminal server sessions.   Could not query terminal session information.   ClientSiteName  DcSiteName  Flags   DnsForestName   DomainName  DomainGuid  DomainControllerAddressType DomainControllerAddress DomainControllerName    GetOwnerModuleFromTcpEntry  iphlpapi.dll    GetOwnerModuleFromUdpEntry  No adapter information exists for the local computer    No adapter information exists for the specified adapter GetExtendedTcpTable GetExtendedUdpTable AllocateAndGetTcpExTableFromStack   AllocateAndGetUdpExTableFromStack   \wship6 \ws2_32 �P�Z�P�_pPRZfreeaddrinfo    getnameinfo getaddrinfo tcp udp %u  65535   Invalid network share current connections parameter Invalid network share path parameter    Invalid network share password parameter    Invalid network share security descriptor parameter Invalid network share parameter Invalid network share maximum connections parameter Invalid network share name parameter    Invalid network share type parameter    Invalid network share remark parameter  Invalid network share permissions parameter Invalid or unsupported share information level specified    Could not retrieve share information:   Invalid info level for SHARE_INFO structure lpProvider  lpComment   lpRemoteName    lpLocalName dwUsage dwDisplayType   dwType  dwScope ui2_domainname  ui2_username    ui2_usecount    ui2_refcount    ui2_asg_type    ui2_status  ui2_password    ui2_remote  ui2_local   Invalid level specified.    cname   user_flags  idle_time   time    num_opens   username    cltype_name transport   id  netname num_users   pathname    num_locks   permissions Invalid security handle format  Comment Name    cbMaxToken  wRPCID  wVersion    fCapabilities   Invalid SecBuffer format    ok  continue    complete    complete_and_continue   incomplete_message  Unsupported QuerySecurityContext attribute id   Too many random bytes requested.    NtQueryObject   NtQueryInformationFile  Could not get object name information:  Could not get object type information:  Could not get basic object information:     < u n k n o w n >   Error getting channel handle    Unknown channel o:twapi::HANDLE2ADDRESS_LITERALh    Wrong # args.    argument   %d  Wrong # args.   Searching %s
   o:twapi::ADDRESS_LITERAL2HANDLEaddr     l:twapi::Twapi_AddressToPointeraddr     l:twapi::Twapi_MapWindowsErrorToStringerror     l|s:twapi::win32_errorerror DEFAULT_EMPTY_STRING    oi:twapi::Twapi_ReadMemoryIntbufP offset    oii:twapi::Twapi_ReadMemoryBinarybufP offset len    oi|i:twapi::Twapi_ReadMemoryCharsbufP offset DEFAULT_MINUS_ONE  oi|i:twapi::Twapi_ReadMemoryUnicodebufP offset DEFAULT_MINUS_ONE    oiii:twapi::Twapi_WriteMemoryIntbufP offset buf_size val    oiio:twapi::Twapi_WriteMemoryBinarybufP offset buf_size BINLEN BINDATA  oiis|i:twapi::Twapi_WriteMemoryCharsbufP offset buf_size utf8 DEFAULT_MINUS_ONE     oiio|i:twapi::Twapi_WriteMemoryUnicodebufP offset buf_size ucs16P DEFAULT_MINUS_ONE     il:twapi::GlobalAllocuFlags dwBytes     oli:twapi::GlobalReAllochMem dwBytes uFlags     o:twapi::GlobalFreehMem     o:twapi::GlobalLockhMem     o:twapi::GlobalUnlockhMem   o:twapi::GlobalSizehMem     o:twapi::CloseHandleh   o:twapi::CastToHANDLEh  i|s:twapi::mallocsize DEFAULT_EMPTY_STRING  o:twapi::freevoid *     ol:twapi::OpenProcessTokenProcessHandle DesiredAccess   oll:twapi::OpenThreadTokenThreadHandle DesiredAccess OpenAsSelf     o:twapi::TwapiGetSidStringRepsidP   oo:twapi::LookupAccountNamelpSystemName lpAccountName   oo:twapi::LookupAccountSidlpSystemName sidP     Error looking up account SID:   oi:twapi::GetTokenInformationtokenH token_class     oo:twapi::Twapi_SetTokenPrimaryGrouptokenH sidP     oo:twapi::Twapi_SetTokenOwnertokenH sidP    oooloolo:twapi::NetUserAddservername name password priv home_dir comment flags script_path  oo:twapi::NetUserDelservername username     ol:twapi::Twapi_NetUserEnumserver_name filter   o:twapi::NetGroupEnumserver_name    o:twapi::NetLocalGroupEnumserver_name   oo:twapi::NetUserGetGroupsserver_name user_name     ool:twapi::NetUserGetLocalGroupsserver_name user_name flags     oo:twapi::NetLocalGroupGetMembersserver_name group_name     oo:twapi::NetGroupGetUsersserver_name group_name    ool:twapi::NetUserGetInfoservername username level  ool:twapi::NetGroupGetInfoservername groupname level    ool:twapi::NetLocalGroupGetInfoservername groupname level   ooo:twapi::Twapi_NetUserSetInfo_nameservername username name    ooo:twapi::Twapi_NetUserSetInfo_passwordservername username password    ool:twapi::Twapi_NetUserSetInfo_privservername username priv    ooo:twapi::Twapi_NetUserSetInfo_home_dirservername username home_dir    ooo:twapi::Twapi_NetUserSetInfo_commentservername username comment  ool:twapi::Twapi_NetUserSetInfo_flagsservername username flags  ooo:twapi::Twapi_NetUserSetInfo_script_pathservername username script_path  ool:twapi::Twapi_NetUserSetInfo_auth_flagsservername username auth_flags    ooo:twapi::Twapi_NetUserSetInfo_full_nameservername username full_name  ool:twapi::Twapi_NetUserSetInfo_acct_expiresservername username acct_expires    ool:twapi::Twapi_NetUserSetInfo_country_codeservername username country_code    ooo:twapi::Twapi_NetUserSetInfo_profileservername username profile  ooo:twapi::Twapi_NetUserSetInfo_home_dir_driveservername username home_dir_drive    oo:twapi::LookupPrivilegeNamelpSystemName lpLuid counted_outbuf_size    Invalid LUID format:    oo:twapi::LookupPrivilegeDisplayNamelpSystemName lpPrivName counted_outbuf_size     oo:twapi::LookupPrivilegeValuelpSystemName lpPrivName   o:twapi::IsValidSidpsid     ooi:twapi::Twapi_PrivilegeChecktokenH INPUT all_required    
Invalid LUID_AND_ATTRIBUTES:   olo:twapi::Twapi_AdjustTokenPrivilegestokenH disableAll INPUT   ooo:twapi::NetGroupAddservername groupname comment  ooo:twapi::NetLocalGroupAddservername groupname comment     oo:twapi::NetGroupDelservername groupname   oo:twapi::NetLocalGroupDelservername groupname  ooo:twapi::NetGroupAddUserservername groupname username     ooo:twapi::NetGroupDelUserservername groupname username     ooo:twapi::Twapi_NetLocalGroupAddMemberservername groupname membername  ooo:twapi::Twapi_NetLocalGroupDelMemberservername groupname membername  :twapi::Twapi_InitializeSecurityDescriptor  o:twapi::IsValidAclaclP     Internal error constructing ACL Invalid ACL format. Should be 'null' or have exactly two elements   Invalid ACE format. o:twapi::IsValidSecurityDescriptorsecdP     Invalid control flags for SECURITY_DESCRIPTOR   Invalid SECURITY_DESCRIPTOR format. Should have 0 or five elements  oii:twapi::Twapi_GetNamedSecurityInfoname type wanted_fields    oiioooo:twapi::SetNamedSecurityInfoname type set_fields owner group dacl sacl   oii:twapi::Twapi_GetSecurityInfoh type wanted_fields    oiioooo:twapi::SetSecurityInfoh type wanted_fields owner group dacl sacl    oooll:twapi::LogonUserlpszUsername lpszDomain lpszPassword dwLogonType dwLogonProvider  o:twapi::ImpersonateLoggedOnUserhToken  :twapi::RevertToSelf    i:twapi::ImpersonateSelflevel   oo:twapi::SetThreadTokenthread token    oloii:twapi::DuplicateTokenExhExistingToken dwDesiredAccess lpTokenAttributes ImpersonationLevel TokenType  Invalid SECURITY_ATTRIBUTES format. Should have 0 or 2 elements i:twapi::UuidCreatelocal_ok     :twapi::UuidCreateNil   :twapi::AllocateLocallyUniqueId il:twapi::ExitWindowsExuFlags dwReason  :twapi::LockWorkStation i:twapi::GetUserNameExformat counted_outbuf_size    ol:twapi::Twapi_LsaOpenPolicySystemName DesiredAccess   o:twapi::LsaCloseObjectHandle   oo:twapi::Twapi_LsaEnumerateAccountRightsPolicyHandle AccountSid    oo:twapi::Twapi_LsaEnumerateAccountsWithUserRightPolicyHandle UserRights    ooo:twapi::Twapi_LsaAddAccountRightsPolicyHandle AccountSid LSASTRINGARRAY LSASTRINGARRAYCOUNT  ooio:twapi::Twapi_LsaRemoveAccountRightsPolicyHandle AccountSid AllRights LSASTRINGARRAY LSASTRINGARRAYCOUNT    :twapi::LsaEnumerateLogonSessions   o:twapi::LsaGetLogonSessionDataluidP    oi:twapi::Twapi_LsaQueryInformationPolicylsaH infoclass     ol:twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_setself dwOSVersionInfoSize  o:twapi::OSVERSIONINFOEXW_dwOSVersionInfoSize_getself   ol:twapi::OSVERSIONINFOEXW_dwMajorVersion_setself dwMajorVersion    o:twapi::OSVERSIONINFOEXW_dwMajorVersion_getself    ol:twapi::OSVERSIONINFOEXW_dwMinorVersion_setself dwMinorVersion    o:twapi::OSVERSIONINFOEXW_dwMinorVersion_getself    ol:twapi::OSVERSIONINFOEXW_dwBuildNumber_setself dwBuildNumber  o:twapi::OSVERSIONINFOEXW_dwBuildNumber_getself     ol:twapi::OSVERSIONINFOEXW_dwPlatformId_setself dwPlatformId    o:twapi::OSVERSIONINFOEXW_dwPlatformId_getself  oo:twapi::OSVERSIONINFOEXW_szCSDVersion_setself szCSDVersion    o:twapi::OSVERSIONINFOEXW_szCSDVersion_getself  oh:twapi::OSVERSIONINFOEXW_wServicePackMajor_setself wServicePackMajor  o:twapi::OSVERSIONINFOEXW_wServicePackMajor_getself     oh:twapi::OSVERSIONINFOEXW_wServicePackMinor_setself wServicePackMinor  o:twapi::OSVERSIONINFOEXW_wServicePackMinor_getself     oh:twapi::OSVERSIONINFOEXW_wSuiteMask_setself wSuiteMask    o:twapi::OSVERSIONINFOEXW_wSuiteMask_getself    ob:twapi::OSVERSIONINFOEXW_wProductType_setself wProductType    o:twapi::OSVERSIONINFOEXW_wProductType_getself  ob:twapi::OSVERSIONINFOEXW_wReserved_setself wReserved  o:twapi::OSVERSIONINFOEXW_wReserved_getself     :twapi::new_OSVERSIONINFOEXW    o:twapi::delete_OSVERSIONINFOEXWself    o:twapi::GetVersionExlpVersionInformation   :twapi::GetComputerNamecounted_outbuf_size  i:twapi::GetComputerNameExnamefmt counted_outbuf_size   oolll:twapi::InitiateSystemShutdownlpMachineName lpMessage dwTimeout bForceAppsClosed bRebootAfterShutdown  o:twapi::AbortSystemShutdownlpMachineName   o:twapi::ExpandEnvironmentStringslpSrc malloc_outbuf_size   lollo:twapi::FormatMessageFromModuledwFlags hModule dwMessageId dwLanguageId argc argv  loo:twapi::FormatMessageFromStringdwFlags fmtString argc argv   ol:twapi::LoadLibraryExlpFileName dwFlags   o:twapi::FreeLibraryhModule     :twapi::GetSystemInfo   ooio:twapi::GetPrivateProfileIntlpAppName lpKeyName nDefault lpFileName     ooi:twapi::GetProfileIntlpAppName lpKeyName nDefault    oooo:twapi::GetPrivateProfileStringlpAppName lpKeyName lpDefault malloc_outbuf_size lpFileName  ooo:twapi::GetProfileStringlpAppName lpKeyName lpDefault malloc_outbuf_size     oooo:twapi::WritePrivateProfileStringlpAppName lpKeyName lpString lpFileName    ooo:twapi::WriteProfileStringlpAppName lpKeyName lpString   oo:twapi::GetPrivateProfileSectionlpAppName lpFileName  o:twapi::GetPrivateProfileSectionNameslpFileName    :twapi::GlobalMemoryStatus  iioi:twapi::SystemParametersInfouiAction uiParam pvParam fWinIni    :twapi::Twapi_SystemProcessorTimes  :twapi::Twapi_SystemPagefileInformation oloo:twapi::Twapi_LoadUserProfilehToken flags username profilepath  oo:twapi::UnloadUserProfilehToken hProfile  :twapi::GetProfileType  :twapi::GetSystemTimeAsFileTime :twapi::GetTickCount    o:twapi::FileTimeToSystemTimelpFileTime     o:twapi::SystemTimeToFileTimelpSystemTime   b:twapi::Wow64EnableWow64FsRedirectionenable_redirection    :twapi::Wow64DisableWow64FsRedirection  o:twapi::Wow64RevertWow64FsRedirectionaddr  lll:twapi::OpenProcessdwDesiredAccess bInheritHandle dwProcessId    :twapi::GetCurrentProcess   oi:twapi::TerminateProcesshProcess uExitCode    oo:twapi::GetModuleFileNameExhProcess hModule counted_outbuf_size   oo:twapi::GetModuleBaseNamehProcess hModule counted_outbuf_size     o:twapi::GetDeviceDriverFileNamelpBase counted_outbuf_size  o:twapi::GetDeviceDriverBaseNamelpBase counted_outbuf_size  EntryPoint  SizeOfImage lpBaseOfDll oo:twapi::GetModuleInformationhProcess hModule cb   :twapi::EnumProcesses   o:twapi::EnumProcessModulesphandle  :twapi::EnumDeviceDrivers   :twapi::GetCurrentThreadId  :twapi::GetCurrentThread    lll:twapi::OpenThreaddwDesiredAccess bInheritHandle dwThreadId  ol:twapi::WaitForInputIdlehProcess dwMilliseconds   oooollooo:twapi::CreateProcesslpApplicationName lpCommandLine lpProcessAttributes lpThreadAttributes bInheritHandles dwCreationFlags lpEnvironment lpCurrentDirectory lpStartupInfo     ooooollooo:twapi::CreateProcessAsUserhToken lpApplicationName lpCommandLine lpProcessAttributes lpThreadAttributes bInheritHandles dwCreationFlags lpEnvironment lpCurrentDirectory lpStartupInfo   o:twapi::ResumeThreadhThread    o:twapi::SuspendThreadhThread   ol:twapi::SetPriorityClasshProcess dwPriorityClass  o:twapi::GetPriorityClasshProcess   oi:twapi::SetThreadPriorityhThread nPriority    o:twapi::GetThreadPriorityhThread   o:twapi::Twapi_NtQueryInformationProcessBasicInformationprocessH    o:twapi::Twapi_NtQueryInformationThreadBasicInformationthreadH  oool:twapi::ReadProcessMemoryhProcess lpBaseAddress lpBuffer nSize  o:twapi::GetExitCodeProcesshProcess     :twapi::GetCommandLineW o:twapi::CommandLineToArgvcmdlineP  ii:twapi::Twapi_GetProcessListpid detail    o:twapi::GetDiskFreeSpaceExdir  o:twapi::GetDriveTyperootpath   :twapi::GetLogicalDrives    o:twapi::GetVolumeInformationlpRootPathName counted_outbuf_size counted_outbuf_size     oo:twapi::SetVolumeLabelrootpath vollabel   o:twapi::QueryDosDevicelpDeviceName     loo:twapi::DefineDosDevicedwFlags lpDeviceName lpTargetPath     :twapi::FindFirstVolumecounted_outbuf_size  o:twapi::FindNextVolumefindH counted_outbuf_size    o:twapi::FindVolumeClosefindH   o:twapi::FindFirstVolumeMountPointvolumeNameP counted_outbuf_size   o:twapi::FindNextVolumeMountPointfindH counted_outbuf_size  o:twapi::FindVolumeMountPointClosefindH     oo:twapi::SetVolumeMountPointvolptP volnameP    o:twapi::DeleteVolumeMountPointvolptP   o:twapi::GetVolumeNameForVolumeMountPointvolptP counted_outbuf_size     o:twapi::GetVolumePathNamevolptP counted_outbuf_size    ollollo:twapi::CreateFilelpFileName dwDesiredAccess dwShareMode lpSecurityAttributes dwCreationDisposition dwFlagsAndAttributes hTemplateFile   ollso:twapi::RegisterDirChangeNotifierpath subtree filter script argc argv  i:twapi::UnregisterDirChangeNotifierid  o:twapi::Twapi_GetFileVersionInfopath   o:twapi::Twapi_FreeFileVersionInfoverP  l:twapi::VerLanguageNamelangid counted_outbuf_size  o:twapi::Twapi_VerQueryValue_FIXEDFILEINFOverP  ooo:twapi::Twapi_VerQueryValue_STRINGverP lang_and_cp name  o:twapi::Twapi_VerQueryValue_TRANSLATIONSverP   o:twapi::GetFileTypeh   ool:twapi::MoveFileExlpExistingFileName lpNewFileName dwFlags   o:twapi::GetFileTimeh   oooo:twapi::SetFileTimeh NULL_OK NULL_OK NULL_OK    ol:twapi::RECT_left_setself left    o:twapi::RECT_left_getself  ol:twapi::RECT_top_setself top  o:twapi::RECT_top_getself   ol:twapi::RECT_right_setself right  o:twapi::RECT_right_getself     ol:twapi::RECT_bottom_setself bottom    o:twapi::RECT_bottom_getself    :twapi::new_RECT    o:twapi::delete_RECTself    ol:twapi::WINDOWINFO_cbSize_setself cbSize  o:twapi::WINDOWINFO_cbSize_getself  oo:twapi::WINDOWINFO_rcWindow_setself rcWindow  o:twapi::WINDOWINFO_rcWindow_getself    oo:twapi::WINDOWINFO_rcClient_setself rcClient  o:twapi::WINDOWINFO_rcClient_getself    ol:twapi::WINDOWINFO_dwStyle_setself dwStyle    o:twapi::WINDOWINFO_dwStyle_getself     ol:twapi::WINDOWINFO_dwExStyle_setself dwExStyle    o:twapi::WINDOWINFO_dwExStyle_getself   ol:twapi::WINDOWINFO_dwWindowStatus_setself dwWindowStatus  o:twapi::WINDOWINFO_dwWindowStatus_getself  oi:twapi::WINDOWINFO_cxWindowBorders_setself cxWindowBorders    o:twapi::WINDOWINFO_cxWindowBorders_getself     oi:twapi::WINDOWINFO_cyWindowBorders_setself cyWindowBorders    o:twapi::WINDOWINFO_cyWindowBorders_getself     oo:twapi::WINDOWINFO_atomWindowType_setself atomWindowType  o:twapi::WINDOWINFO_atomWindowType_getself  oh:twapi::WINDOWINFO_wCreatorVersion_setself wCreatorVersion    o:twapi::WINDOWINFO_wCreatorVersion_getself     :twapi::new_WINDOWINFO  o:twapi::delete_WINDOWINFOself  oi:twapi::WINDOWPLACEMENT_length_setself length     o:twapi::WINDOWPLACEMENT_length_getself     oi:twapi::WINDOWPLACEMENT_flags_setself flags   o:twapi::WINDOWPLACEMENT_flags_getself  oi:twapi::WINDOWPLACEMENT_showCmd_setself showCmd   o:twapi::WINDOWPLACEMENT_showCmd_getself    oo:twapi::WINDOWPLACEMENT_ptMinPosition_setself ptMinPosition   o:twapi::WINDOWPLACEMENT_ptMinPosition_getself  oo:twapi::WINDOWPLACEMENT_ptMaxPosition_setself ptMaxPosition   o:twapi::WINDOWPLACEMENT_ptMaxPosition_getself  oo:twapi::WINDOWPLACEMENT_rcNormalPosition_setself rcNormalPosition     o:twapi::WINDOWPLACEMENT_rcNormalPosition_getself   :twapi::new_WINDOWPLACEMENT o:twapi::delete_WINDOWPLACEMENTself     ol:twapi::POINT_x_setself x     o:twapi::POINT_x_getself    ol:twapi::POINT_y_setself y     o:twapi::POINT_y_getself    :twapi::new_POINT   o:twapi::delete_POINTself   :twapi::EnumWindows o:twapi::EnumChildWindowsparent_handle  o:twapi::GetParenthwndChild     oi:twapi::GetAncestorhwndChild flags    oi:twapi::GetWindowhwnd uCmd    :twapi::GetDesktopWindow    :twapi::GetShellWindow  :twapi::GetForegroundWindow o:twapi::SetForegroundWindowhWnd    o:twapi::SetActiveWindowhWnd    :twapi::GetActiveWindow oo:twapi::FindWindowlpClassName lpWindowName    oooo:twapi::FindWindowExhwndParent hwndChildAfter lpClassName lpWindowName  o:twapi::RealGetWindowClasshWnd counted_outbuf_size     o:twapi::GetClassNamehWnd counted_outbuf_size   oi:twapi::GetWindowLonghWnd nIndex  oil:twapi::SetWindowLonghWnd nIndex lValue  ooiiiii:twapi::SetWindowPoshWnd hWndInsertAfter x y cx cy uFlags    o:twapi::GetWindowThreadProcessIdhWnd   ol:twapi::GUITHREADINFO_cbSize_setself cbSize   o:twapi::GUITHREADINFO_cbSize_getself   ol:twapi::GUITHREADINFO_flags_setself flags     o:twapi::GUITHREADINFO_flags_getself    oo:twapi::GUITHREADINFO_hwndActive_setself hwndActive   o:twapi::GUITHREADINFO_hwndActive_getself   oo:twapi::GUITHREADINFO_hwndFocus_setself hwndFocus     o:twapi::GUITHREADINFO_hwndFocus_getself    oo:twapi::GUITHREADINFO_hwndCapture_setself hwndCapture     o:twapi::GUITHREADINFO_hwndCapture_getself  oo:twapi::GUITHREADINFO_hwndMenuOwner_setself hwndMenuOwner     o:twapi::GUITHREADINFO_hwndMenuOwner_getself    oo:twapi::GUITHREADINFO_hwndMoveSize_setself hwndMoveSize   o:twapi::GUITHREADINFO_hwndMoveSize_getself     oo:twapi::GUITHREADINFO_hwndCaret_setself hwndCaret     o:twapi::GUITHREADINFO_hwndCaret_getself    oo:twapi::GUITHREADINFO_rcCaret_setself rcCaret     o:twapi::GUITHREADINFO_rcCaret_getself  :twapi::new_GUITHREADINFO   o:twapi::delete_GUITHREADINFOself   lo:twapi::GetGUIThreadInfoidThread pGuiThreadInfo   o:twapi::GetWindowTexthWnd counted_outbuf_size  oo:twapi::SetWindowTexthWnd lpString    oi:twapi::ShowWindowhWnd flags  oi:twapi::ShowWindowAsynchWnd flags     ol:twapi::ShowOwnedPopupshWnd fShow     ol:twapi::EnableWindowhWnd bEnable  o:twapi::OpenIconhWnd   o:twapi::CloseWindowhWnd    o:twapi::DestroyWindowhWnd  o:twapi::IsIconichWnd   o:twapi::IsZoomedhWnd   o:twapi::IsWindowVisiblehWnd    o:twapi::IsWindowhWnd   o:twapi::IsWindowUnicodehWnd    o:twapi::IsWindowEnabledhWnd    oo:twapi::IsChildhwndParent hwndChild   oillii:twapi::SendMessageTimeouthWnd Msg wParam lParam fuFlags uTimeout     oill:twapi::SendNotifyMessagehWnd Msg wParam lParam     oill:twapi::PostMessagehWnd Msg wParam lParam   o:twapi::SetFocushWnd   o:twapi::GetClientRecthWnd  o:twapi::GetWindowRecthWnd  oo:twapi::GetWindowInfohwnd pwi     oo:twapi::GetWindowPlacementhWnd lpwndpl    oo:twapi::SetWindowPlacementhWnd lpwndpl    o:twapi::WindowFromPointPoint   ool:twapi::InvalidateRecthWnd RECT_NULL bErase  oiiiil:twapi::MoveWindowhWnd x y nWidth nHeight bRepaint    o:twapi::UpdateWindowhWnd   ol:twapi::FlashWindowhWnd bInvert   ll:twapi::BeepdwFreq dwDuration     i:twapi::MessageBeepuType   :twapi::GetCaretBlinkTime   i:twapi::SetCaretBlinkTimeuMSeconds     o:twapi::HideCarethWnd  o:twapi::ShowCarethWnd  :twapi::GetCaretPos ii:twapi::SetCaretPosx y    lll:twapi::AttachThreadInputidAttach idAttachTo fAttach     o:twapi::ArrangeIconicWindowshWnd   s:twapi::SendInputinput_str     s:twapi::Twapi_SendUnicodeutf8  ool:twapi::PlaySoundpszSound hmod fdwsound  :twapi::GetCursorPos    ii:twapi::SetCursorPosx y   iis:twapi::RegisterHotKeykeyModifiers vk script     i:twapi::UnregisterHotKeyid     l:twapi::BlockInputblock    looliiiioooo:twapi::CreateWindowExdwExStyle lpClassName lpWindowName dwStyle x y nWidth nHeight hWndParent hMenu hInstance lpParam  olbl:twapi::SetLayeredWindowAttributeshwnd crKey bAlpha dwFlags     :twapi::GetProcessWindowStation o:twapi::SetProcessWindowStationhWinSta     oll:twapi::OpenWindowStationlpszWinSta fInherit dwDesiredAccess     ollo:twapi::CreateWindowStationlpwinsta dwFlags dwDesiredAccess lpsa    o:twapi::CloseWindowStationhWinSta  :twapi::EnumWindowStations  o:twapi::EnumDesktopWindowshdesk    o:twapi::EnumDesktopshwinsta    olll:twapi::OpenDesktoplpszDesktop dwFlags fInherit dwDesiredAccess     ooollo:twapi::CreateDesktoplpszDesktop lpszDevice pDevmode dwFlags dwDesiredAccess lpsa     lll:twapi::OpenInputDesktopdwFlags fInherit dwDesiredAccess     o:twapi::CloseDesktophDesktop   o:twapi::SwitchDesktophDesktop  l:twapi::GetThreadDesktopdwThreadId     o:twapi::SetThreadDesktophDesktop   :twapi::GetDoubleClickTime  :twapi::GetLastInputInfo    i:twapi::GetAsyncKeyStatevkey   i:twapi::GetKeyStatevkey    ii:twapi::MapVirtualKeyuCode uMapType   |o:twapi::OpenClipboardHWND_NULL_DEFAULT    :twapi::CloseClipboard  :twapi::EmptyClipboard  io:twapi::SetClipboardDatauFormat hMem  i:twapi::GetClipboardDataclip_fmt   :twapi::GetOpenClipboardWindow  :twapi::Twapi_EnumClipboardFormats  i:twapi::GetClipboardFormatNameformat counted_outbuf_size   :twapi::GetClipboardOwner   i:twapi::IsClipboardFormatAvailableformat   o:twapi::RegisterClipboardFormatlpszFormat  s:twapi::MonitorClipboardStartscript    o:twapi::MonitorClipboardStophwin   :twapi::GetUserDefaultLangID    :twapi::GetSystemDefaultLangID  :twapi::GetUserDefaultLCID  :twapi::GetSystemDefaultLCID    :twapi::GetUserDefaultUILanguage    :twapi::GetSystemDefaultUILanguage  llloiiiooi:twapi::GetNumberFormatopts Locale dwFlags lpValue NumDigits LeadingZero Grouping lpDecimalSep lpThousandSep NegativeOrder    llloiiiooiio:twapi::GetCurrencyFormatopts Locale dwFlags lpValue NumDigits LeadingZero Grouping lpDecimalSep lpThousandSep NegativeOrder PositiveOrder lpCurrencySymbol     :twapi::GetThreadLocale ll:twapi::GetLocaleInfodwLocale dwLocaleType counted_outbuf_size    :twapi::GetACP  :twapi::GetOEMCP    o:twapi::IIDFromStrings     o:twapi::CLSIDFromProgIDlpszProgID  o:twapi::ProgIDFromCLSIDINPUT   o:twapi::CLSIDFromStringLPWSTR  oolos:twapi::Twapi_CoCreateInstanceINPUT pUnkOuter dwClsContext INPUT name  o:twapi::GetActiveObjectINPUT   oos:twapi::IUnknown_QueryInterfaceunkP INPUT nameP  o:twapi::Twapi_GetObjectIDispatchname   ool:twapi::IDispatch_GetIDsOfNamesidispP argc argv lcid     o:twapi::ConvertToIUnknowninterfaceP    o:twapi::ITypeInfo_GetTypeAttrITypeInfo *   oi:twapi::ITypeInfo_GetVarDesctiP index     oi:twapi::ITypeInfo_GetFuncDesctiP index    oo:twapi::ITypeInfo_GetIDsOfNamestiP argc argv  ol:twapi::ITypeInfo_GetNamestiP memid   oohl:twapi::ITypeComp_BindtcP nameP flags lcid  oi:twapi::LoadTypeLibExszFile regkind   ohhl:twapi::LoadRegTypeLibINPUT wVerMajor wVerMinor lcid    ooo:twapi::RegisterTypeLibptlib szFullPath szHelpDir    ohhli:twapi::UnRegisterTypeLibINPUT wVerMajor wVerMinor lcid syskind    ohhl:twapi::QueryPathOfRegTypeLibINPUT wVerMajor wVerMinor lcid     o:twapi::ITypeLib_GetLibAttrITypeLib *  o:twapi::GetRecordInfoFromTypeInfopTypeInfo     olllo:twapi::GetRecordInfoFromGuidsINPUT uVerMajor uVerMinor lcid INPUT     o:twapi::IRecordInfo_GetFieldNamesriP   ol:twapi::IEnumVARIANT_NextevP count    :twapi::CreateBindCtx   o:twapi::CreateFileMonikerpath  o:twapi::OleRuniunknown     d:twapi::VariantTimeToSystemTimevtime   o:twapi::SystemTimeToVariantTimesystemtime  oiol:twapi::SHGetFolderPathhwnd folder tok flags    oil:twapi::SHGetSpecialFolderPathhwndOwner nFolder fCreate  oi:twapi::SHGetSpecialFolderLocationhwndOwner nFolder   o:twapi::SHGetPathFromIDListpidl    oloo:twapi::SHObjectPropertieshwnd dwType szObject szPage   oo:twapi::OpenThemeDatawin classes  o:twapi::CloseThemeDataHTHEME   :twapi::IsThemeActive   :twapi::IsAppThemed :twapi::GetCurrentThemeName oiii:twapi::GetThemeColorhTheme iPartId iStateId iPropId    ooiii:twapi::GetThemeFonthTheme hdc iPartId iStateId iPropId    s:twapi::TwapiThemeDefineValuename  :twapi::Twapi_GetShellVersion   ooooohoioio:twapi::Twapi_WriteShortcutlinkPath objPath itemIds commandArgs desc hotkey iconPath iconIndex relativePath showCommand workingDirectory     oiol:twapi::Twapi_ReadShortcutlinkPath pathFlags hwnd resolve_flags     ool:twapi::Twapi_WriteUrlShortcutlinkPath url flags     o:twapi::Twapi_ReadUrlShortcutlinkPath  oolo:twapi::Twapi_InvokeUrlShortcutlinkPath verb flags hwnd     oiool:twapi::SHInvokePrinterCommandhwnd action buf1 buf2 modal  oiooho:twapi::Twapi_SHFileOperationhwnd op fromP toP flags progress_title   ol:twapi::SERVICE_STATUS_dwServiceType_setself dwServiceType    o:twapi::SERVICE_STATUS_dwServiceType_getself   ol:twapi::SERVICE_STATUS_dwCurrentState_setself dwCurrentState  o:twapi::SERVICE_STATUS_dwCurrentState_getself  ol:twapi::SERVICE_STATUS_dwControlsAccepted_setself dwControlsAccepted  o:twapi::SERVICE_STATUS_dwControlsAccepted_getself  ol:twapi::SERVICE_STATUS_dwWin32ExitCode_setself dwWin32ExitCode    o:twapi::SERVICE_STATUS_dwWin32ExitCode_getself     ol:twapi::SERVICE_STATUS_dwServiceSpecificExitCode_setself dwServiceSpecificExitCode    o:twapi::SERVICE_STATUS_dwServiceSpecificExitCode_getself   ol:twapi::SERVICE_STATUS_dwCheckPoint_setself dwCheckPoint  o:twapi::SERVICE_STATUS_dwCheckPoint_getself    ol:twapi::SERVICE_STATUS_dwWaitHint_setself dwWaitHint  o:twapi::SERVICE_STATUS_dwWaitHint_getself  :twapi::new_SERVICE_STATUS  o:twapi::delete_SERVICE_STATUSself  |ool:twapi::OpenSCManagerpszMachineName pszDatabaseName dwDesiredSCMAccess  o:twapi::LockServiceDatabasehSCManager  o:twapi::UnlockServiceDatabaseScLock    dwLockDuration  lpLockOwner fIsLocked   o:twapi::QueryServiceLockStatushSCManager   oo|l:twapi::OpenServicehSCManager pszInternalName dwDesiredServiceAccess    ooolllloooooo:twapi::CreateServicehSCManager lpServiceName lpDisplayName dwDesiredAccess dwServiceType dwStartType dwErrorControl lpBinaryPathName lpLoadOrderGroup lpdwTagId lpDependencies lpServiceStartName lpPassword  o:twapi::DeleteServicehService  oo:twapi::StartServicehService argc argv    olo:twapi::ControlServicehService dwControl lpServiceStatus     oo:twapi::QueryServiceStatushService lpServiceStatus    lpDependencies  lpDisplayName   lpServiceStartName  lpLoadOrderGroup    lpBinaryPathName    dwTagId dwErrorControl  dwStartType o:twapi::QueryServiceConfighService     oo:twapi::GetServiceKeyNamehSCManager name  oo:twapi::GetServiceDisplayNamehSCManager name  olllooooooo:twapi::ChangeServiceConfighService dwServiceType dwStartType dwErrorControl lpBinaryPathName lpLoadOrderGroup lpdwTagId lpDependencies lpServiceStartName lpPassword lpDisplayName  oll:twapi::EnumServicesStatushService dwServiceType dwServiceState  lpServiceName   oillo:twapi::EnumServicesStatusExhService infolevel dwServiceType dwServiceState groupname  Unsupported information level   ol:twapi::EnumDependentServiceshService dwServiceState  o:twapi::CloseServiceHandlehSCManager   oi:twapi::QueryServiceStatusExh infolevel   ols:twapi::Twapi_BecomeAServiceargc argv service_type script    slllll:twapi::Twapi_SetServiceStatusname state exit_code service_exit_code checkpoint waithint  s:twapi::Twapi_StopServiceThreadname    oo:twapi::RegisterEventSourceserverName sourceName  ohhlooo:twapi::ReportEventhEventLog wType wCategory dwEventID lpUserSid argc argv BINLEN BINDATA    o:twapi::DeregisterEventSourcehEventLog     oo:twapi::OpenEventLoglpUNCServerName lpSourceName  oo:twapi::OpenBackupEventLoglpUNCServerName lpFileName  oll:twapi::ReadEventLogevlH flags offset    o:twapi::CloseEventLoghEventLog     oo:twapi::BackupEventLoghEventLog lpBackupFileName  oo:twapi::ClearEventLoghEventLog lpClearFileName    o:twapi::GetNumberOfEventLogRecordshEventLog    o:twapi::GetOldestEventLogRecordhEventLog   o:twapi::Twapi_IsEventLogFullhEventLog  :twapi::AllocConsole    llol:twapi::CreateConsoleScreenBufferdwDesiredAccess dwShareMode lpSecurityAttributes dwFlags   ohlo:twapi::FillConsoleOutputAttributehConsoleOutput wAttribute nLength dwWriteCoord    Invalid Console coordinates format. Should have exactly 2 integer elements between 0 and 65535  oolo:twapi::FillConsoleOutputCharacterhConsoleOutput wChar nLength dwWriteCoord     o:twapi::FlushConsoleInputBufferhConsoleInput   :twapi::FreeConsole ll:twapi::GenerateConsoleCtrlEventdwCtrlEvent dwProcessGroupId  :twapi::GetConsoleCP    o:twapi::GetConsoleModehConsoleHandle   :twapi::GetConsoleOutputCP  o:twapi::GetConsoleScreenBufferInfohConsoleOutput   :twapi::GetConsoleTitlecounted_outbuf_size  :twapi::GetConsoleWindow    o:twapi::GetLargestConsoleWindowSizehConsoleOutput  o:twapi::GetNumberOfConsoleInputEventshConsoleInput     :twapi::GetNumberOfConsoleMouseButtons  l:twapi::GetStdHandlenStdHandle     i:twapi::SetConsoleCPwCodePageID    oo:twapi::SetConsoleCursorPositionhConsoleOutput dwCursorPosition   ol:twapi::SetConsoleModehConsoleHandle dwMode   i:twapi::SetConsoleOutputCPwCodePageID  oo:twapi::SetConsoleScreenBufferSizehConsoleOutput dwSize   oh:twapi::SetConsoleTextAttributehConsoleOutput wAttributes     o:twapi::SetConsoleTitlelpConsoleTitle  olo:twapi::SetConsoleWindowInfohConsoleOutput bAbsolute lpConsoleWindow     Need to specify exactly 4 integers for a SMALL_RECT structure   lo:twapi::SetStdHandlenStdHandle hHandle    ool:twapi::WriteConsolehConsoleOutput lpBuffer nNumberOfCharsToWrite    ooo:twapi::WriteConsoleOutputCharacterhConsoleOutput INPUT COUNT dwWriteCoord   o:twapi::SetConsoleActiveScreenBufferhHandle    oi:twapi::ReadConsoleconh numchars  si:twapi::RegisterConsoleEventNotifierscript timeout    :twapi::UnregisterConsoleEventNotifier  :twapi::PdhGetDllVersion    o:twapi::PdhConnectMachineszMachineName     ooll:twapi::PdhEnumObjectsszDataSource szMachineName dwDetailLevel bRefresh     oooll:twapi::PdhEnumObjectItemsszDataSource szMachineName szObjectName dwDetailLevel dwFlags    oooolol:twapi::PdhMakeCounterPathszMachineName szObjectName szInstanceName szParentInstance dwInstanceIndex szCounterName dwFlags   ol:twapi::PdhParseCounterPathszFullPathBuffer dwFlags   :twapi::PdhBrowseCounters   l:twapi::PdhSetDefaultRealTimeDataSourcedwDataSourceId  ol:twapi::PdhOpenQueryszDataSource dwUserData   o:twapi::PdhCloseQueryhQuery    ool:twapi::PdhAddCounterhQuery szFullCounterPath dwUserData     o:twapi::PdhRemoveCounterhCounter   o:twapi::PdhCollectQueryDatahQuery  ol:twapi::PdhGetFormattedCounterValuehCounter dwFormat  o:twapi::PdhValidatePathszFullCounterPath   ol:twapi::PdhLookupPerfNameByIndexszMachineName ctr_index   o:twapi::GetDChwin  o:twapi::GetWindowDChwin    oo:twapi::ReleaseDChwin hdc     oio:twapi::GetObjecthgdiobj cbBuffer lpvObject  oi:twapi::GetDeviceCapshdc index    ol|l:twapi::EnumDisplayDeviceslpDevice iDevNum DEFAULT_ZERO     ol:twapi::MonitorFromWindowhwnd dwFlags     ol:twapi::MonitorFromRectlprc dwFlags   ol:twapi::MonitorFromPointpt dwFlags    o:twapi::GetMonitorInfohMonitor     oo:twapi::EnumDisplayMonitorshdc RECT_NULL  ol|o:twapi::AddFontResourceExlpszFilename fl LPVOID_NULL_DEFAULT    ol|o:twapi::RemoveFontResourceExlpFileName fl LPVOID_NULL_DEFAULT   looo:twapi::CreateScalableFontResourcefdwHidden lpszFontRes lpszFontFile lpszCurrentPath    ol:twapi::IEnumWorkItems_NextewiP count     oooh:twapi::IScheduledWorkItem_GetRunTimesswiP beginP endP count    o:twapi::IScheduledWorkItem_GetWorkItemDataswiP     l:twapi::Twapi_EnumPrinters_Level4flags     l:twapi::ProcessIdToSessionIddwProcessId    o:twapi::WTSCloseServerHANDLE   oll:twapi::WTSDisconnectSessionhServer SessionId bWait  o:twapi::WTSEnumerateProcesseswtsH  o:twapi::WTSEnumerateSessionswtsH   oll:twapi::WTSLogoffSessionhServer SessionId bWait  o:twapi::WTSOpenServerserver_name   oli:twapi::WTSQuerySessionInformationhServer sess_id info_class     ololollll:twapi::WTSSendMessagehServer SessionId pTitle TitleLength pMessage MessageLength Style Timeout bWait  ooool:twapi::DsGetDcNamesystemnameP domainnameP INPUT_WITH_NULL sitenameP flags     bbb:twapi::SetSuspendStatehibernate forcecritical disablewakeevent  o:twapi::GetDevicePowerStatehDevice     s:twapi::Twapi_PowerNotifyStartscriptP  o:twapi::Twapi_PowerNotifyStophwin  :twapi::GetSystemPowerStatus    l:twapi::SetThreadExecutionStateesFlags     ooo|o:twapi::SetupDiCreateDeviceInfoListExINPUT_WITH_NULL parent MachineName LPVOID_NULL_DEFAULT    o:twapi::SetupDiDestroyDeviceInfoListDeviceInfoSet  oooloo|o:twapi::SetupDiGetClassDevsExINPUT_WITH_NULL Enumerator parent Flags DeviceInfoSet MachineName LPVOID_NULL_DEFAULT  olo:twapi::SetupDiEnumDeviceInfoDeviceInfoSet MemberIndex DeviceInfoData    oolol:twapi::SetupDiGetDeviceRegistryPropertyDeviceInfoSet DeviceInfoData Property PropertyBuffer PropertyBufferSize    ooolo:twapi::SetupDiEnumDeviceInterfacesDeviceInfoSet DeviceInfoData INPUT MemberIndex DeviceInterfaceData  ooolo:twapi::SetupDiGetDeviceInterfaceDetailDeviceInfoSet DeviceInterfaceData DeviceInterfaceDetailData DeviceInterfaceDetailDataSize DeviceInfoData    o|ooo:twapi::SetupDiClassNameFromGuidExINPUT counted_outbuf_size NULL_DEFAULT NULL_DEFAULT LPVOID_NULL_DEFAULT  ool|oo:twapi::SetupDiClassGuidsFromNameExClassName ClassGuidList ClassGuidListSize NULL_DEFAULT LPVOID_NULL_DEFAULT     oo|o:twapi::SetupDiGetDeviceInstanceIdDeviceInfoSet DeviceInfoData counted_outbuf_size NULL_DEFAULT     olololo:twapi::DeviceIoControlhDevice dwIoControlCode lpInBuffer nInBufferSize lpOutBuffer nOutBufferSize lpOverlapped  slo:twapi::Twapi_DeviceChangeNotifyStartscriptP type INPUT_WITH_NULL    o:twapi::Twapi_DeviceChangeNotifyStophwin   :twapi::GetNetworkParams    :twapi::GetAdaptersInfo o:twapi::GetAdapterIndexAdapterName     :twapi::GetInterfaceInfo    :twapi::GetNumberOfInterfaces   i:twapi::GetPerAdapterInfoadapter_index     i:twapi::GetIfEntryif_index     |i:twapi::GetIfTablesort_order_default_0    |i:twapi::GetIpAddrTablesort_order_default_0    |i:twapi::GetIpNetTablesort_order_default_0     |i:twapi::GetIpForwardTablesort_order_default_0     i:twapi::FlushIpNetTableif_index    ll:twapi::AllocateAndGetTcpExTableFromStacksorted flags     ll:twapi::AllocateAndGetUdpExTableFromStacksorted flags     o:twapi::SetTcpEntryrow     Invalid TCP connection format:  Invalid IP address format:  255.255.255.255 Invalid or non-integer port number specified    oi:twapi::getnameinfoINPUT flags    ssi:twapi::getaddrinfohostname svcname protocol     ss:twapi::Twapi_ResolveHostnameAsyncnameP scriptP   ss:twapi::Twapi_ResolveAddressAsyncaddrP scriptP    oo:twapi::GetBestRouteIPADDR IPADDR     o:twapi::GetBestInterfaceIPADDR     ollli:twapi::GetExtendedTcpTablebuf buf_sz sorted family table_class    oii:twapi::Twapi_FormatExtendedTcpTablebuf family table_class   ollli:twapi::GetExtendedUdpTablebuf buf_sz sorted family table_class    oii:twapi::Twapi_FormatExtendedUdpTablebuf family table_class   oololoo:twapi::NetShareAddserver_name net_name share_type remark max_uses path secd     :twapi::NetUseEnum  oo:twapi::Twapi_NetUseGetInfoUncServerName UseName  ool:twapi::NetShareDelserver_name net_name reserved     o:twapi::Twapi_NetShareEnumserver_name  oo:twapi::Twapi_NetShareCheckserver_name device_name    ool:twapi::NetShareGetInfoservername netname level  ooolo:twapi::NetShareSetInfoserver_name net_name remark max_uses secd   ool:twapi::NetConnectionEnumserver qualifier level  oool:twapi::NetFileEnumserver basepath user level   oll:twapi::NetFileGetInfoserver fileid level    ol:twapi::NetFileCloseservername fileid     oool:twapi::NetSessionEnumserver client user level  oool:twapi::NetSessionGetInfoserver client user level   ooo:twapi::NetSessionDelserver client user  olooooiol:twapi::Twapi_WNetUseConnectionwinH type localdeviceP remoteshareP providerP usernameP ignore_password passwordP flags     oll:twapi::WNetCancelConnection2lpName dwFlags fForce   o:twapi::WNetGetUniversalNamelocalpathP     o:twapi::WNetGetUserlpName  oo:twapi::NetGetDCNameservername domainname     ol:twapi::NetScheduleJobGetInfoservername jobid     oo:twapi::NetScheduleJobAddservername atP   AT_INFO list must have exactly 5 elements   oll:twapi::NetScheduleJobDelServername MinJobId MaxJobId    o:twapi::NetScheduleJobEnumservername   ool:twapi::Twapi_WNetGetResourceInformationremoteName provider resourcetype     olo:twapi::CreateMutexlpMutexAttributes bInitialOwner lpName    llo:twapi::OpenMutexdwDesiredAccess bInheritHandle lpName   o:twapi::ReleaseMutexhMutex     ollo:twapi::CreateSemaphorelpSemaphoreAttributes lInitialCount lMaximumCount lpName     llo:twapi::OpenSemaphoredwDesiredAccess bInheritHandle lpName   ol:twapi::ReleaseSemaphorehSemaphore lReleaseCount  oll:twapi::WaitForMultipleObjectsHANDLE_COUNT HANDLE_ARRAY bWaitAll dwMilliseconds  ooo:twapi::Twapi_Allocate_SEC_WINNT_AUTH_IDENTITYuser domain password   o:twapi::Twapi_Free_SEC_WINNT_AUTH_IDENTITYswaiP    :twapi::EnumerateSecurityPackages   ooloo:twapi::AcquireCredentialsHandlepszPrincipal pszPackage fCredentialUse LUID_WITH_NULL pAuthData    o:twapi::FreeCredentialsHandleINPUT     ooolllol:twapi::InitializeSecurityContextINPUT INPUT_WITH_NULL pszTargetName fContextReq Reserved1 TargetDataRep INPUT_WITH_NULL Reserved2  oooll:twapi::AcceptSecurityContextINPUT INPUT_WITH_NULL INPUT_WITH_NULL fContextReq TargetDataRep   o:twapi::DeleteSecurityContextINPUT     o:twapi::QuerySecurityContextTokenINPUT     o:twapi::ImpersonateSecurityContextINPUT    ol:twapi::QueryContextAttributesINPUT attr  olol:twapi::MakeSignatureINPUT qop BINLEN BINDATA seqnum    ool:twapi::VerifySignatureINPUT INPUT_WITH_NULL MessageSeqNo    olol:twapi::EncryptMessageINPUT qop BINLEN BINDATA seqnum   ool:twapi::DecryptMessageINPUT INOUT seqnum     ooll:twapi::CryptAcquireContextpszContainer pszProvider dwProvType dwFlags  o|l:twapi::CryptReleaseContexthProv DEFAULT_ZERO    ol:twapi::CryptGenRandomhProv dwLen     si:twapi::Tcl_GetChannelHandlechan_name direction   iiii:twapi::Twapi_GetHandleInformationpid skip_errors timeout_ms type   o:twapi::GetHandleInformationhObject    oll:twapi::SetHandleInformationhObject mask flags   ooolll:twapi::DuplicateHandlehSourceProcessHandle hSourceHandle hTargetProcessHandle dwDesiredAccess bInheritHandle dwOptions   o:twapi::IUnknown_ReleasepIUnknown  o:twapi::IUnknown_AddRefpIUnknown   o:twapi::IDispatch_GetTypeInfoCountpIDispatch   oil:twapi::IDispatch_GetTypeInfopIDispatch itinfo lcid  ool:twapi::IDispatchEx_GetDispIDpIDispatchEx INPUT grfdex   ol:twapi::IDispatchEx_GetMemberNamepIDispatchEx dispid  oll:twapi::IDispatchEx_GetMemberPropertiespIDispatchEx dispid grfdexFetch   o:twapi::IDispatchEx_GetNameSpaceParentpIDispatchEx     oll:twapi::IDispatchEx_GetNextDispIDpIDispatchEx grfdex id  oi:twapi::ITypeInfo_GetRefTypeOfImplTypepITypeInfo index    ol:twapi::ITypeInfo_GetRefTypeInfopITypeInfo hreftype   o:twapi::ITypeInfo_GetTypeComppITypeInfo    o:twapi::ITypeInfo_GetContainingTypeLibpITypeInfo   oi:twapi::ITypeInfo_GetDocumentationpITypeInfo index    oi:twapi::ITypeInfo_GetImplTypeFlagspITypeInfo index    oi:twapi::ITypeLib_GetDocumentationpITypeLib index  o:twapi::ITypeLib_GetTypeInfoCountpITypeLib     oi:twapi::ITypeLib_GetTypeInfoTypepITypeLib index   oi:twapi::ITypeLib_GetTypeInfopITypeLib index   oo:twapi::ITypeLib_GetTypeInfoOfGuidpITypeLib INPUT     ooo:twapi::IRecordInfo_GetFieldpIRecordInfo rec fieldname   o:twapi::IRecordInfo_GetGuidpIRecordInfo    o:twapi::IRecordInfo_GetNamepIRecordInfo    o:twapi::IRecordInfo_GetSizepIRecordInfo    o:twapi::IRecordInfo_GetTypeInfopIRecordInfo    oo:twapi::IRecordInfo_IsMatchingTypepIRecordInfo recinfoP   oo:twapi::IRecordInfo_RecordClearpIRecordInfo rec   ooo:twapi::IRecordInfo_RecordCopypIRecordInfo fromrec torec     o:twapi::IRecordInfo_RecordCreatepIRecordInfo   oo:twapi::IRecordInfo_RecordCreateCopypIRecordInfo fromrec  oo:twapi::IRecordInfo_RecordDestroypIRecordInfo rec     oo:twapi::IRecordInfo_RecordInitpIRecordInfo rec    oo:twapi::IMoniker_GetDisplayNamepIMoniker pbc  oo:twapi::IEnumVARIANT_ClonepIEnumVARIANT OUTPUT    o:twapi::IEnumVARIANT_ResetpIEnumVARIANT    ol:twapi::IEnumVARIANT_SkippIEnumVARIANT skipcount  oo:twapi::IConnectionPoint_AdvisepIConnectionPoint unkP     oo:twapi::IConnectionPoint_GetConnectionInterfacepIConnectionPoint OUTPUT   ol:twapi::IConnectionPoint_UnadvisepIConnectionPoint dwCookie   o:twapi::IConnectionPointContainer_EnumConnectionPointspIConnectionPointContainer   oo:twapi::IConnectionPointContainer_FindConnectionPointpIConnectionPointContainer INPUT     ol:twapi::IEnumConnectionPoints_NextpIEnumConnectionPoints celt     o:twapi::IEnumConnectionPoints_ResetpIEnumConnectionPoints  ol:twapi::IEnumConnectionPoints_SkippIEnumConnectionPoints celt     o:twapi::IProvideClassInfo_GetClassInfopIProvideClassInfo   ol:twapi::IProvideClassInfo2_GetGUIDpIProvideClassInfo2 guidkind    ooo:twapi::ITaskScheduler_ActivatepITaskScheduler nameP INPUT   ooo:twapi::ITaskScheduler_AddWorkItempITaskScheduler nameP wiP  oo:twapi::ITaskScheduler_DeletepITaskScheduler nameP    o:twapi::ITaskScheduler_EnumpITaskScheduler     ooo:twapi::ITaskScheduler_IsOfTypepITaskScheduler nameP INPUT   oooo:twapi::ITaskScheduler_NewWorkItempITaskScheduler nameP INPUT INPUT     oo:twapi::ITaskScheduler_SetTargetComputerpITaskScheduler nameP     o:twapi::ITaskScheduler_GetTargetComputerpITaskScheduler    o:twapi::IEnumWorkItems_ClonepIEnumWorkItems    o:twapi::IEnumWorkItems_ResetpIEnumWorkItems    ol:twapi::IEnumWorkItems_SkippIEnumWorkItems count  o:twapi::IScheduledWorkItem_CreateTriggerpIScheduledWorkItem    oh:twapi::IScheduledWorkItem_DeleteTriggerpIScheduledWorkItem trigger   oo:twapi::IScheduledWorkItem_EditWorkItempIScheduledWorkItem hwnd   o:twapi::IScheduledWorkItem_GetAccountInformationpIScheduledWorkItem    o:twapi::IScheduledWorkItem_GetCommentpIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetCreatorpIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetExitCodepIScheduledWorkItem  o:twapi::IScheduledWorkItem_GetFlagspIScheduledWorkItem     o:twapi::IScheduledWorkItem_GetIdleWaitpIScheduledWorkItem  o:twapi::IScheduledWorkItem_GetMostRecentRunTimepIScheduledWorkItem     o:twapi::IScheduledWorkItem_GetNextRunTimepIScheduledWorkItem   o:twapi::IScheduledWorkItem_GetStatuspIScheduledWorkItem    oh:twapi::IScheduledWorkItem_GetTriggerpIScheduledWorkItem trigger  o:twapi::IScheduledWorkItem_GetTriggerCountpIScheduledWorkItem  oh:twapi::IScheduledWorkItem_GetTriggerStringpIScheduledWorkItem trigger    o:twapi::IScheduledWorkItem_RunpIScheduledWorkItem  ooo:twapi::IScheduledWorkItem_SetAccountInformationpIScheduledWorkItem nameP passwordP  oo:twapi::IScheduledWorkItem_SetCommentpIScheduledWorkItem commentP     oo:twapi::IScheduledWorkItem_SetCreatorpIScheduledWorkItem creatorP     oh:twapi::IScheduledWorkItem_SetErrorRetryCountpIScheduledWorkItem count    oh:twapi::IScheduledWorkItem_SetErrorRetryIntervalpIScheduledWorkItem interval  ol:twapi::IScheduledWorkItem_SetFlagspIScheduledWorkItem flags  ohh:twapi::IScheduledWorkItem_SetIdleWaitpIScheduledWorkItem idle deadline  Binary data exceeds MAXWORD oo:twapi::IScheduledWorkItem_SetWorkItemDatapIScheduledWorkItem BINLEN BINDATA  o:twapi::IScheduledWorkItem_TerminatepIScheduledWorkItem    o:twapi::ITask_GetApplicationNamepITask     o:twapi::ITask_GetMaxRunTimepITask  o:twapi::ITask_GetParameterspITask  o:twapi::ITask_GetPrioritypITask    o:twapi::ITask_GetTaskFlagspITask   o:twapi::ITask_GetWorkingDirectorypITask    oo:twapi::ITask_SetApplicationNamepITask nameP  ol:twapi::ITask_SetMaxRunTimepITask runtime     oo:twapi::ITask_SetParameterspITask params  ol:twapi::ITask_SetPrioritypITask priority  ol:twapi::ITask_SetTaskFlagspITask flags    oo:twapi::ITask_SetWorkingDirectorypITask dir   o:twapi::ITaskTrigger_GetTriggerpITaskTrigger   o:twapi::ITaskTrigger_GetTriggerStringpITaskTrigger     oo:twapi::ITaskTrigger_SetTriggerpITaskTrigger triggerP     o:twapi::IPersistFile_GetCurFilepIPersistFile   o:twapi::IPersistFile_IsDirtypIPersistFile  ool:twapi::IPersistFile_LoadpIPersistFile file mode     ool:twapi::IPersistFile_SavepIPersistFile filename remember     oo:twapi::IPersistFile_SaveCompletedpIPersistFile file  namespace eval twapi { }    twapi   2.1.6   8.1 Unknown or unsupported SHChangeNotify flags type    wEventID uFlags dwItem1 ?dwItem2?   Unknown or unsupported SHChangeNotify event type    �J\KiK�K�K�K�KIID CMD Unable to allocate memory    Offending parameter index  wCode   scode   dwHelpContext   bstrHelpFile    bstrDescription bstrSource  Property put methods must have exactly one parameter    Invalid IDispatch prototype - must contain DISPID RIID LCID FLAGS RETTYPE ?PARAMTYPES?  IDISPATCH PROTOTYPE ?ARG1 ARG2...?  Could not console control event notification structures Could not initialize directory change notification structures   Could not initialize hotkey structures  Could not initialize callback structures    Could not initialize winsock    Twapi callback initialization already in failed state. Further calls will continue to fail. Bad Twapi callback initialization state.    "   
Error in callback script " start   stop    pause   interrogate Could not install console control handler.  No service names specified. Twapi_BecomeAService called multiple times  Could not start service control dispatcher. ::twapi::_service_background_error  Unknown service name.   ��    .?AVexception@@ ��    .?AVlogic_error@std@@   ��    .?AVout_of_range@std@@  invalid vector<T> subscript Could not register hot key  TwapiHK%x%x devtyp_volume   devtyp_port devtyp_deviceinterface  deviceremovecomplete    devicearrival   devnodes_changed    Device interface must be specified on Windows 2000  Could not queue hostname resolution request.    fail    �P�Z�P�_pPRZCould not queue address resolution request. 10022   Queue length empty even though semaphore acquisition succeeded  ctrl-c  ctrl-break  close   logoff  shutdown    Could not initialize directory change notification. Could not setup overlapped read for directory change notifications. Could not register directory change notification callback.  added   removed modified    renameold   renamenew   unknown  Last system error:     apmbatterylow   apmpowerstatuschange    apmoemevent apmresumeautomatic  apmresumesuspend    apmquerysuspendfailed   apmsuspend  apmresumecritical   Tcl This interpreter does not support stubs-enabled extensions. ��    .?AVtype_info@@                                                                                                                             �                  0  �               	  H   ` �                  �4   V S _ V E R S I O N _ I N F O     ���                                      F   S t r i n g F i l e I n f o   "   0 4 0 9 0 4 b 0   d   F i l e D e s c r i p t i o n     T c l   W i n d o w s   A P I   E x t e n s i o n   D L L   < 
  O r i g i n a l F i l e n a m e   t w a p i . d l l   D   C o m p a n y N a m e     A s h o k   P .   N a d k a r n i   ,   F i l e V e r s i o n     2 . 1 . 6   j #  L e g a l C o p y r i g h t   C o p y r i g h t   �   2 0 0 9   A s h o k   P .   N a d k a r n i     T   P r o d u c t N a m e     T c l   W i n d o w s   A P I   E x t e n s i o n   :   P r o d u c t V e r s i o n   2 . 1 . 6   B e t a     D    V a r F i l e I n f o     $    T r a n s l a t i o n     	�                                                                                                                                                                                           T  00#0(0-0E0K0Y0^0d0n0w0}0�0�0�0�0�0�0�0�0�0�0�0�0�0�01111'1.131?1E1{1�1�1�1�1�12&222^2�2�2�2�2�23$3,313E3L3b3m3�3�3�34474>4W4^4{4�4�4�45t5�5�5�5�5�56 6&6f6�6�6�6=7C7L7R7Z7e7�7�7�7+8E8]8d8�8�8�8�8979>9X9g9�9�9�9::$:5:S:}:�:�:�:�:�:;	;;*;6;=;F;�;�;<<Y<z<�<�<�<�<�<(=3=:=[=f=n=�=�=�=�=>2>e>|>�>�>�>�>??w?�?�?�?�?      D  00&0,0?0D0h0�0�0�0�0�0�0�0�0�0�0�0E1f1x1�1�1�1�1�1�1 2	22-2?2Q2k2�2�2�2�2�2333 343:3K3i3�3�3�3�3�3�3�3�34&444W4�4�4�4�4�455$525@5G5`5�5�5�5�5�5 66&696L6^6�6�68+8g8~8�8�8�8�89%9s9�9�9�9�9::0:L:[:h:o:�:�:�:�:�:�:;F;b;v;�;�;�;�;�;�;<-<W<�<�<�<�<=3=T=y=�=�=�=�=�=#>*>P>�>�>�>�>�>???*?8?Q?_?h?t?�?�?   0     00$0�12�2�2�2�2�233#3*383M3T3e3�3�3�3�3�3�3�34*404>4G4Q4c4k4|4�4�4�4�4�4�4�435O5^5p5w5�5�5�5�56"676R6[6�6�6�677 757S7�7�7�7�7�7<8c8z8�8�89G9L9R9o9w99�9�9�9�9�9�9:3:D:K:Y:`:�:�:�:�:�:; ;g;m;};�;�;W<c<i<u<3=A=f=s=�=�=�=�=�>�>
?!?@?s?�?   @  H  P0�0�0�0�0�0�01,141D1L1s1�1�1�1�1�1�1�122/2T2\2e2k2r2y2�2�2�2�2�2�23I33�3�3�3�3�34L4d4k4�4�4�4�4�45(555@5J5h5�5�5�5�5�5�536E6N6e6o6�6�6�6�6�6�67-737�7�7�7�78#8;8\8r8�8�8�8>9U9�9�9�9�9�9:9:g:�:�:�:�:;;+;M;q;�;�;�;�;�;<(<U<n<v<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<===$=3=h=z=�=�=>+>K>c>u>�>�>�>�>�>?-?N?j?s?�? P  D  0%0Q0@2F2q2x22�2�2�2�2�2�2�2�2�23
333353<3]3�3�3�3�3�344#4:4T4^4�4�4�4�4�4�4�4�45$5+5B5\5c5�5�5�5�5�5�5�5�56676>6_6d6~6�6�6�6�6�6�6�67)737J7d7q7�7�7�7�7�7�7�78828L8S8t8z8�8�8�8�8�8�8
992979Q9X9o9�9�9�9�9�9�9�9::7:<:V:]:t:�:�:�:�:�:�:;;/;n;u;�;�;�;�; <'<.<A<Q<X<�<�<�<�<�<�< =='=M=R=m=t=�=�=�?�?   `    l0w0�0�01 121X1h1o1�1�12>2R2~2�2�2�2�2�213?3n3�3�3�3�3�3464<4R4s4�4�4�4�4�405I5O5d5�5�566B6�6�6�6�6�697w7|7�7�78:8A8�8�8�8959�9�9�9�9�9�9�9::/:K:R:h:�:�:�:�:�:�:
;;2;7;E;R;Y;r;�;�;�;�;�;�;!<(<><]<�<�<�<�<Y=�=�=�=">'>j>s>�>�>�>�>�>�>??"?�?�?�?�?�?�?�?�? p  �  0020@0j0�0�0�0�0�0�0�011+1W1�1�1�1�1;2v2�2�2�2�2�233:3_3f3�3�3�3�3�3�3414A4W4v4�4�4�4�4�4�4�4�4�4�4�4.5h5�5�5�5�5�5�5�5656<6X6w6~6�6�6�6�6/7:7P7X7�7�788/8A8I8R8X8_8f8m8r8w8�8�8�8�8�8�8�8�8�8�8�8�8�899999"9'9d9�9�9�9:$:+:A:h:o:�:�:�:�:�:�:�:;;4;[;b;x;�;�;�;�;�;�;<
<#<?<F<_<�<�<�<�<�<�<�<�<=+=2=H=a=k=�=�=�=�=�=�=�=	>>&>?>I>_>x>>�>�>�>�>�>??(?D?K?g?�?�?�?�?�?�? �  @  00*0F0M0l0�0�0�0�011<1C1d1�1�1�1�1�121282Y2}2�2�2�2�2�23(3C3u3|3�3�3�3�34484_4f4�4�4�4�4515A5o5�56606K6s6�6�6�6�6�6�6�6707{7�7�7�78"8(8F8h8u88�8�8�89-9V9y9�9�9:&:+:A:^:|:�:�:�:�:�:;;K;�;�;�;�;�;�;�;�;�;�;<"<3<E<X<i<z<�<�<1=9=B=H=O=V=]=b=g=|=�=�=�=�=�=>->Q>f>�>�>�>�>�>?)?;?T?�?�?�?�?�?�?�?   �  X  00(0@0G0`0|0�0�0�0�0�0�0�01*111J1f1m1�1�1�1�1�1�1�12242P2W2p2�2�2�2�2�2�2�2*363_3�3�3�3�3�3474C4_4�4�4�4�4�45+5F5]5n55�5�5�5�5�56686U6j66�6�6�6�6�6�6�67,737J7g7n7�7�7�7�7�7�7�78888S8Z8u8�8�8�8�8�8�899&9A9H9c9{9�9�9�9�9�9,:3:8:j:�:�:�:�:�:�:�:;2;H;Z;h;v;�;�;�;�;<#<*<T<�<�<�<�<^=�=>>/>8>A>L>T>f>s>z>�>�>�>�>??[?�?�? �  (  11"1,1J1�1�1�1	22292Q2p2y2�2�2�2�2�2�23*3C3U3`3z3�3�34U4l4�4�45T5k5�5�5�5�5�5
656]6�6�6�67&777=7I7T7w7�7�788'8\8n8�8�8�8929H9b9�9�9h:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�: ;;;;;;;; ;$;(;,;0;4;8;<;@;D;H;L;P;T;X;\;`;d;h;l;p;t;x;�;�;�;�;�;<E<p<�<�< =A=|=�=>>U>[>�>�>?E?�?�?�? �  d  0C0�0�0�0�0�0�01'1+1/13171;1?1C1G1K1O1S1W1[1_1c1g1k1o1s1w1{1�1�1�1�1"2+2E2�2�2�2333`3�3�3�3�3�3�3�344-4F4M4f4�4�4�4�4�4�4�4!5(5A5H5a5z5�5�5�5�5�5�5�56,666O6j6q6�6�6�6�6�6�677(7A7\7c7|7�7�7�7�7�7�78@88�8�8�8
9*9�9�9�9::&:?:`:w:�:�:�:�:;;4;K;R;n;�;�;�;�;�;�;<+<8<?<[<z<�<�<�<=u=�=�=�=�=�=�=>*>1>M>l>s>�>�>�>�>�>�>?<?C?_?�?�?�?�?�?   �  H   000"0T0b0o0�0�0�0�0�0G1w1�1�1�1�1=2R2t2�2�2383L3e3�3�3�3�3�344(4D4K4d4}4�4�4�4�4�4�4�45C5�5�56&6P6{6�6�6�6�67i7�7858n8�8�8�89B9e9�9�9�9�9�9�9.:g:�:�:5;A;h;{;;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;<<<<<<<<#<'<+</<E<Q<\<<�<�<�<=
==.=C=J=k=�=�=�=�=�=w>�>�>�>�>�>�>h?{?�?�?�? �  �  00$0:0A0I0U0o0�0�0�0�0�0�0�0�0�0�0�0�01
1111$1)101?1\1b1k1w1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�122!2'2/2>2H2Z2d2v2�2�2�2�2�2�2�2�2�2333(3:3D3V3`3r3|3�3�3�3�3�3�3�3�3�3�3�3444*444C4M4\4f4u44�4�4�4�4�4�4�4�4�4�455$5.5=5G5V5`5o5y5�5�5�5�5�5�5�5�5�5�5666(676A6P6Z6i6s6�6�6�6�6�6�6�6�6�6�6�6	77"717;7J7T7c7m7|7�7�7�7�7�7�7�7�7�7�7888+858D8N8]8g8v8�8�8�8�8�8�8�8�8�8�8�899%9/9>9H9W9a9p9z9�9�9�9�9�9�9�9�9�9�9:::):8:B:Q:[:j:t:�:�:�:�:�:�:�:�:�:�: ;
;;#;2;<;K;U;d;n;};�;�;�;�;�;�;�;�;�;�;<<<,<6<E<O<^<h<w<�<�<�<�<�<�<�<�<�<�<�<==&=+=@=J=Y=c=r=|=�=�=�=�=�=�=�=�= >
>>#>2><>K>`>j>y>�>�>�>�>�>�>�>�>�>�>? ?*?9?C?R?\?k?u?�?�?�?�?�?�?�?�?�?�? �  �  000$030=0L0V0e0o0~0�0�0�0�0�0�0�0�0�0�0111-171F1P1_1i1x1�1�1�1�1�1�1�1�1�1�1�122'212@2J2Y2c2r2|2�2�2�2�2�2�2�2�2�2�233!3+3:3D3S3]3l3v3�3�3�3�3�3�3�3�3�3�3444%444>4M4W4i4s4�4�4�4�4�4�4�4�4�4�455!5+5:5D5S5X5m5w5�5�5�5�5�5�5�5�5�5�5	66"616;6J6_6i6x6�6�6�6�6�6�6�6�6�6�6
77#7-7<7Q7[7j7t7�7�7�7�7�7�7�7�7�7�7888.888G8Q8`8j8y8�8�8�8�8�8�8�8�8�8�8 999(929A9K9Z9d9s9}9�9�9�9�9�9�9�9�9�9�9	::":,:;:E:T:^:m:w:�:�:�:�:�:�:�:�:�:�:;;;&;5;?;N;X;g;q;�;�;�;�;�;�;�;�;�;�;�;<< </<9<H<R<a<k<z<�<�<�<�<�<�<�<�<�<�<===)=3=B=L=[=e=t=~=�=�=�=�=�=�=�=�=�=�=
>>#>-><>F>U>_>n>x>�>�>�>�>�>�>�>�>�>�>???'?6?@?O?Y?h?r?�?�?�?�?�?�?�?�?�?�?�? �  �  00!000:0I0S0b0l0{0�0�0�0�0�0�0�0�0�0�0111*141C1M1\1f1u11�1�1�1�1�1�1�1�1�1�122$2.2=2G2V2`2o2t2�2�2�2�2�2�2�2�2�2�233343>3M3W3f3p33�3�3�3�3�3�3�3�3�3444*444C4M4\4f4u4�4�4�4�4�4�4�4�4�4�455 555?5N5X5g5q5�5�5�5�5�5�5�5�5�5�5666,666E6O6^6s6}6�6�6�6�6�6�6�6�6�6�6	77#7-7<7F7U7j7t7�7�7�7�7�7�7�7�7�7�7 8
88#828<8K8U8d8n8}8�8�8�8�8�8�8�8�8�8�8999,969E9O9^9h9w9�9�9�9�9�9�9�9�9�9�9�9::&:0:?:I:X:b:q:{:�:�:�:�:�:�:�:�:�:�:;; ;*;9;C;R;\;k;u;�;�;�;�;�;�;�;�;�;�;<<<$<3<=<L<V<e<o<~<�<�<�<�<�<�<�<�<�<�<===-=7=F=P=b=l=~=�=�=�=�=�=�=�=�=�=�=>>>1>;>J>T>f>p>>�>�>�>�>�>�>�>�>???,?6?H?M?b?l?{?�?�?�?�?�?�?�?�?�?�?     H  000-070I0S0b0l0{0�0�0�0�0�0�0�0�0�0�0111*141C1M1\1f1u11�1�1�1�1�1�1�1�1�1�12&202?2I2X2b2q2{2�2�2�2�2�2�2�2�2�2�233$3.3=3G3V3`3o3y3�3�3�3�3�3�3�3�3�3�344$434=4L4V4e4o4~4�4�4�4�4�4�4�4�4�4�455!505:5I5S5b5l5{5�5�5�5�5�5�5�5�5�5�566!606:6I6S6b6l6{6�6�6�6�6�6�6�6�6�6�677$737=7L7a7k7}7�7�7�7�7�7�7�7�7�7�7888,868E8O8^8h8w8�8�8�8�8�8�8�8�8�8�8�899&909?9I9X9b9q9{9�9�9�9�9�9�9�9�9�9�9:: :*:9:C:R:\:n:x:�:�:�:�:�:�:�:�:�:�: ;
;;#;2;<;O;Y;n;x;�;�;�;�;�;�;�;�;	<<(<2<G<Q<f<p<�<�<�<�<�<�<�<�<== =*=?=I=^=h=}=�=�=�=�=�=�=�=�= >>>.>8>J>T>e>�>�>�>�>�>�>�>�?    �  E0L0X0h0�0�0�0�0.151K1~1�1�1�1�1�122)2_2f2|2�2�2�2�233+3`3g3}3�3�3�3�34e4l4x4�4�4�4$5-535E5�5�5�5�5�5�5�5�5�566&6,636:6A6F6K6a6i6r6x66�6�6�6�6�6�6�6�6�6�6�6�6�6A7X7o7}7�7�7�7�7�7�7�7�7�728>8C8i8q8z8�8�8�8�8�8�8�8�8�8�8�8�8�8�89@9I9O9h9z9�9�9�9�9<:G:]:u:�:�:�:�:�:�:;;);C;J;a;{;�;�;�;�;�;�;�;<)<0<G<a<k<�<�<�<�<=&=S=n=�=�=*>M>V>o>�>�>�>�>�>�>�>�>????G?�?�?�?�?     P   00?0J0[0w0|0�0�0�01�1�1�1�1�1�12&2�2�2 333-3i3p3(4M4S4Z4�4553585Q5X5}5�5�5�5�5�5�5�566/666O6h6o6�6�6�6�6�6�677]7d7l7|7�7�7�7�7�7�7�78>8Y8`8k8�899+959D9L9e9o9�9�9�9�9�9�9�9�9::3:=:R:\:q:{:�:�:�:�:�:�::;R;j;�;�;�;�;<"<.<9<X<n<�<�<�<�<�<�<�<==7=>=Y=t={=�=�=�=�=�=�=>%>,>G>b>o>�>�>�>�>�>�>�>??-?J?~?�?�?�?�?�? 0 8  00!0?0c0j0�0�0�0�0�01W1h1o1�1�1�1�1�1�122(2/2K2R2n2u2�2�2�2�2�2�2�2�23,333O3V3r3}3�3�3a4�4�4�4�4�4"525B5�5�5�5�56�6�6�6�6�6�6�6�677r7�7�7�78!8`8�8�8�8�8�8�8�899,939K9f9�9�9�9::;:b:q:x:�:�:�:�:�:;2;7;V;];�;�;�;�;<a<v<|<�<�<�<�<�<="=N=S=r=y=�=�=�=%>P>�>�>�>�>	??7?<?U?\?�?�?�?�?�?�?�?�?   @ 8  00@0E0^0e0�0�0�0�0�0�0�011.151Z1_1x1�1�1	202B2U2h2x2�2�2�2�23!353P3d3x3�3�3�3�3�3�34!464K4`4u4�4�4�4�4595T5p5�5�5�5�5�56E6|6�6�6�6�6�6�6�6�677777 7>7P7s7�7�7�7�7 88+8=8E8N8T8[8b8i8n8s8}8�8�8�889d9�9�9�9!:Z:~: ;�;�;�;�;<<)<Q<g<{<�<�<�<�<�<=-=A=R=`=�=�=>>,>J>k>�>�>�>�>�>�>?!?G?n?�?�?�? P (  F0t0�0�0�0�01/1[1a1�1�1�1�12212y2�2�2�2�2�2�2�233A3�3�3�3�3�3�344&474H4Z4�4�4�4�4�4�4�4�4�45H5k5s5|5�5�5�5�5�5�5�5�56+686=6b6|6�6�6�6�6�6�6�6�6�6�6�67C7h7u7z7�7�7�7�7�7�7�78
8888*8:8`8�8�8�8�8�8�8�8�8�899(9N9Z9l9w9�9�9�9�9�9:::-:?:E:a:c;w;�;�;�;�<�<=^=|=�=�=8>�>G?[?�? `   Z0e0{0�0�0�0�0191�1�1�1�1 222/2=2r2�2�2�2333!3'3?3E3K3Q3W3�3�3�3[4�4�45,5:5g5�5�5�5�5@6G6e6�6�6�6�67787I7Z7k7|7�7�7�7�7�7l8�8�8g9�9�9�9�9�9�:�:�:�:�:;;/;P;W;s;�;�;�;�;�;�;<#<K<P<o<v<�<�<�<�<�<�<==D=I=�=�=�=>/>v>�>�>�>�>�>??1?6?P?W?z??�?�?�?�?�?�? p 0  00*0D0N0e00�0�0�0�0�0�0�0L1�1�1$2;2N2a2t2�2�2-3X3v3�3�3�3�3�3�34C4J4�4�4�4�4
535:5X5�5�5�5�5�5�56676X6_6}6�6�6�6�6�67A7H7^7�7�7�7�7�7�78&8=8�8�8�89,9a9h9�9�9�9�9�9�9:6:=:[:|:�:�:�:�:�:; ;>;};�;�;�;<<-<N<U<s<�<�<�<�<�<=0=7=U=�=�=�=	>,>Q>n>�>�>�>�>�>�>�>�>?*?1?L?d?k?�?�?�?�?�?�?�?   � �   00K0�0�0%1D1�1�1�1�12(262~2�2�2�233g3�3�3�3�3�3�3�34Q4]4�4�4�4�4�45535K5]5�576~6�6 77"737D7V7n7�7�7�7�7�7�7�7'898T8b8~8�8�8�8�8/9�9�9�9�9%:L:�:q;�;�;�;�;<5<<<]<i<�<�<�<="=b=o=w=�=�=�=�=�=�=�=�=�=�=�=>	>>>>!>S>o>w>�>�>�>b?�?�?�?   �    �0�0�0�0�0�0�0�0�0 1J1[1n11�1�1�1�122*2d2x2�2�2�2�2�2�2�233-3A3Z3o3t3�3�3�3�3444�4�4�4�4c5�5�506I6�6�6�6�6�6�6�677.7:7@7S7Y7p7�7�7�7�7�7 88&8|8�8�8�8�8�8�89J9`9}9�9�9�9B:�:;�;�;'<t<�<%=Z=z=�=�=�=�=�=>!>*>:>O>W>~>�>�>?#?)?1?Y?x?�?�?�? � �   020i0�0�0�0�0�01)1_1h1�1�1�1232H2P2g2�2�2�2�2�23/3h3�3�3�3�34.4c4�4�4�4"5(595J5b5s5�5�5�5�526O6�6�6�6�647I7p7�7�7�7�7�78d8�8�8�8949W9�9�9�9::F:m:�:�:�:�:;@;Z;�;�;�;�;<5<c<�<�<�<�<==a=�=�=�=�=>2>t>�>�>�>?%?@?T?�?�?�?   � �   080S0g0�0�0�0+1K1f1z1�1�1�1A2_2~2�2�2�23Q3q3�3�3�34Q4�4�4�4�4�4*5C5W5�5�5�566/6Z6�6�6�6�6�67_7l7�7�7v8�8�8�89'9�9�9�9�9$:D:_:t:�:�:;>;\;{;�;�;�;<H<h<�<�<�<�<='=i=�=�=�=�=%>^>m>s>�>�>�>�>??7?U?�?�? �    0)080@0Y0{0�0�0�0�0%1F1`1�1�1�1�1�12#272H2Z2q2v2�2�2�2�2<3T3Z3x3�3�3454;4R4g4r4�4�4�4�4�4 5:5�5�5�5�5	66)676`6z6�6�6�6�6717�7�7�7?8\8�8�8�8�8�8#9�9�9�9;:T:j:�:�:�:�:�:;";>;Z;y;�;�;�; <<9<s<�<�<�<�<=T=u=�=�=�=�=�=�=9>W>�>�>�>�>$?D?[?�?�?�?�? � �   0P0�0�0�01(1=1E1l1�1�1�1�112`22�2�23+3v3�3�3!474�4�45,5a5�5�5646p6�6�6�67?7^7�7�7�78.8Q8�8�8�8�8!9S9r9�9�9�9!:@:^:�:�:�:�:&;E;�;�;�;<!<c<�<�<�<�<?=^=�=�=�=>8>^>�>�>�>?7?]?�?�?�?�?�? �   00&0E0�0�01E1�1�1�1�1292S2�2�2�2�2�23<3[3�3�3�304O4e4�4�45 575B5Q5V5^5�5�5�5�5686M6]6r6x6�6�6�6�6�6?7^7o7�7�7�7�7�7�7	8A8^8o8�8�8�8�8�8�89*9@9L9Q9j9�9�9�9�9�9�9:5:Y:�:�:�:�:
;0;u;�;�;�;7<V<s<�<�<�<= =B=`=u=�=�=�=�=�=>>M>�>�>�>�>?8?x?�?�?�?�?   �   0M0p0y0�0�0�0�0�0�0�011G1f1�1�1�1�1*2k2�2�2�2393s3�3�34E4b4|4�4�4�4�4�4�4�4 55&5.5>5T5�5�5�5�56$6I6e6n6~6�6�6�6�6�677&7Q7p7�7�78\8i8s8�8�8$949F9Y9j9x9�9�9:9:[:�:�:�:�:=;t;�;�;�;�;�;<'<D<^<u<�<�<�<�<=:=Y=�=�=�=�=�=>9>b>>�>�>�>�>/?N?�?�?�?     0#000_0|0�0�0�0�0111F1f1�1�1�1�1212E2]2q2�2�2�2�2�2�23%3X3r3�3�3�3�3�34%4C4O4j4�4�4�4�45)5L5�5�5�5�5�566+6@6I6^6�6�6�6
7 7C7f7�7�7�7�788848<8Q8t8�8�8�8969Y9x9�9�9�9�9�9:::H:s:�:�:�:�:;4;K;�;�;�;<<&<I<P<�<�<�<�<=Q=�=�=�=�=�=�=>->e>�>�>�>5?T?q?�?�?�?  �   0!0]0v0�0�0�0�01"181I1a1r1�1�1�12%2R2b2�2�2�2�23?3^3�3�3�34-4P4�4�4�4�4 5R5q5�5�5�5666<6D6t6�6�6�6�6�687W7y7�7�7&8C8b8m8�8�8969U9`9�9�9�9:/:a:�:�:�:�:1;P;�;�;�;< <]<|<�<�<�<-=L=o=�=�=�=!>>>g>v>{>�>�>�>?2?V?|?�?�?�?�?�?   $  0-0F0e0�0�0�0131p1�1�1�12@2_2�2�2�2�2@3]3|3�3�3�3�3D4a4�4�4�4�475T5s5~5�5�5�5�56 6A6Q6j6�6�6�6787W7�7�7�7�78"8*8Z8y8�8�8�8�89:9W9x9�9�9�9�9�9�9:
::;:X:|:�:�:�:�:�:�:�:�:;%;.;5;@;[;y;�;�;�;�;�;�;�;&<A<[<e<l<�<�<�<�<�<�<�<�<=7=Z=t=}=�=�=�=�=�=>A>a>j>q>|>�>�>�>�><?W?}?�?�?�? 0   00H0c0�0�0�01.1X1�1�1�1�1�1�1 2?2{2�2�2�23J3i3�3�3�3�364U4{4�4�4�4�4�4-5L5r5y5�5�5�5�5$6C6i6p6{6�6�6�67:7`7g7r7�7�7�7818W8^8i8�8�8�8	9(9N9U9`9�9�9: :?:J:l:�:�:�:�:�:;;6;U;};�;�;<;<X<p<�<�<�<�<�<$=A=e=k=�=�=�=�=>>>D>m>�>�>�>�>?)?F?b?�?�?�?�?�?   @   02080a0~0�0�0�0�011;1X1y11�1�1�1�1272T2t2z2�2�233+3c3�3�3�3�34B4_4�4�4�4�4�4�4�45@5[5y5�5�5�5�5!6N6l6�6�6�6�67=7e7�7�7�7�7�78 8[8�8�8�89!9=9f9�9�9�9�9�9:>:D:d:�:�:�:�:�:;.;S;p;�;�;�;�;<4<_<�<�<�<�<�<�<!=T=�=�=�=�=�=!>A>X>�>�>�>?@?�?�?�?�?�? P 4  0t0}0�0�0�0�0�01;1D1T1i1r1�1�1�12222;2K2`2h2�2�2�2�23&3-3c3�3�3�3�34B4a4�4�4�4�4�455I5j5{5�5�5�5�566V6y6�6�6�6�6�6�6777V7r7�7�7�7�7�7�7838O8k8�8�8�8�8�89A9G9q9�9�9�9�9�9:@:]:z:�:�:�:�:;7;@;P;e;m;�;�;�;�;�;�;<,<5<<<G<\<�<�<�<	='=0=7=B=^=�=�=�=�=�=�=>M>j>�>�>�>�>?	?)?J?P?p?�?�?�?�?�? ` �   000J0�0�0�0�091T1i1y1�1�1�1�12K2a2x2�2�2�2�233>3Z3l3�3�3�3�3 444O4`4r4�4�4�4�4�4�45505k5�5�5�56:6K6^6w6~6�6�6�67K7e7�7�7�7�7	8%8A8U8i8�8�829A9U9\9�9�9�9:K:j:�:�:�:;;�;�;�;<(<\<v<�<�<�<�<�<7=Q=Y=p=�=�=�=�=�=7>w>�>�>?-?F?e?�?�?�?�? p �   00N0k0z0�0�0�0�0�01<1{1�1�1�122,2S2m22�2�2�2�23B3j3�3�3�3 44R4m4�4�45.5l5�5�5�5 66@6v6�6�6�6�67b77�7�7�7�7�7808[8�8�8�8�8(9G9�9�9�9:C:o:�:�:�:/;Q;s;�;�;$<@<Q<�<�<�<�<=L=h=x=�=�=>>3>J>�>�>�>�>�>?*?r?�?�?�?   �   0=0o0�0�0�01?1^1�1�1�12.2k2�2�2�2�2;3Z3}3�3�34*4M44�4�4�45@5c5i5q5�5�5�5�56A6i6�6�6�6�6�6�67(747P7X7�7�7�7�78*8A8O8V8r8�8�8�8�8�8�89%979M9a9t9�9�9�9�9:::4:<:�:�:�:�:�:�:	;);6;@;p;�;�;�;�;�;<<5<K<j<�<�<�<�<B=h=�=�=�=�=�=>?>_>{>�>�>�>?"?0?7?S?q?x?�?�?�?�?�?�?   � (  0=0D0l0q0�0�0�0�0�0�01161=1e1j1�1�1�1�1�1�12$2C2a2~2�2�2�2�23 393X3l3�3�3�3�344&4H4g4�4�4�4585M5l5�5�5!6.6D6�6�6�6�6�6�6�677?7D7^7e7|7�7�7�7�7�7�7	88*8D8Q8b8|8�8�8�8�8�8919Q9`9g9�9�9�9:+:A:�:�:�:�:�:�:�:;;;;@;z;�;�;<"<Y<s<�<�<�<�<=/=N=�=�=�=�=M>�>�>�>?#?0?>?U?\?�?�?�?   �   D0g0�0�0�01+1S1q1�1�1�1�1�1�12"2A2P2]2k2�2�2�2�2363R3y3�3�3�3�3
4)4F4o4�4�4�4�4�4585P5]5�5�5�5�56,6b6�6�6�6�6�6*7~7�7�7�7�78[8b8�8�8�8
99G9~9�9�9�9 ::<:B:t:�:�:�:�:;;L;�;�;�;<1<D<V<w<�<�<�<�<�<==U=o=z=�=�=�=�=�=>#>7>l>�>�>�>�>?#?4?`?�?�?�?�?�?�? � �   '0q0�0�0�01I1�1�1�12;2I22�2�233<3Y3v3�3�34O4�4�4�4�4'5Z5r55�5�56k6�6�677=7[7�7�7�7888H8m8�8�8�8939Q9c9�9�9�9�9:U:k:}:�:�:(;/;F;j;�;�;�;<B<J<a<�<�<�<=P=o=�=�=>$>[>v>�>�>�>�>�>�>?&?/???T?\?�?�?�?�?�?   � �   "0?0{0�0�0�0�0�0/1\1�1�1�1�122!262>2p2�2�2�2�2�2
3?3H3X3m3u3�3�3�3�3-4J4d4�4�45!5W5s5�5�5�5�56#686h6�6�6�67{7�7�7�78=8R8c8�8�8�89N9m9�9�9: :i:�:�:�:�:�:�:;t;�;�;�;�;	<@<`<�<�<�<�<%=q=�=�=�=�=�=.>K>~>�>�>�>�>??#?O?q?w?�?�?�?   � �   0#0k0x0�0�0�0�0�0	1=1a1�1�1�1�12P2]2k2�2�2�2�2�23Q3y3�3�3�3�34$404N4Z4�4�4�4�4
5&5M5�5�5�5�56.6;6\6w6�6�6�6�67=7�7�7�78878w8�8�8�8�89:9f9{9�9�9<:l:�:�:�:�:;?;\;�;�;�;<2<?<`<�<�<�<=4=l=�=�=>G>�>�>?m?�?�?�?�? � �   )0D0c0y0�0�0�0�0 111?1W1w1�1�1�1�182w2�2*373x3�3R4�4'5J5h5x5�5�56?6Y6�6�6�6�6!7R7y7�7�7�7�738V8t8�8�89(9Y9{9�9�9�9":\:}:�:�:;1;q;�;�;�;�;<.<Q<�<�<�<=(=L=o=�=�=�=->M>n>�>�>�>�>-?P?�?�? � �   00F0K0i0�0�0�0�0)1V1w1�1�1232L2�2�2�2�2�233W3q3�3�3�3�3�3�344R4�4�4�4�4�4�4585L5U5e5z5�5�5�5�566P6o6�6�6�67+7?7P7f7n7�7�7�7,8Q8o8�8�8�89!999_9�9�9:E:�:�:e;�;�;�;<<6<[<�<�<=V=�=�=>>Q>�>�>2?H?\?h?�?�?�?     �   00&0Z0y0�0�0�01a1�1�1�1�1272V2x2�2�2�2353P3W3b3�3�3�384j4�4�4�4�455M5n5�5�5�5�5�56=6]6w6�6�6�6�67.7i7�7�7�7
88J8g8�8�8�8�89P9]9�9�9�9�93:P:�:�:�:�:�:+;3;J;v;�;�;�;�;<<H<q<�<�<�<�<==,=D=[=�=�=�=�=0>Y>�>�>�>�>�>??,?C?q?�?�?�?  �   
0H0U0�0�0�0�0101P1j1{1�1�1�1�12#2S2�2�2�2�2 3X3u3�3�3�34@4M4�4�4�4�4�45B5^5�5�5�5B6h6�67*727d7�7�7�7888T8�8�8,9O9k9�9�9�9�9�9:*:F:�:�:�:;p;�;�;�;(<K<g<�<�<'=D=|=�=�=�=�=>>A>H>_>�>�>�>�>??+?]?|?�?�?     �   <0Y0�0�0�0�0�0:1o1�1�1�1�1�122I2p2�2�2�2	3(3C3�3�3�3�3�3)4I4b4u4�4�4�45#565E5V5�5�5�5�56%6t6�6�6�67*7b7j7�7�7�7868�8�8�899'9/9F9v9�9�9�9:9:S:�:�:�:;;;X;u;�;�;�;<*<F<�<�<�<�<�<6=C=v=�=�=�=�=*>G>c>�>�>�>�>?/?K?�?�?�?�? 0 �   )0\0y0�0�0�0111M1�1�1�1�1�12I2V2�2�2�23(3E3b3~3�3�3
4"464C4J4�4�4�4�4+5H5d5}5�5�5�5P6m6�6�6�67l7�7�7�7868P8i8o8�8�8�8<9Y9�9�9�9�93:@:s:�:�:�:;,;j;w;�;�;<<E<b<�<�<�<�<=`==�=�=>S>r>�>�>9?X?s?�?�? @ �   0J0g0�0�0�01f1�1�1�1�1�1�1212P2w2�2�2�2+3M3l3�3�3�334J4P4U4a4f4v4~4�4�4�4�4�4�4�4�4�4�4�455?5Q5x5�5�5�5�5�576K6a6s6�6�67U7u7�8�89�9�9�9�9::5:K:]:�:;*;;�;�;�;*<Y<m<�<�<�<!=/=u=�=�=�=�=�=>L>^>�>�>�>?2?F?g?�?�?�?   P �  u0{0�0�0r1�1�1H2W2^2t2�2�2�2�2�2�2�2 332393O3h3o3�3�3�3�3�3�3:4G4N4Z4k4w4�4�4�4�4�4$585@5`5f5k5w5}5�5�5�5�5�5�5�5�5�5�5�5�5�566'6,6C6[6i6�6�6�6�6�6�6�6 747>7O7`7q7�7�7�7�7�7�7�7�7F8P8U8a8n8s8�8�8�8�8�8�8�89/979L9Y9e9j9w9}9�9�9�9�9�91:6:C:P:�:�:�:�:�:;+;B;_;�;�;�;�;�;�;�;<!<<<L<[<n<�<�<�<�<�<===9=M=R=d=p=y=�=�=�=�=�=>>%>6>>>J>P>W>\>l>s>�>�>�>�>�>�>�>�>%?G?d?�?�?�? `   040H0k0|0�0�0�0�0�0�0	12191M1c1�1�3�3444464;4A4H4V4\4b4�4�4�4�4�4�4�4555)5.595?5D5U5c5t5�5�5�5�5�5�5�5�5�5!6&636H6Q6m6x6�6�6�6�6�67777!7&71777<7S7a7�7�7�7�7�7�788(8.878=8T8Y8_8u8�8�8�8�8�8�8�8�8�8�8 99F9O9l9}9�9�9�9�9�9�9�9:!:@:N:�:�:�:�:�:�:;;W;�?   p �   "050\0a0n0�0�0�0�011.1y1�1�1�1�112`2�2�2�23O3}3�3�3 4R4\4�4�4	5�677*7;7@7E7\;j;�;�;�;<<<F<c<t<�<�<�<�<�<==#=O=�=�=�=�=�=�=�=	>R>X>l>�>�>�>??-?V?k?w?�?�?�?�?�?�?�?�?   � �   0	0020I0w0�0�0�0�011%1q1�1�1�1�1�12:2�2�2�23J3P3X3^3h3�3494Y4�415`5�6�67>7D7L7S7_7h7|7�9�9: :h:�:�:�:�:;X;�;�;�;<*<J<P<�<�<�<�<
=%=K=�=>$>K?l?�?�?   � 0  0'0,090I0�0�0�0�0�0�0b1�1�1�12!2H2a2p2�2�2�2�233$313U3[3p3�3�3�3�3�3�3�3404B4N4h4s4�4�4�4�4�455(555A5J5e5}5�5�5�5�5�566B6Q6�6�6�6�6�6�6�6�6-7?7c7p7�7�7�7�7�7�7�78S8b8�8�8�8�8�89�9�9�9:+:8:O:`:|:�:�<�<�<=/=>=C=x=�=�=�=�=�=>>.>4>:>I>�>�>�>�>�>�>�>�>�>�>???/?A?Q?V?d?�?�?�?�?�?�?   �    	00060<0A0M0S0b0h0m0y00�0�0�0�0�01%1I1X1i1�1�1�1�1222h2�2�2�2�2�2�2�23B3T3r3�3�3�3�3�344-4:4I4Q4W4o4�4�4�4�4�4�45'535a5�5�5�5616y6�6�6�67&757A7R7\7k7r7�7�7�7�7!8&848C8�8�8�8�8�8�89/9J9�9�9�9�93:?:r:�:�:�:�:;-;6;W;\;i;x;�;�;�;�;�;<<,<:<�<�<=2=G=U=�=�=�=�=�=�?�?�? �   000?0�0�01@1`1�182g2�3�3�344:4B4I4U4^4r4x6�6�6.737@7R7o7�7�7�78J8j8x8�8�8�89K9�9x::�:�;�;W<^<|<�<�<�<�<�<�<�<�<�<�<C=R=�=�=�=�=�=�=)>E>`>p>}>�>�>�>�>�>�>�>�>�>�> ??????$?*?0?6?<?B?H?N?T?Z?`?f?l?r?x?~?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�? � �  00000 0&0,02080>0D0J0P0V0\0b0h0n0t0z0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�01
1111"1(1.141:1@1F1L1R1X1^1d1j1p1v1|1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1 222222$2*20262<2B2H2N2T2Z2`2f2l2r2x2~2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�233333 3&3,32383>3D3J3P3V3\3b3h3n3t3z3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�34
4444"4(4.444:4@4F4L4R4X4^4d4j4p4v4|4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4 555555$5*50565<5B5H5N5T5Z5`5f5l5r5x5~5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�566666 6&6,62686>6D6J6P6V6\6b6h6n6t6z6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�67
7777"7(7.747:7@7F7L7R7X7^7d7j7p7v7|7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7 888888$8*80868<8B8H8N8T8Z8`8f8l8r8x8~8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�899999 9&9,92989>9D9J9P9V9\9b9h9n9t9z9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9:
::::":(:.:4:::@:F:L:R:X:^:d:j:p:v:|:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�: ;;;;;;$;*;0;6;<;B;H;N;T;Z;`;f;l;r;x;~;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;<<<<< <&<,<2<8<><D<J<P<V<\<b<h<n<t<z<�<�<�<�<�<�<�<�<�<�<�<�<�<=>>>>>">(>.>4>:>@>F>L>R>X>^>d>j>w>~>�>�>�>�>�>�>�>�>�> ?.?6?<?G?T?\?j?o?t?y?�?�?�?�?�?�?�?�?   � �   R0n0t0z0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�011111 1&1,121W1h1m1}1�1�1�1�1�1�1�1�1�12222/2L2e2j2�2�2�2�2�2�2�2�23%353:3I3V3h3m3�3�3�3�3�3�3�3�3�34454:4Y4^4u4z4�4�4�4�4�4�4�4�4�455.5=5B5\5a5u5�5�5�5�5�5�5�5�5�5666)6A6F6   � �   �:�:�:�:�:�:�:�:�:�: ;;;;;;;; ;$;(;,;0;�;�;�;�;�;�; <<,<4<<<H<d<p<x<�<�<�<�<�<�<==(=D=L=X=t=�=�=�=�=�=�=�=�=>$>,>8>T>\>h>�>�>�>�>�>�>�>�>�>? ?<?H?d?p?�?�?�?�?�?�?�?�?   � �   00 0$0,040@0\0h0�0�0�0�0�0�0�011,181@1p1�1�1�1�1�1�1�1 242@2\2d2p2�2�2�2�2�2�2�2�2 33$3,383T3\3h3�3�3�3�3�3�3�34$4,484T4\4d4l4t4|4�4�4�4�4�4�4�45$5,545<5D5P5l5t5|5�5�5�5�5�5�5�5�5�5(6<6H6P6�6�6�6�6�6�6�677   @   0000000 0$0(0�5�5�566668888$8,848<8D8L8T8\8d8l8t8|8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8 99999999 9$9(9,9094989<9@9D9H9L9P9T9X9\9`9p9t9x9|9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9 :::::::: :$:(:,:0:4:8:<:@:D:H:L:P:T:X:\:`:d:x:|:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�: ;;;;;;; ;$;8;<;@;D;H;L;P;X;\;`;d;h;l;p;t;x;|;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�; <<<<<<<< <$<(<,<0<4<8<<<@<P<T<X<\<`<d<h<p<t<|<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�< ======$=(=0=4=<=@=H=L=T=X=`=d=l=p=x=|=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�= >>>>> >$>,>0>8><>D>H>P>T>\>`>h>l>t>x>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>????? ?(?,?4?8?@?D?L?P?X?\?d?h?p?t?|?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?   P l   000000$0(00040<0@0H0L0T0X0`0d0l0p0x0|0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0 11111 1$1,10181<1D1H1P1T1\1`1h1l1t1x1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�122222 2(2,2024282@2D2L2P2X2\2d2h2p2t2|2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2 333333$3(30343<3@3H3L3T3X3`3d3l3p3x3|3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3 44444 4$4,40484<4D4H4P4T4\4`4h4l4t4x4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�455555 5(5,54585@5D5L5P5X5\5d5h5p5t5|5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5 666666$6(60646<6@6H6L6T6X6`6d6l6p6x6|6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6 777777 7$7,70787<7D7H7P7T7\7`7h7l7t7x7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�788888 8$8(8,84888@8D8L8P8X8\8d8h8p8t8|8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8 999999$9(9,90949<9@9H9L9T9X9`9d9l9p9x9|9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9 ::::: :$:,:0:8:<:D:H:P:T:\:`:h:l:t:x:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:;;;;;; ;(;,;4;8;@;D;L;P;X;\;d;h;p;t;|;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�; <<<<<<$<(<0<4<<<@<H<L<T<X<`<d<l<p<x<|<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�< ===== =$=,=0=8=<=D=H=P=T=\=`=h=l=t=x=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=>>>>> >(>,>4>8>@>D>L>P>X>\>d>h>p>t>|>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�> ??????$?(?0?4?<?@?H?L?T?X?`?d?l?p?x?|?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?   ` `   00000 0$0,00080<0D0H0P0T0\0`0h0l0t0x0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�011111 1(1,14181@1D1L1P1X1\1d1h1p1t1|1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1�1 222222$2(20242<2@2H2L2T2X2`2d2l2p2x2|2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2�2 33333 3$3,30383<3D3H3P3T3\3`3h3l3t3x3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�3�344444 4(4,44484@4D4L4P4X4\4d4h4p4t4|4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4 555555$5(50545<5@5H5L5T5X5`5d5l5p5x5|5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5 66666 6$6,60686<6D6H6P6T6\6`6h6l6t6x6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�6�677777 7(7,74787@7D7L7P7X7\7d7h7p7t7|7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7 888888$8(80848<8@8H8L8T8X8`8d8l8p8x8|8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8�8 99999 9$9,90989<9D9H9P9T9\9`9h9l9t9x9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9�9::::: :(:,:4:8:@:D:L:P:X:\:d:h:p:t:|:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�:�: ;;;;;;$;(;0;4;<;@;H;L;T;X;`;d;l;p;x;|;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�;�; <<<<< <$<,<0<8<<<D<H<P<T<\<`<h<l<t<x<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<�<===== =(=,=4=8=@=D=L=P=X=\=d=h=p=t=|=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�=�= >>>>>>$>(>0>4><>@>H>L>T>X>`>d>l>p>x>|>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�>�> ????? ?$?,?0?8?<?D?H?P?T?\?`?h?l?t?x?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�? p �  00000 0(0,04080@0D0L0P0X0\0d0h0p0t0|0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0�0 111111$1(10141<1@1H1L1T1X1p1x1�1�1�1�1�1 2(2<2X2t2�2�2�2�23@3H3\3�3�3�3�3�34H4P4d4�4�4�4�4 555P5X5l5�5�5�5�5�5646p6x6�6�6�6�6 7(7<7x7�7�7�7�7�7(808D8�8�8�8�8�8�80989L9�9�9�9�9�9�98:@:T:�:�:�:�:�:;@;H;\;�;�;�;�;�;�;<(<D<�<�<�<�<�<�<0=8=L=�=�=�=�=�=�=8>@>T>�>�>�>�>�>?@?H?\?�?�?�?�?�? �    0H0P0d0�0�0�0�0 11P1X1l1�1�1�1 22282T2p2�2�2�2�2 3(3<3x3�3�3�3�3�3(404D4�4�4�4�4�4�40585L5�5�5�5�5�5�586@6T6�6�6�6�6�67@7H7\7�7�7�7�7�78H8P8d8�8�8�8�8 99P9X9l9�9�9�9 :::X:`:t:�:�:�:�:;@;H;\;�;�;�;�;�;<H<P<d<�<�<�<�< ==P=X=l=�=�=�= >>>X>`>t>�>�>�>??$?`?h?|?�?�?�?   � ,  00,0h0p0�0�0�0�01 141p1x1�1�1�1�1 2(2<2x2�2�2�2�2�2�2(303D3�3�3�3�3�3�30484L4�4�4�4�4�4�485@5T5�5�5�5�5�56@6H6\6�6�6�6�6�6�67H7P7d7�7�7�7�7�7888,8H8�8�8�8�8�8�80989L9h9�9�9�9�9 ::P:X:l:�:�:�:�:; ;4;p;x;�;�;�;�; <(<<<x<�<�<�<�<�<(=0=D=�=�=�=�=�=�=0>8>L>�>�>�>�>�>�>?4?p?x?|?�?�?�?�? � h   0(0<0x0�0�0�0�0�0(101D1�1�1�1�1�1�10282L2�2�2�2�2�2�283@3T3�3�3�3�3�34<4@4D4H4L4P4T4X4\4`4d4h4l4p4t4x4|4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4�4 55555555 5$5(5,5054585<5@5D5H5L5P5T5X5\5`5d5h5l5p5t5x5|5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5�5 66666666 6$6(6,6064686<6@6D6H6L6P6T6X6\6`6d6   P    X0\0`0d0h0l0 �    �;�;�;�;�;�;�;p?�?�?      �0�0�0�0�0�0�3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          NB10    ��J   C:\Documents and Settings\ashok\My Documents\src\twapi\twapi\base\build\release\twapi.pdb 