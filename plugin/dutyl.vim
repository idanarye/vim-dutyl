command! DutylConfigFileEditImportPaths call dutyl#configFile#editImportPaths()

command! DutylDCDstartServer call dutyl#dcd#startServer()
command! DutylDCDstopServer call dutyl#dcd#stopServer()

call dutyl#register#module('dub','dutyl#dub#new',0)
call dutyl#register#module('dcd','dutyl#dcd#new',20)
call dutyl#register#module('configFile','dutyl#configFile#new',100)
