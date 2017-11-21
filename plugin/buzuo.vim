"===============================================================================
"File: plugin/buzuo.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

if exists('g:buzuo_loaded') && g:buzuo_loaded
    finish
endif
let g:buzuo_loaded = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

let g:buzuo_database_path = '~/.todo/todo.sqlite'

function! s:trigger_denite(param) abort
    execute 'Denite Buzuo:' . a:param
endfunction

function! s:get_complete_candidate(A, L, P) abort
    return buzuo#get_field('status')
endfunction

command! -nargs=0 BuzuoInit :call buzuo#create_data_base()
command! -nargs=1 -complete=custom,s:get_complete_candidate Buzuo :call s:trigger_denite(<q-args>)


let s:save_cpoptions = &cpoptions
set cpoptions&vim
