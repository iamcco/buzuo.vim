"exec source vim
function! s:trim(str) abort
    return substitute(a:str, '\v(^[\n\r \t]*|[\n\r \t]*$)', '', 'g')
endfunction

execute 'source ' . expand('%:p:h') . '/../autoload/buzuo.vim'

let g:buzuo_database_path = expand('%:p:h') . '/buzuo.database'

echo 'create database path: ' . buzuo#get_database_path()
call buzuo#create_data_base()

if executable('sqlite')
    let s:sqlite = 'sqlite'
else
    let s:sqlite = 'sqlite3'
endif

echo 'sqlite command: ' . s:sqlite

let s:buzuo_schema = system(join([
            \ s:sqlite,
            \ buzuo#get_database_path(),
            \ '".schema buzuo"'
            \], ' '))

let s:buzuo_schema = s:trim(s:buzuo_schema)

let s:expect_schema = 'CREATE TABLE buzuo(id INTEGER PRIMARY KEY AUTOINCREMENT,create_time INTEGER,modify_time INTEGER,status,tag,type,title,content);'

echo 'expect schema: ' . s:expect_schema

echo 'create schema: ' . s:buzuo_schema

let s:result = s:expect_schema ==? s:buzuo_schema

echo 'expect schema ==? create schema: ' . s:result

echo 'insert item: '

call buzuo#insert_item('word', 'now', 'title')

let s:id = s:trim(system(join([
            \ s:sqlite,
            \ buzuo#get_database_path(),
            \ '"select id from buzuo where title = \"title\" limit 1"'
            \])))

echo 'insert item id: ' . s:id

let s:title = 'new-title'

echo 'update item title to: ' . s:title

call buzuo#update_item(s:id, 'title', s:title)

let s:update_title = s:trim(system(join([
            \ s:sqlite,
            \ buzuo#get_database_path(),
            \ '"select title from buzuo where id = ' . s:id . '"'
            \])))

echo 'after update title: '. s:update_title

let s:result = s:update_title ==# s:title

echo 'update result: ' . s:result

echo 'get distinct title filed test: '

echo 'title field: '.  join(split(buzuo#get_distinct_field('title'), "\n"), '//')
