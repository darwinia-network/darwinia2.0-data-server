FROM ruby:3.1.2

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV PANGOLIN_ENDPOINT=https://pangolin-rpc.darwinia.network
ENV GOERLI_ENDPOINT=https://eth-goerli.g.alchemy.com/v2/<your-api-key>
ENV MONGODB_URI=mongodb+srv://<username>:<password>@<your-cluster-url>/goerli_pangolin?retryWrites=true&w=majority
ENV RACK_ENV=production
EXPOSE 4567
ENTRYPOINT ["bundle", "exec"]
