FROM perl:5.20

MAINTAINER Dominic Sonntag <dominic.sonntag@unitedprint.com>

RUN cpanm YAML Dancer2 Digest::SHA && rm -rf /root/.cpanm

RUN cpanm Test::CheckManifest Test::Pod::Coverage

RUN mkdir /app

WORKDIR /app

COPY . /app/

EXPOSE 3000

CMD [ "perl", "dancer2.pl" ]

