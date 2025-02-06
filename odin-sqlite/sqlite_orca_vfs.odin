package sqlite3

import "core:c"
import "core:math/rand"
import "core:strings"
import oc "core:sys/orca"
import "base:runtime"
/*
after filling in the functions we now get a functype failure.
how can that even happen?
we check type==function->funcType.
where is this info coming from that these could even theoretically be different?

type comes from "immediate (IM3FuncType)"
function comes from module->table0[tableIndex]

"immediate" is just reading the next piece of data pointed to by _pc.
unclear how to debug this.



*/
ctx:runtime.Context


orca_files:map[cstring]oc.file

randstate:rand.Default_Random_State
randgen:=rand.default_random_generator(&randstate)

//iVersion=3 from  https://www.sqlite.org/c3ref/vfs.html
//mxPathname=65534 from the existing VFS win32-longpath
orca_vfs:=sqlite3_vfs{iVersion=1,szOsFile=size_of(sqlite3_file),mxPathname=65534, zName="orca",
    xOpen=file_open,
    xDelete=file_delete,
    xAccess=file_access,
    xFullPathname=file_FullPathname,
    xDlOpen=file_DlOpen,
    xDlError=file_DlError,
    xDlSym=file_DlSym,
    xDlClose=file_DlClose,
    xRandomness=vfs_randomness,
    xSleep=vfs_sleep,
    xCurrentTime=vfs_CurrentTime
}

orca_io_methods:=sqlite3_io_methods{
    xClose=file_close,
    xRead=file_read,
    xWrite=file_write,
    xTruncate=file_truncate,
    xSync=file_sync,
    xFileSize=file_FileSize,
    xLock=file_Lock,
    xUnlock=file_Unlock,
    xCheckReservedLock=file_CheckReservedLock,
    xFileControl=file_FileControl,
    xSectorSize=file_SectorSize,
    xDeviceCharacteristics=file_DeviceCharacteristics
    }


@(export)
sqlite3_os_init :: proc "c" ()->c.int{
    vfs_register(cast(^Vfs)&orca_vfs,1)
    return 0 //TODO ? should be SQLITE_OK.
}

@(export)
sqlite3_os_end :: proc "c" () -> c.int {
    // Cleanup logic
    return 0  //TODO ? should be SQLITE_OK.
}

//name_to_handle:map[cstring]oc.file


sqlite_open_flag :: enum {
    SQLITE_OPEN_READONLY        ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_READWRITE       ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_CREATE          ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_DELETEONCLOSE   ,  /* VFS only */
    SQLITE_OPEN_EXCLUSIVE       ,  /* VFS only */
    SQLITE_OPEN_AUTOPROXY       ,  /* VFS only */
    SQLITE_OPEN_URI             ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_MEMORY          ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_MAIN_DB         ,  /* VFS only */
    SQLITE_OPEN_TEMP_DB         ,  /* VFS only */
    SQLITE_OPEN_TRANSIENT_DB    ,  /* VFS only */
    SQLITE_OPEN_MAIN_JOURNAL    ,  /* VFS only */
    SQLITE_OPEN_TEMP_JOURNAL    ,  /* VFS only */
    SQLITE_OPEN_SUBJOURNAL      ,  /* VFS only */
    SQLITE_OPEN_SUPER_JOURNAL   ,  /* VFS only */
    SQLITE_OPEN_NOMUTEX         ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_FULLMUTEX       ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_SHAREDCACHE     ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_PRIVATECACHE    ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_WAL             ,  /* VFS only */
    SQLITE_OPEN_NOFOLLOW        ,  /* Ok for sqlite3_open_v2() */
    SQLITE_OPEN_EXRESCODE       ,  /* Extended result codes */
}
sqlite_open_flags::bit_set[sqlite_open_flag;c.int]


sqlite3_int64::i64
sqlite3_filename::cstring
sqlite3_syscall_ptr :: #type proc()


