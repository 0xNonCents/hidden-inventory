import type { NextPage } from "next";
import { Game as GameType } from "phaser";
import { useEffect, useState } from "react";
import styles from "./styles/Home.module.css";

const Home: NextPage = () => {
  const [game, setGame] = useState<GameType>();

  useEffect(() => {
    // import dynamically phaser sdk
    async function initPhaser() {
      const Phaser = await import("phaser");

      // import dynamically game scenes
      const { default: Platformer } = await import(
        "../components/scenes/PlatformerScene"
      );

      const { default: MainScene } = await import(
        "../components/scenes/MainScene"
      );

      // run only once
      if (game) {
        return;
      }

      // create new phaser game
      const phaserGame = new Phaser.Game({
        type: Phaser.AUTO,
        parent: "app",
        width: 800,
        height: 600,
        physics: {
          default: "arcade",
          arcade: {
            gravity: { y: 200 },
          },
        },
        dom: {
          createContainer: true,
        },
        scene: [Platformer, MainScene],
      });

      setGame(phaserGame);
    }
    initPhaser();
  }, []);

  return (
    <div className={styles.container}>
      <div id="app" key="app">
        {/* the game will be rendered here */}
      </div>

  </div>
  );
};

export default Home;
