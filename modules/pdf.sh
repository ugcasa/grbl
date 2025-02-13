#!/bin/bash
# pdf tools for grbl


pdf.install () {
# install requirements
    sudo apt-get install poppler-utils pandoc

    # cd $HOME/apps/
    # git clone https://github.com/vpec/lyrapdf.git
    # pip install pdfminer.six sspipe

}


pdf.to_text() {
# convert pdf to text. input file_name.pdf and optional output.txt
    local pdf_file=$1
    shift
    if [[ $1 ]] ; then 
            output_file=$1
        else
            output_file="${pdf_file%.*}.txt"
        fi

    pdftotext -layout $pdf_file $output_file
}


pdf.to_html () {
# convert pdf to html. input file_name.pdf and optional output.html
## ISSEU: not really good output
    local pdf_file=$1
    shift
    if [[ $1 ]] ; then
            output_file=$1
            options="-i"
        else
            output_file="${pdf_file%.*}.html"
        fi

    pdftohtml $options $pdf_file $output_file # -i ignore images
}


pdf.to_md() {
# convert pdf to markdown. input file_name.pdf and optional output.md
    local pdf_file=$1
    local html_file="${pdf_file%.*}.html"
    shift
    if [[ $1 ]] ; then
            output_file=$1
        else
            output_file="${pdf_file%.*}.md"
        fi
    
    pdf.to_html $pdf_file $html_file
    pandoc -o $output_file $html_file
    #python3 -m $HOME/apps/lyrapdf/lyrapdf $pdf_file --format markdown --threads 4
}


pdf.to_png() {
# convert pdf file to pictures
    local pdf_file=$1
    shift
    if [[ $1 ]] ; then 
            output_file=$1
        else
            output_file="${pdf_file%.*}"
        fi

    pdftoppm -png $pdf_file $output_file
}


# pdf.colors () {
# # change text color of pdf for printing wihout of some color

#     gs -o output.pdf     \
#    -sDEVICE=pdfwrite \
#    -c "{1 exch sub}{1 exch sub}{1 exch sub}{1 exch sub} setcolortransfer" \
#    -f $1
# }