sqlite3_io_methods :: struct {
  iVersion:c.int,
  xClose:proc "c" (file:^sqlite3_file)->ResultCode,
  xRead:proc "c" (file:^sqlite3_file,data:rawptr,iAmt:c.int,iOfst:sqlite3_int64)->c.int,
  xWrite:proc "c" (file:^sqlite3_file,data:rawptr,iAmt:c.int,iOfst:sqlite3_int64)->c.int,
  xTruncate:proc "c" (file:^sqlite3_file,size:sqlite3_int64)->c.int,
  xSync:proc "c" (file:^sqlite3_file,flags:c.int)->c.int,
  xFileSize:proc "c" (file:^sqlite3_file,pSize:^sqlite3_int64)->c.int,
  xLock:proc "c" (file:^sqlite3_file,lock:c.int)->c.int,
  xUnlock:proc "c" (file:^sqlite3_file,unlock:c.int)->c.int,
  xCheckReservedLock:proc "c" (file:^sqlite3_file,pResOut:^c.int)->c.int,
  xFileControl:proc "c" (file:^sqlite3_file,op:c.int,pArg:rawptr)->c.int,
  xSectorSize:proc "c" (file:^sqlite3_file)->c.int,
  xDeviceCharacteristics:proc "c" (file:^sqlite3_file)->c.int,
  /*
  /* Methods above are valid for version 1 */
  xShmMap:proc(file:^sqlite3_file,iPg:c.int,pgsz:c.int,dat:c.int,volatile:^rawptr)->c.int,
  xShmLock:proc(file:^sqlite3_file,offset:c.int,n:c.int,flags:c.int)->c.int,
  xShmBarrier:proc(file:^sqlite3_file),
  xShmUnmap:proc(file:^sqlite3_file,deleteFlag:c.int)->c.int,
  
  /* Methods above are valid for version 2 */
  xFetch:proc(file:^sqlite3_file,iOfst:sqlite3_int64,iAmt:c.int,pp:^rawptr)->c.int,
  xUnfetch:proc(file:^sqlite3_file,iOfst:sqlite3_int64,p:rawptr)->c.int,
  
  /* Methods above are valid for version 3 */
  /* Additional methods may be added in future releases */
  */
}

file_close ::proc "c" (file:^sqlite3_file)->ResultCode{
    oc.file_close(file.file_id)
    //TODO handle errors
    return .OK
}

file_read::proc "c" (file:^sqlite3_file,buf:rawptr,iAmt:c.int,iOfst:sqlite3_int64)->c.int{
    whence:oc.file_whence=.SET
    pos:=oc.file_seek(file.file_id,iOfst,whence)
    oc.file_read(file.file_id,u64(iAmt),cast([^]u8)buf)
    //TODO handle errors
    oc.log_info("Read file")
    return 0
}
file_write::proc "c" (file:^sqlite3_file,buf:rawptr,iAmt:c.int,iOfst:sqlite3_int64)->c.int{
//TODO: do we need to guard against being called on a file without write permission?
    whence:oc.file_whence=.SET
    pos:=oc.file_seek(file.file_id,iOfst,whence)
    oc.file_write(file.file_id,u64(iAmt),cast([^]u8)buf)
    //TODO handle errors
    oc.log_info("Write file")
    return 0
}

//TODO: this should return an error under some circumstances, even as a no-op
//see  https://www.sqlite.org/src/doc/trunk/src/test_demovfs.c
file_truncate::proc "c" (file:^sqlite3_file,size:sqlite3_int64)->c.int{
    return 0
}
//files should always refer to something on-disk, so no sync needed???
file_sync::proc "c" (file:^sqlite3_file,flags:c.int)->c.int{
    return 0
}

file_FileSize::proc "c" (file:^sqlite3_file,pSize:^sqlite3_int64)->c.int{
    status:=oc.file_get_status(file.file_id)
    pSize^=cast(i64)status.size
    return 0
}

