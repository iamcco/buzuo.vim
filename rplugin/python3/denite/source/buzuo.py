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
        conn = context['__db_conn']
        cursor = conn.cursor()
        args = dict(enumerate(context['args']))
        category = str(args.get(0, 'work'))
        the_type = str(args.get(1, 'now'))
        status = str(args.get(2, 'pending'))
        candidata = []
        cursor.execute('select * from buzuo \
                where status = ? and category = ? and type = ? order by id desc',
                (status, category, the_type))
        time_now = time.time()
        for row in cursor:
            candidata.append({
                'word': '%-4d [%s] %s' % (row[0], timeago(time_now, row[1]), row[6]),
                'source__id': row[0],
                'source__status': row[3],
                'source__category': row[4],
                'source__type': row[5],
                'source__title': row[6],
                'source__content': row[7],
                'source__db_conn': conn,
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

class Kind(BaseKind):
    def __init__(self, vim):
        super().__init__(vim)

        self.default_action = 'toggle'
        self.persist_actions = ['toggle', 'edit', 'delete', 'add']
        self.redraw_actions = ['toggle', 'edit', 'delete', 'add']
        self.name = 'buzuo'

    def action_toggle(self, context):
        conn = context['targets'][0]['source__db_conn']
        cursor = conn.cursor()
        todos = []
        time_now = int(time.time())
        for target in context['targets']:
            status = 'done' if target['source__status'] == 'pending' else 'pending'
            todos.append((time_now, status, target['source__id']))
        cursor.executemany('UPDATE buzuo SET modify_time = ?, status = ? WHERE id = ?', todos)
        conn.commit()

    def action_edit(self, context):
        conn = context['targets'][0]['source__db_conn']
        cursor = conn.cursor()
        target = context['targets'][0]
        title = util.input(self.vim, context, 'Change to: ', target['source__title'])
        if not len(title):
            return
        cursor.execute('UPDATE buzuo SET title = ? WHERE id = ?', (title, target['source__id']))
        conn.commit()

    def action_delete(self, context):
        conn = context['targets'][0]['source__db_conn']
        cursor = conn.cursor()
        cursor.executemany('DELETE FROM buzuo WHERE id = ?',
                [(x['source__id'],) for x in context['targets']])
        conn.commit()

    def action_add(self, context):
        conn = context['targets'][0]['source__db_conn']
        category = util.input(self.vim, context, 'Enter category: ')
        the_type = util.input(self.vim, context, 'Enter type: ')
        title = util.input(self.vim, context, 'Enter title: ')
        if not len(title) or not len(category) or not len(the_type):
            return
        cursor = conn.cursor()
        time_now = int(time.time())
        cursor.execute('INSERT INTO buzuo \
                (create_time, modify_time, status, category, type, title) \
                VALUES (?,?,?,?,?,?)',
                (time_now, time_now, 'pending', category, the_type, title))
        conn.commit()