# Data Whistleblowing

This is a simple proof of concept of a data reporting and anonymous
whistleblowing mechanism.  Under the hood, it uses Ethereum smart contracts and
[Semaphore](https://github.com/kobigurk/semaphore), a zero-knowledge signalling
gadget.

While the core functionality is original, much of the scaffolding in this
repository is a fork of
[semaphore-ui](https://github.com/weijiekoh/semaphore-ui).

More information about Semaphore can be found
[here](https://medium.com/coinmonks/to-mixers-and-beyond-presenting-semaphore-a-privacy-gadget-built-on-ethereum-4c8b00857c9b).

## Local development and testing

These instructions have been tested with Ubuntu 18.0.4 and Node 11.14.0.

### Requirements

- Node v11.14.0.
      - We recommend [`nvm`](https://github.com/nvm-sh/nvm) to manage your Node
        installation.

### Local development

Install `npx` and `http-server` if you haven't already:

```bash
npm install -g npx http-server
```

Clone this repository and its `semaphore` submodule:

```bash
git clone git@github.com:weijiekoh/datawhistleblowing.git && \
cd datawhistleblowing && \
git submodule update --init
```

Download the circuit, keys, and verifier contract. Doing this instead of
generating your own keys will save you about 20 minutes. Note that these are
not for production use as there is no guarantee that the toxic waste was
discarded.

```bash
./scripts/downloadSnarks.sh
```

Install all dependencies and build the source code:

```bash
npm i &&
npm run bootstrap &&
npm run build
```

In a separate terminal, navigate to `contracts` and launch Ganache:

```bash
cd contracts
npm run ganache
```

Staying inside the `contracts` directory, run the demo script. You need an
[`solc`](https://github.com/ethereum/solidity) 0.5.X binary somewhere in your
filesystem.

```bash
node build/run.js -s /path/to/solc -o ./abi -i ./sol/
```
