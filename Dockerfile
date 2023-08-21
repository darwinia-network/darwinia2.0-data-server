FROM ruby:3.1.2

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV RACK_ENV=production
EXPOSE 4567
ENTRYPOINT ["bundle", "exec"]
