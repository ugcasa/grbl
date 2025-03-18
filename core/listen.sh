#!/bin/bash
# grbl listener
# casa@ujo.guru 2023





# wait user to say "$GRBL_CALL"

call_sing=
[[ $GRBL_CALL ]] && call_sing="$GRBL_CALL"


listen.install () {

    # sudo add-apt-repository ppa:michael-sheldon/gst-deepspeech
    # sudo apt update
    # sudo add-apt-repository ppa:michael-sheldon/deepspeech
    # sudo apt update
    # sudo apt install deepspeech

    # https://deepspeech.readthedocs.io/en/r0.9/?badge=latest
    # https://github.com/mozilla/DeepSpeech/releases/tag/v0.9.3

    # Create and activate a virtualenv
    virtualenv -p python3 $HOME/tmp/$USER/deepspeech-venv/
    source $HOME/tmp/$USER/deepspeech-venv/bin/activate
    # Install DeepSpeech
    pip3 install deepspeech


    # Download pre-trained English model files
    curl -LO https://github.com/mozilla/DeepSpeech/releases/download/v0.9.3/deepspeech-0.9.3-models.pbmm
    curl -LO https://github.com/mozilla/DeepSpeech/releases/download/v0.9.3/deepspeech-0.9.3-models.scorer

    # Download example audio files
    curl -LO https://github.com/mozilla/DeepSpeech/releases/download/v0.9.3/audio-0.9.3.tar.gz
    tar xvf audio-0.9.3.tar.gz

    # Transcribe an audio file
    deepspeech --model deepspeech-0.9.3-models.pbmm --scorer deepspeech-0.9.3-models.scorer --audio audio/2830-3980-0043.wav

}

listen.training() {
    # https://deepspeech.readthedocs.io/en/r0.9/TRAINING.html
    # git clone --branch v0.9.3 https://github.com/mozilla/DeepSpeech
    # python3 -m venv $HOME/tmp/$USER/deepspeech-train-venv/
    # source $HOME/tmp/$USER/deepspeech-train-venv/bin/activate
    # pip3 install --upgrade pip==20.2.2 wheel==0.34.2 setuptools==49.6.0
    # pip3 install --upgrade -e .
    # sudo apt-get install python3-dev
    # # pip3 uninstall tensorflow
    # pip3 install 'tensorflow-gpu==1.15.4'
}



# server  https://www.digikey.com/en/maker/projects/how-to-run-custom-speechtotext-stt-and-texttospeech-tts-servers/90ec03ef27854b9b83b6e27090b767b3

deepspeech --hot_words $GRBL_CALL:1 --model deepspeech-0.9.3-models.pbmm --scorer deepspeech-0.9.3-models.scorer --audio audio/2830-3980-0043.wav


mic_vad_streaming.py  -v 2 -m ~/deepspeech-0.9.3-models.pbmm -s ~/deepspeech-0.9.3-models.scorer -d 10


pip install sounddevice --user