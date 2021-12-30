FROM cimg/python:3.7

COPY --chown=circleci:circleci requirements.txt /requirements.txt

RUN pip install -r /requirements.txt