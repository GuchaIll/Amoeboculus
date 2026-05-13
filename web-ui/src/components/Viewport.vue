<template>
  <canvas ref="canvas" class="viewport-canvas" id="amoeba-canvas"></canvas>
</template>

<script setup>
import { onMounted, onBeforeUnmount, ref } from 'vue';
import { getEngine, startRenderLoop } from '../engine.js';

const canvas = ref(null);
let resizeObserver = null;

onMounted(async () =>{
  const engine = await getEngine("amoeba-canvas");
  startRenderLoop(engine);

  resizeObserver = new ResizeObserver(([entry]) => {
    const { width, height } = entry.contentRect;
    engine.value.width = width;
    engine.value.height = height;
    engine.resize(canvas.value.width, canvas.value.height);
  });

  resizeObserver.observe(canvas.value);

});

onBeforeUnmount(() => {
  if (resizeObserver) {
    resizeObserver.disconnect();
  }
});

</script>


<style scoped>
.viewport-canvas {
  width: 100%;
  height: 100%;
  display: block;
}
</style>
