#!/usr/bin/python3
# -*- coding: utf-8 -*-

# target is to be:
# - be main library and run time to service guru-cli application that really benefits from gui
# - a wrap for window manager to be too easy to use when needed
# - is compatible linux, windows (and later mac os) operating systems
# - served a least test environment for budget tool

from tkinter import *
from tkinter import ttk
from tkinter import messagebox
from tkinter import scrolledtext
from tkinter.ttk import Progressbar
from tkinter import filedialog


class window():
    "build and draw simple pre-set window"

    target_file=""
    home_folder=""
    version="0.0.1"

    def __init__(self, title, geometry="1500x700"):

        self.window = Tk()
        self.window.option_add('*Dialog.msg.font', 'Arial 10')
        self.window.title(title)
        self.window.geometry(geometry)

    def open_dir(self):
        self.home_folder = filedialog.askdirectory()
        print("home folder: "+self.home_folder)

    def open_file(self):
        self.target_file = filedialog.askopenfilename()
        print("open file "+self.target_file)

    def update(self):
        arvot="\n"+"open file: "+self.target_file+"\nhome folder: "+self.home_folder
        messagebox.showinfo("values in use", arvot)

    def menu(self):

        self.menu = Menu(self.window)
        new_item = Menu(self.menu)
        new_item.add_command(label='Open', command=self.open_file)
        new_item.add_command(label='Folder', command=self.open_dir)
        new_item.add_command(label='Export')
        self.menu.add_cascade(label='File', menu=new_item)
        self.window.config(menu=self.menu)


    def bye(self):
        quit()
        #how to exit mainloop?

    def welcome(self):

        self.menu()

        lbl = Label(self.window, text="Welcome to guru budget tools!", font=("Arial Bold", 9))
        #lbl.pack(side="top")
        lbl.place(relx=.5, rely=.3, anchor="center")
        #lbl.grid(column=1, row=1)

        update_bnt = Button(self.window, text="update", command=self.update)
        #update_bnt.place(relx=.5, rely=.5, anchor="e")
        #update_bnt.grid(column=1, row=13)
        update_bnt.place(relx=.3, rely=.6, anchor="center")

        bye_btn = Button(self.window, text="exit", command=self.bye)
        #bye_btn.place(relx=.5, rely=.5, anchor="s")
        bye_btn.place(relx=.7, rely=.6, anchor="center")

        self.window.mainloop()
        print("post")


# def update(self):
#     res = "" + txt.get()
#     lbl.configure(text=res)
#     btn1.configure(text="save")
#     txt.configure(state='normal')
#     btn2.configure(text="show selections", state='normal')    # lbl.configure(text="Button was update !!")

# if sys.platform.startswith('freebsd'):
#     # FreeBSD-specific code here...
# elif sys.platform.startswith('linux'):
#     # Linux-specific code here...
# elif sys.platform.startswith('aix'):
#     # AIX-specific code here...


# window manager
# https://docs.python.org/3/library/tkinter.html
# https://likegeeks.com/python-gui-examples-tkinter-tutorial/
# https://pythonguides.com/python-tkinter-animation/
# https://pythonguides.com/python-tkinter-editor/


    # def do_messages(self):
    #     res = messagebox.askquestion('Mitäs mieltä','Mitäs mieltä?')
    #     res = messagebox.askyesno('Jees or nou','Että kumpi?')
    #     res = messagebox.askyesnocancel('jees nou kankel','Mikäs näistä?')
    #     res = messagebox.askokcancel('ok kankel','Kumpikos?')
    #     res = messagebox.askretrycancel('retry kankel','Valistaans?')

    # txt = Entry(window,width=20, state='disabled')
    # txt.focus()
    # txt.grid(column=1, row=0)

    # btn2 = Button(window, text="show selections", command=save)
    # btn2.grid(column=6, row=1)
    # message_btn = Button(window, text="show all messages", command=do_messages)
    # message_btn.grid(column=0,row=3)

    # combo = Combobox(window)
    # combo['values']= ("rotta", "näätä", "kissa", "lokki", "susi")
    # combo.current(1) #set the selected item
    # combo.grid(column=0, row=1)

    # chk_state = BooleanVar()
    # chk = Checkbutton(window, text='Choose', var=chk_state)
    # chk_state.set(True) #set check state
    # chk.grid(column=1, row=1)

    # selected = IntVar()
    # rad1 = Radiobutton(window,text='First', value=1, variable=selected)
    # rad1.grid(column=2, row=1)
    # rad2 = Radiobutton(window,text='Second', value=2, variable=selected)
    # rad2.grid(column=3, row=1)
    # rad3 = Radiobutton(window,text='Third', value=3, variable=selected)
    # rad3.grid(column=4, row=1)

    # scroll = scrolledtext.ScrolledText(window,width=25,height=10)
    # scroll.insert(INSERT,'You text goes here')
    # scroll.grid(column=0,row=2)

    # default_spin = IntVar()
    # default_spin.set(42)
    # spin = Spinbox(window, from_=0, to=100, width=3, textvariable=default_spin)
    # spin.grid(column=5, row=1)

    # bar_value = 0
    # bar = Progressbar(window, length=200, style='black.Horizontal.TProgressbar')
    # bar.grid(column=0, row=4)

# class Example(Frame):

#     def __init__(self, parent):
#         Frame.__init__(self, parent, background="gray")

#         self.parent = parent

#         self.parent.title("testi-ikkuna")
#         lbl = Label(self.parent, text="Hello")
#         lbl.grid(column=0, row=0)
#         self.pack(fill=BOTH, expand=1)


# # screenName=None, baseName=None, className='Tk', useTk=True, sync=False, use=None
# root = Tk()
# root.geometry("500x500")
# app = Example(root)

# root.mainloop()


# import turtle
# screen = turtle.Screen()
# screen.setup(1500, 1500)
# screen.bgcolor('white')