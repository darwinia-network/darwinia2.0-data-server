FROM ruby:3.1.2

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install
RUN gem install puma

COPY . .

ENV RACK_ENV=production
EXPOSE 4567
CMD ["./run.sh"]