# ============================================================================
# FILE: buzuo.py
# AUTHOR: 年糕小豆汤 <ooiss@qq.com>
# License: MIT license
# ============================================================================

import time
import sqlite3
from denite import util
from .base import Base
from ..kind.base import Base as BaseKind

def timeago(now, seconds):
    diff = now - seconds
    if diff <= 0:
        return 'just now'
    if diff < 60:
        return str(int(diff)) + ' seconds ago'
    if diff/60 < 60:
        return str(int(diff/60)) + ' minutes ago'
    if diff/3.6e+3 < 24:
        return str(int(diff/3.6e+3)) + ' hours ago'
    if diff/8.64e+4 < 24:
        return str(int(diff/8.64e+4)) + ' days ago'
    if diff/6.048e+5 < 4.34812:
        return str(int(diff/6.048e+5)) + ' weeks ago'
    if diff/2.63e+6 < 12:
        return str(int(diff/2.63e+6)) + ' months ago'
    return str(int(diff/3.156e+7)) + 'years ago'

class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'buzuo'
        self.kind = Kind(vim)

    def on_init(self, context):
        database = self.vim.call('buzuo#get_database_path')
        context['__db_conn'] = sqlite3.connect(database)

    def on_close(self, context):
        context['__db_conn'].close()
        context['__db_conn'] = None

    def gather_candidates(self, context):
        sql = 'SELECT * FROM buzuo WHERE {s[category]} and {s[type]} and {s[status]} ORDER BY id desc'
        format_sql = {
                'category': 'category = ?',
                'type': 'type = ?',
                'status': 'status = ?',
                }
        conn = context['__db_conn']
        cursor = conn.cursor()
        args = dict(enumerate(context['args']))
        category = str(args.get(0, 'work'))
        the_type = str(args.get(1, 'now'))
        status = str(args.get(2, 'pending'))
        if category == '/':
            format_sql['category'] = '1 = ?'
            category = 1
        if the_type == '/':
            format_sql['type'] = '1 = ?'
            the_type = 1
        if status == '/':
            format_sql['status'] = '1 = ?'
            status = 1
        cursor.execute(sql.format(s=format_sql), (category, the_type, status))
        time_now = time.time()
        candidata = []
        for row in cursor:
            candidata.append({
                'word': '%-4d [%s] %s' % (row[0], timeago(time_now, row[1]), row[6]),
                'source__id': row[0],
                'source__status': row[3],
                'source__category': row[4],
                'source__type': row[5],
                'source__title': row[6],
                'source__content': row[7],
                'source__args': args,
                })
        if not len(candidata):
            candidata.append({
                'word': '1    list is empty :)',
                'source__status': status,
                'source__category': category,
                'source__type': the_type,
                'source__args': args,
                })
        return candidata

    def highlight(self):
        self.vim.command('highlight default link deniteSource__BuzuoHeader Statement')
        self.vim.command('highlight default link deniteSource__BuzuoId Special')
        self.vim.command('highlight default link deniteSource__BuzuoTime Constant')

    def define_syntax(self):
        self.vim.command('syntax case ignore')
        self.vim.command(r'syntax match deniteSource__BuzuoHeader /^.*$/ ' +
                         r'containedin=' + self.syntax_name)
        self.vim.command(r'syntax match deniteSource__BuzuoTime /\v\[(\w|\s){-}\sago\]/ ' +
                         r'contained containedin=deniteSource__BuzuoHeader')
        self.vim.command(r'syntax match deniteSource__BuzuoId /\v^.*%7c/ contained ' +
                         r'containedin=deniteSource__BuzuoHeader')

def doNothingWithoutId(action):
    def wrapper(self, context):
        if context['targets'][0].get('source__id', None) is None:
            return
        return action(self, context)
    return wrapper

def addDBConnect(action):
    def wrapper(self, context):
        conn = sqlite3.connect(self.vim.call('buzuo#get_database_path'))
        res = action(self, context, conn)
        conn.close()
        return res
    return wrapper