file_Lock::proc "c" (file:^sqlite3_file,lock:c.int)->c.int{
    return 0
}
file_Unlock::proc "c" (file:^sqlite3_file,unlock:c.int)->c.int{
    return 0
}
file_CheckReservedLock::proc "c" (file:^sqlite3_file,pResOut:^c.int)->c.int{
    return 0
}
file_FileControl::proc "c" (file:^sqlite3_file,op:c.int,pArg:rawptr)->c.int{
    return cast(c.int)ResultCode.NOTFOUND
}
file_SectorSize::proc "c" (file:^sqlite3_file)->c.int{
    return 0
}
file_DeviceCharacteristics::proc "c" (file:^sqlite3_file)->c.int{
    return 0
}





sqlite3_file :: struct{
    pMethods:^sqlite3_io_methods,
    file_id:oc.file
}

sqlite3_vfs :: struct {
    iVersion:c.int,
    szOsFile:c.int,
    mxPathname:c.int,
    pNext:^sqlite3_vfs,
    zName:cstring,
    pAppData:rawptr,
    xOpen:proc "c" (vfs:^sqlite3_vfs,zName:sqlite3_filename,fileptr:^sqlite3_file,flags:c.int,outflags:^c.int)->c.int,
    xDelete:proc "c" (vfs:^sqlite3_vfs,zname:cstring,syncDir:c.int)->c.int,
    xAccess:proc "c" (vfs:^sqlite3_vfs,zname:cstring,flags:c.int,pResOut:^c.int)->c.int,
    xFullPathname:proc "c" (vfs:^sqlite3_vfs,zname:cstring,nOut:c.int,zOut:^c.char)->c.int,
    xDlOpen:proc "c" (vfs:^sqlite3_vfs,zFilename:cstring)->rawptr,
    xDlError:proc "c" (vfs:^sqlite3_vfs,nByte:c.int,zErrMsg:[^]byte),
    xDlSym:proc "c" (vfs:^sqlite3_vfs,data:rawptr,zSymbol:cstring)->rawptr, //probably wrong signature?
    xDlClose:proc "c" (vfs:^sqlite3_vfs,data:rawptr),
    xRandomness:proc "c" (vfs:^sqlite3_vfs,nByte:c.int,zOut:[^]byte)->c.int,
    xSleep:proc "c" (vfs:^sqlite3_vfs,microseconds:c.int)->c.int,
    xCurrentTime:proc "c" (vfs:^sqlite3_vfs,time:^c.double)->c.int,
    
    /*//unclear how to implement these functions. They are vers>1, so setting iVersion=1 ignores them anyway.

    
    xGetLastError:proc(vfs:^sqlite3_vfs,id:c.int,msg:cstring)->c.int,

    xCurrentTimeInt64:proc(vfs:^sqlite3_vfs,ctime:^sqlite3_int64)->c.int,

    xSetSystemCall:proc(vfs:^sqlite3_vfs,zName:cstring,syscallptr:sqlite3_syscall_ptr)->c.int,
    xGetSystemCall:proc(vfs:^sqlite3_vfs,zName:cstring)->sqlite3_syscall_ptr,
    xNextSystemCall:proc(vfs:^sqlite3_vfs,zname:cstring)->cstring
*/
}



