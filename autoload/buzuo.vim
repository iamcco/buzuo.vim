"===============================================================================
"File: autoload/buzuo.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

"check sqlite executable
if executable('sqlite')
    let s:sqlite = 'sqlite'
elseif executable('sqlite3')
    let s:sqlite = 'sqlite3'
endif

"err message format
function! s:echo_error(mess) abort
    echoerr '[Plugin: buzuo.vim]: ' . a:mess
endfunction

function! s:quote(str, ...) abort
    let l:wrap = get(a:, '1', "'")
    return l:wrap . escape(a:str, "'\"") . l:wrap
endfunction

"system wrap return -1 if occurred error
function! s:system(cmd) abort
    let l:output = system(a:cmd)
    if v:shell_error
        call s:echo_error(l:output)
        return -1
    endif
    return l:output
endfunction

"get database path
function! buzuo#get_database_path() abort
    "check database path
    if !exists('g:buzuo_database_path')
        call s:echo_error('g:buzuo_database_path variable not exists')
    endif
    let l:p = g:buzuo_database_path
    "check absolute path
    if l:p !~# '\v\/.*' && l:p !~# '\v\a:.*' && l:p !~# '\v\~\/.*'
        let l:p = expand('~') . '/' . g:buzuo_database_path
    elseif l:p =~# '\v\~\/.*'
        let l:p = expand(l:p)
    endif
    return l:p
endfunction

"create database
function! buzuo#create_data_base() abort
    "sql to create table type [now, later, longterm]
    let l:sql_create_table = 'CREATE TABLE IF NOT EXISTS buzuo('
                \. 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
                \. 'create_time INTEGER,'
                \. 'modify_time INTEGER,'
                \. 'status,'
                \. 'tag,'
                \. 'type,'
                \. 'title,'
                \. 'content'
                \. ')'

    "get database path
    let l:p = buzuo#get_database_path()
    "check database
    if filereadable(l:p)
        call s:echo_error('database file '
                    \. g:buzuo_database_path
                    \. ' already exists')
    endif
    "create directory if not exists
    let l:p_dir = fnamemodify(l:p, ':p:h')
    if !isdirectory(l:p_dir)
        call mkdir(l:p_dir, 'p')
    endif
    "cmd to create database
    let l:cmd_create_database = join([
                \ s:sqlite,
                \ l:p,
                \ s:quote(l:sql_create_table),
                \], ' ')
    if s:system(l:cmd_create_database) !=# -1
        echo 'database create success!'
    endif
endfunction

"insert new item
function! buzuo#insert_item(tag, type, title) abort
    let l:now_time = localtime()
    let l:sql_insert_item = '"INSERT INTO '
                \. 'buzuo(create_time,modify_time,status,tag,type,title)'
                \. 'VALUES(%s,%s,%s,%s,%s,%s)"'
    let l:sql_insert_item = printf(l:sql_insert_item,
                \ l:now_time,
                \ l:now_time,
                \ s:quote('pending'),
                \ s:quote(a:tag),
                \ s:quote(a:type),
                \ s:quote(a:title),
                \)
    let l:cmd_insert_item = join([
                \ s:sqlite,
                \ buzuo#get_database_path(),
                \ l:sql_insert_item,
                \], ' ')
    if s:system(l:cmd_insert_item) !=# -1
        echo 'done'
    endif
endfunction

"update item
function! buzuo#update_item(id, field, value) abort
    let l:now_time = localtime()
    let l:sql_insert_item = '"UPDATE buzuo SET modify_time=%s, %s=%s where id = %s"'
    let l:sql_insert_item = printf(l:sql_insert_item,
                \ l:now_time,
                \ a:field,
                \ s:quote(a:value),
                \ a:id)
    let l:cmd_update_item = join([
                \ s:sqlite,
                \ buzuo#get_database_path(),
                \ l:sql_insert_item,
                \], ' ')
    if s:system(l:cmd_update_item) !=# -1
        echo 'done'
    endif
endfunction

"get field
function! buzuo#get_distinct_field(field) abort
    "get tags
    let l:sql_query_tags = 'SELECT DISTINCT(' . a:field . ') FROM buzuo'
    let l:cmd_get_tags = join([
                \ s:sqlite,
                \ buzuo#get_database_path(),
                \ s:quote(l:sql_query_tags),
                \], ' ')
    let l:output = s:system(l:cmd_get_tags)
    if l:output ==# -1
        return ''
    endif
    return l:output
endfunction
