"===============================================================================
"File: plugin/buzuo.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

let g:buzuo_debug = 1
if exists('g:buzuo_debug') && g:buzuo_debug
elseif exists('g:buzuo_loaded') && g:buzuo_loaded
    finish
endif
let g:buzuo_loaded = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

let g:buzuo_database_path = '~/.buzuo/buzuo.database'
let g:buzuo_category_candidate = join(['work', 'study', 'person'], "\n")
let g:buzuo_category_default = 'work'
let g:buzuo_type_candidate = join(['now', 'shortterm', 'longterm'], "\n")
let g:buzuo_type_default = 'now'

function! s:get_complete_candidate(A, L, P) abort
    return join([ 'init', 'add', 'list' ], "\n")
endfunction

command! -nargs=1 -complete=custom,s:get_complete_candidate Buzuo :call buzuo#start(<q-args>)

let s:save_cpoptions = &cpoptions
set cpoptions&vim