file_open::proc "c" (vfs:^sqlite3_vfs,zFileName:sqlite3_filename,fileptr:^sqlite3_file,flags:c.int,outflags:^c.int)->c.int{
    //zFileName could be a null pointer. Could also have a suffix added.

    flags:=transmute(sqlite_open_flags)flags
    oc_flags :oc.file_open_flags
    oc_access:oc.file_access
    if .SQLITE_OPEN_READONLY in flags {
        oc_access |= {.READ}
    }
    else if .SQLITE_OPEN_READWRITE in flags{
        oc_access |= {.READ,.WRITE}
    }
    if .SQLITE_OPEN_CREATE in flags{
        oc_flags |= {.CREATE}
    }
    scratch := oc.scratch_begin()
    defer oc.scratch_end(scratch)
    //TODO: strings.clone_from_cstring doesn't work. Must use orca substitute. Is this intended?
    oc.log_info("cloning fname string")
    oc.log_info(zFileName)
    oc.log_info("cloned fname string")
    fnamestr:=oc.str8_push_cstring(scratch.arena,zFileName)
    file:=oc.file_open_with_request(fnamestr,oc_access,oc_flags)
    orca_files[zFileName]=file

    //fill in fileptr struct
    fileptr.pMethods=&orca_io_methods //TODO should this be a static thing independent of the db file?
    fileptr.file_id=file
    //if open failed (how to tell???) don't do anything.
    //TODO: fill in output flags
    oc.log_info("Open file")
    return 0
}

file_delete :: proc "c" (vfs:^sqlite3_vfs,zname:cstring,syncDir:c.int)->c.int{
    // TODO: how do you delete files?
    return 0
}

file_access :: proc "c" (vfs:^sqlite3_vfs,zname:cstring,flag:c.int,pResOut:^c.int)->c.int{
    flag:=cast(AccessFlag)flag
    file_handle:oc.file
    status:oc.file_status
    if zname in orca_files{
        file_handle = orca_files[zname]
        status = oc.file_get_status(file_handle)
    }else{
        file_handle = oc.file_nil()
        //TODO: this sets perm to 0, normally inaccessible. Is this ok?
        status:oc.file_access
    }
    
    switch flag{
        case .EXISTS:
           pResOut^= zname in orca_files ? 1 : 0
        case .READWRITE:
            fileflags:=status.perm
            pResOut^= .OWNER_WRITE in fileflags && .OWNER_READ in fileflags ? 1 : 0
        case .READ: //never used
            pResOut^=0
    }

    return 0
}

file_FullPathname::proc "c" (vfs:^sqlite3_vfs,zname:cstring,nOut:c.int,zOut:^c.char)->c.int{
    zOut:=transmute([^]c.char)zOut
    //TODO: how to get full pathnames from Orca? Is this ok?
    N:=min(nOut-1,c.int(len(zname)))
    zname:=transmute([^]u8)zname
    i:c.int
    for i=0; i<N; i+=1 {
        zOut[i]=zname[i]
    }
    zOut[i]=0
    return 0
}

file_DlOpen::proc "c" (vfs:^sqlite3_vfs,zFilename:cstring)->rawptr{
    return nil
}
file_DlError::proc "c" (vfs:^sqlite3_vfs,nByte:c.int,zErrMsg:[^]byte){
    zErrMsg[0]=0
}
file_DlSym::proc "c" (vfs:^sqlite3_vfs,data:rawptr,zSymbol:cstring)->rawptr{
    return nil
} 
file_DlClose::proc "c" (vfs:^sqlite3_vfs,data:rawptr){
    return
}


vfs_randomness :: proc "c" (vfs:^sqlite3_vfs,nByte:c.int,zOut:[^]byte)->c.int{
    context = ctx

    for i:c.int=0; i<nByte;i+=1{
        bytes:=rand.uint32(randgen)
        zOut[i]=cast(byte)bytes
    }
    return nByte
}

//TODO: how to sleep with orca?
vfs_sleep :: proc "c" (vfs:^sqlite3_vfs,microseconds:c.int)->c.int{
    return 0;
}
//TODO: should be current UTC time expressed as a Julian day.
//Bad implementation, copied from https://www.sqlite.org/src/doc/trunk/src/test_demovfs.c
vfs_CurrentTime::proc "c" (vfs:^sqlite3_vfs,pTime:^c.double)->c.int{
    raw_time:=oc.clock_time(.DATE)
    pTime^=raw_time/86400.0 + 2440587.5
    return 0
}

