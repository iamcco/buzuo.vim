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

" quote
function! s:quote(str, ...) abort
    let l:wrap = get(a:, '1', '"')
    return l:wrap . escape(a:str, "'\"") . l:wrap
endfunction

" format cmd
function! s:get_cmd_sql(sql) abort
    return join([
                \ s:sqlite,
                \ buzuo#get_database_path(),
                \ a:sql
                \], ' ')
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
    if l:p !~# '\v^\/.*$' && l:p !~# '\v^\a:.*$' && l:p !~# '\v^\~\/.*$'
        let l:p = expand('~') . '/' . g:buzuo_database_path
    elseif l:p =~# '\v\~\/.*'
        let l:p = expand(l:p)
    endif
    return l:p
endfunction

"create database
function! buzuo#create_data_base() abort
    "get database path
    let l:p = buzuo#get_database_path()
    "check database
    if filereadable(l:p)
        call s:echo_error('database file '
                    \. g:buzuo_database_path
                    \. ' already exists')
    endif

    "sql to create table type [now, later, longterm]
    let l:sql_create_table = 'CREATE TABLE IF NOT EXISTS buzuo('
                \. 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
                \. 'create_time INTEGER,'
                \. 'modify_time INTEGER,'
                \. 'status,'
                \. 'category,'
                \. 'type,'
                \. 'title,'
                \. 'content'
                \. ')'

    "create directory if not exists
    let l:p_dir = fnamemodify(l:p, ':p:h')
    if !isdirectory(l:p_dir)
        call mkdir(l:p_dir, 'p')
    endif
    "cmd to create database
    let l:cmd_create_database = s:get_cmd_sql(s:quote(l:sql_create_table))
    return s:system(l:cmd_create_database)
endfunction

"insert new item
function! buzuo#insert_item(category, type, title) abort
    let l:now_time = localtime()
    let l:sql_insert_item = 'INSERT INTO '
                \. 'buzuo(create_time,modify_time,status,category,type,title)'
                \. 'VALUES(%s,%s,%s,%s,%s,%s)'
    let l:sql_insert_item = printf(l:sql_insert_item,
                \ l:now_time,
                \ l:now_time,
                \ s:quote('pending'),
                \ s:quote(a:category),
                \ s:quote(a:type),
                \ s:quote(a:title),
                \)
    let l:cmd_insert_item = s:get_cmd_sql(s:quote(l:sql_insert_item))
    return s:system(l:cmd_insert_item)
endfunction

"update item
function! buzuo#update_item(id, field, value) abort
    let l:now_time = localtime()
    let l:sql_update_item = 'UPDATE buzuo SET modify_time=%s, %s=%s where id = %s'
    let l:sql_update_item = printf(l:sql_update_item,
                \ l:now_time,
                \ a:field,
                \ s:quote(a:value),
                \ a:id)
    let l:cmd_update_item = s:get_cmd_sql(s:quote(l:sql_update_item))
    return s:system(l:cmd_update_item)
endfunction

"get field
function! buzuo#get_distinct_field(field) abort
    "get tags
    let l:sql_query_tags = 'SELECT DISTINCT(' . a:field . ') FROM buzuo'
    let l:cmd_get_tags = s:get_cmd_sql(s:quote(l:sql_query_tags))
    let l:output = s:system(l:cmd_get_tags)
    if l:output ==# -1
        return ''
    endif
    return l:output
endfunction

" input
function! buzuo#input(param) abort
    let l:res = ''
    call inputsave()
    let l:res = input(a:param)
    call inputrestore()
    redraw
    return l:res
endfunction

" start
function! buzuo#start(args) abort
    try
        let l:args = split(a:args, ':')
        let l:type = l:args[0]
        let l:args = [join(l:args[1:-1], ':')]
        call call(function('buzuo#' . l:type), l:args)
    catch /[eE]700/
        call s:echo_error('option not exists')
    catch /.*/
        call s:echo_error(v:exception)
    endtry
endfunction

" init database
function! buzuo#init(param) abort
    if buzuo#create_data_base() !=# -1
        echo 'create database success! (ง •̀_•́)ง'
    endif
endfunction

function! buzuo#add_category_candidate(A, L, P) abort
    return join(g:buzuo_category_candidate, "\n")
endfunction

function! buzuo#add_type_candidate(A, L, P) abort
    return join(g:buzuo_type_candidate, "\n")
endfunction

" add item
function! buzuo#add(param) abort
    let l:args = split(a:param, ':')
    let l:category = get(l:args, '0', '')
    let l:type = get(l:args, '1', '')
    let l:title = join(l:args[2:], ':')
    if l:title ==# ''
        let l:title = buzuo#input({
                    \ 'prompt': 'Enter title: ',
                    \})
    endif
    if l:title ==# ''
        echo 'cancel'
        return 0
    endif
    if l:category ==# ''
        let l:category = buzuo#input({
                    \ 'prompt': 'Enter category: ',
                    \ 'completion': 'custom,buzuo#add_category_candidate'
                    \})
    endif
    if l:category ==# ''
        let l:category = g:buzuo_category_default
    endif
    if l:type ==# ''
        let l:type = buzuo#input({
                    \ 'prompt': 'Enter type: ',
                    \ 'completion': 'custom,buzuo#add_type_candidate'
                    \})
    endif
    if l:type ==# ''
        let l:type = g:buzuo_type_default
    endif
    if buzuo#insert_item(l:category, l:type, l:title) !=# -1
        echo 'add item success! (ง •̀_•́)ง'
    endif
endfunction

" Denite buzuo
function! buzuo#list(param) abort
    execute 'Denite buzuo:' . a:param
endfunction
