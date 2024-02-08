import type { AppProps } from "next/app";
import Head from "next/head";
import "./styles/globals.css";


function MyApp({ Component, pageProps }: AppProps) {
  return (
    <div>
      <Head>
        <title>thirdweb Signature Based Minting</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta
          name="description"
          content="thirdweb Example Repository to Showcase signature based minting on an NFT Collection contract"
        />
        <meta name="keywords" content="thirdweb signature based minting" />
      </Head>
      <Component {...pageProps} />
      </div>
  );
}

export default MyApp;