class Kind(BaseKind):
    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'buzuo'
        self.default_action = 'toggle'
        self.persist_actions = ['toggle', 'edit', 'delete', 'add']
        self.redraw_actions = ['toggle', 'edit', 'delete', 'add']

    def action_list_all(self, context):
        context['sources_queue'].append([
            {'name': 'buzuo', 'args': ['/', '/', '/']},
            ])

    def action_switch_category(self, context):
        target = context['targets'][0]
        category = util.input(
                self.vim, context, 'Enter category: ', '', 'custom,buzuo#add_category_candidate')
        if not len(category):
            return
        args = target['source__args']
        the_type = str(args.get(1, 'now'))
        status = str(args.get(2, 'pending'))
        context['sources_queue'].append([
            {'name': 'buzuo', 'args': [category, the_type, status]},
            ])

    def action_switch_type(self, context):
        target = context['targets'][0]
        the_type = util.input(
                self.vim, context, 'Enter type: ', '', 'custom,buzuo#add_type_candidate')
        if not len(the_type):
            return
        args = target['source__args']
        category = str(args.get(0, 'work'))
        status = str(args.get(2, 'pending'))
        context['sources_queue'].append([
            {'name': 'buzuo', 'args': [category, the_type, status]},
            ])

    def action_switch_status(self, context):
        target = context['targets'][0]
        status = 'done' if target['source__status'] == 'pending' else 'pending'
        args = target['source__args']
        category = str(args.get(0, 'work'))
        the_type = str(args.get(1, 'now'))
        context['sources_queue'].append([
            {'name': 'buzuo', 'args': [category, the_type, status]},
            ])

    @doNothingWithoutId
    @addDBConnect
    def action_toggle(self, context, conn):
        cursor = conn.cursor()
        todos = []
        time_now = int(time.time())
        for target in context['targets']:
            status = 'done' if target['source__status'] == 'pending' else 'pending'
            todos.append((time_now, status, target['source__id']))
        cursor.executemany('UPDATE buzuo SET modify_time = ?, status = ? WHERE id = ?', todos)
        conn.commit()

    @doNothingWithoutId
    @addDBConnect
    def action_edit(self, context, conn):
        cursor = conn.cursor()
        target = context['targets'][0]
        title = util.input(self.vim, context, 'Change to: ', target['source__title'])
        if not len(title):
            return
        category = util.input(
                self.vim, context, 'Enter category: ', '', 'custom,buzuo#add_category_candidate')
        if not len(category):
            category = target['source__category']
        the_type = util.input(
                self.vim, context, 'Enter type: ', '', 'custom,buzuo#add_type_candidate')
        if not len(the_type):
            the_type = target['source__type']
        cursor.execute(
                'UPDATE buzuo SET title = ?, category = ?, type = ? WHERE id = ?',
                (title, category, the_type, target['source__id']))
        conn.commit()

    @doNothingWithoutId
    @addDBConnect
    def action_delete(self, context, conn):
        cursor = conn.cursor()
        cursor.executemany('DELETE FROM buzuo WHERE id = ?',
                [(x['source__id'],) for x in context['targets']])
        conn.commit()

    @addDBConnect
    def action_add(self, context, conn):
        title = util.input(self.vim, context, 'Enter title: ')
        if not len(title):
            return
        category = util.input(
                self.vim, context, 'Enter category: ', '', 'custom,buzuo#add_category_candidate')
        if not len(category):
            category = self.vim.eval('g:buzuo_category_default')
        the_type = util.input(
                self.vim, context, 'Enter type: ', '', 'custom,buzuo#add_type_candidate')
        if not len(the_type):
            the_type = self.vim.eval('g:buzuo_type_default')
        cursor = conn.cursor()
        time_now = int(time.time())
        cursor.execute('INSERT INTO buzuo \
                (create_time, modify_time, status, category, type, title) \
                VALUES (?,?,?,?,?,?)',
                (time_now, time_now, 'pending', category, the_type, title))
        conn.commit()
