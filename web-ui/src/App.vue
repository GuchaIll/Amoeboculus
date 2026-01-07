<script setup>
import { onMounted } from 'vue';
import init from 'wasm-engine'; // Using the alias we just made

onMounted(async () => {
  await init();
  console.log("WASM Loaded!");
});
</script>

<template>
  <header>
    <canvas id="canvas"></canvas>
    <div class="overlay">
      <h1>Amoeboculus Engine</h1>
    </div>
  </header>

  <main>

  </main>
</template>

<style>
body { margin: 0; background: #000; }
canvas { width: 100vw; height: 100vh; display: block; }
.overlay { position: absolute; top: 10px; left: 10px; color: white; pointer-events: none; }
</style>