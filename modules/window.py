#!/usr/bin/python3
# -*- coding: utf-8 -*-
# https://docs.python.org/3/library/tkinter.html
# https://likegeeks.com/python-gui-examples-tkinter-tutorial/

version = '0.0.1'
forderSeparator =
fs = forderSeparator

# os check
from sys import platform
if platform == "linux" or platform == "linux2":
    print("linux")
    forderSeparator='\\'
elif platform == "darwin":
    print("osx")
elif platform == "win32":
    print("windows")
    forderSeparator='/'
elif platform == "java":
    print("java")
    forderSeparator='?'
else:
    platform == "unknown"
    forderSeparator='\\'
    print("unknown")

# window manager
from tkinter import *
from tkinter.ttk import *
from tkinter import messagebox
from tkinter import scrolledtext
from tkinter.ttk import Progressbar
from tkinter import filedialog

def open_dir():
    dir = filedialog.askdirectory()

def open_file():
    file = filedialog.askopenfilename()
    bar['value'] = bar_value
    print(bar_value)

def update():
    res = "" + txt.get()
    lbl.configure(text=res)
    btn1.configure(text="save")
    txt.configure(state='normal')
    btn2.configure(text="show selections", state='normal')    # lbl.configure(text="Button was update !!")


def save():
    res = "" + txt.get()
    lbl.configure(text=res)
    #btn2.configure(text="saved", state='disabled')
    txt.configure(state='disabled')
    arvot="user: "+txt.get()+"\nselected:"+str(selected.get())+"\ncombo: "+str(combo.get()+"\nspin: "+spin.get()+"file: "+file+"\nplatform: "+platform)
    messagebox.showinfo('Arvot', arvot)
    # lbl.configure(text="Button was update !!")


def do_messages():
    res = messagebox.askquestion('Mitäs mieltä','Mitäs mieltä?')
    res = messagebox.askyesno('Jees or nou','Että kumpi?')
    res = messagebox.askyesnocancel('jees nou kankel','Mikäs näistä?')
    res = messagebox.askokcancel('ok kankel','Kumpikos?')
    res = messagebox.askretrycancel('retry kankel','Valistaans?')


file = ""
bar_value = 0
window = Tk()
window.title("budget manager v"+version)
window.geometry("1500x700")
lbl = Label(window, text="unknown") #, font=("Arial Bold", 14)
txt = Entry(window,width=20, state='disabled')
txt.focus()

btn1 = Button(window, text="edit", command=update)
btn2 = Button(window, text="show selections", command=save)
message_btn = Button(window, text="show all messages", command=do_messages)

combo = Combobox(window)
combo['values']= ("rotta", "näätä", "kissa", "lokki", "susi")
combo.current(1) #set the selected item

chk_state = BooleanVar()
chk = Checkbutton(window, text='Choose', var=chk_state)
chk_state.set(True) #set check state

selected = IntVar()
rad1 = Radiobutton(window,text='First', value=1, variable=selected)
rad2 = Radiobutton(window,text='Second', value=2, variable=selected)
rad3 = Radiobutton(window,text='Third', value=3, variable=selected)

scroll = scrolledtext.ScrolledText(window,width=25,height=10)
scroll.insert(INSERT,'You text goes here')

default_spin = IntVar()
default_spin.set(42)
spin = Spinbox(window, from_=0, to=100, width=3, textvariable=default_spin)

bar = Progressbar(window, length=200, style='black.Horizontal.TProgressbar')

menu = Menu(window)
new_item = Menu(menu)
new_item.add_command(label='Open', command=open_file)
new_item.add_command(label='Vault', command=open_dir)
menu.add_cascade(label='File', menu=new_item)


# first row
lbl.grid(column=0, row=0)
txt.grid(column=1, row=0)
btn1.grid(column=2, row=0)

# second row
combo.grid(column=0, row=1)
chk.grid(column=1, row=1)
rad1.grid(column=2, row=1)
rad2.grid(column=3, row=1)
rad3.grid(column=4, row=1)
spin.grid(column=5, row=1)
btn2.grid(column=6, row=1)

# third row
scroll.grid(column=0,row=2)

# forth row
message_btn.grid(column=0,row=3)
btn2.grid(column=1, row=3)

# fift row
bar.grid(column=0, row=4)


window.config(menu=menu)
window.mainloop()



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