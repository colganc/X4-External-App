<template>
  <widget>
    <template #header>
      <div class="d-flex justify-content-between">
        <h4 class="card-title pb-0 mb-0">Inventory (Raw)</h4>
      </div>
    </template>

    <div class="p-2">
      <div v-if="!gameData" class="text-muted small">No inventory data received yet.</div>

      <div v-else>
        <div class="small text-muted mb-2">
          <div v-if="meta.playerName">Player: {{ meta.playerName }}</div>
          <div v-if="meta.playerFaction">Faction: {{ meta.playerFaction }}</div>
          <div v-if="meta.shipName">Ship: {{ meta.shipName }} ({{ meta.shipId }})</div>
        </div>

        <div v-if="items && items.length">
          <div class="d-flex mb-2 gap-2 align-items-center">
            <input v-model="filters.q" class="form-control form-control-sm" placeholder="Filter item id..." />
            <input v-model.number="filters.minCount" type="number" class="form-control form-control-sm" style="width:90px" placeholder="Min" />
            <select v-model="sort.by" class="form-select form-select-sm" style="width:120px">
              <option value="id">Sort: id</option>
              <option value="count">Sort: count</option>
            </select>
            <button class="btn btn-sm btn-outline-secondary" @click="toggleSortDir()">{{ sort.dir === 'asc' ? '↑' : '↓' }}</button>
          </div>

          <div class="list-group list-group-flush">
          <div
            v-for="it in displayedItems"
            :key="it.id || it.name"
            class="list-group-item d-flex justify-content-between align-items-start"
          >
            <div class="me-auto small">{{ it.id }}</div>
            <div class="badge bg-secondary rounded-pill small">{{ it.count }}</div>
          </div>
          </div>
        </div>

        <pre v-else class="small mt-2" style="white-space: pre-wrap; word-break: break-word;">{{ formatted }}</pre>
      </div>
    </div>
  </widget>
</template>

<script>
import Widget from "../Widget.vue";

export default {
  name: 'InventoryWidget',
  components: { Widget },
  props: {
    gameData: [Object, Array, String],
    maxHeight: {
      type: Number,
      default: 40,
    },
  },
  data() {
    return {
      filters: {
        q: '',
        minCount: 0,
      },
      sort: {
        by: 'id',
        dir: 'asc',
      },
    };
  },
  methods: {
    toggleSortDir() {
      this.sort.dir = this.sort.dir === 'asc' ? 'desc' : 'asc';
    }
  },
  computed: {
    formatted() {
      try {
        if (typeof this.gameData === 'string') return this.gameData;
        return JSON.stringify(this.gameData, null, 2);
      } catch (e) {
        return String(this.gameData);
      }
    }
    ,
    meta() {
      if (!this.gameData) return {};
      // If the widget receives a wrapper object (like { playerId, shipId, inventory })
      if (typeof this.gameData === 'object' && !Array.isArray(this.gameData)) {
        return {
          playerName: this.gameData.playerName || this.gameData.player || null,
          playerFaction: this.gameData.playerFaction || null,
          shipName: this.gameData.shipName || null,
          shipId: this.gameData.shipId || null,
        };
      }
      return {};
    },
    items() {
      if (!this.gameData) return [];

      // If gameData is an object that contains `.inventory` (our normalized format)
      if (typeof this.gameData === 'object' && !Array.isArray(this.gameData) && this.gameData.inventory) {
        if (Array.isArray(this.gameData.inventory)) return this.gameData.inventory;
        if (typeof this.gameData.inventory === 'object') return Object.entries(this.gameData.inventory).map(([k, v]) => ({ id: k, count: v }));
      }

      // If gameData itself is an array of items
      if (Array.isArray(this.gameData)) return this.gameData;

      return [];
    }
    ,
    displayedItems() {
      let list = (this.items || []).slice();

      // Filter by search text
      const q = (this.filters.q || '').toString().toLowerCase().trim();
      if (q) {
        list = list.filter((it) => (it.id || '').toString().toLowerCase().indexOf(q) !== -1);
      }

      // Filter by min count
      const min = Number(this.filters.minCount) || 0;
      if (min > 0) {
        list = list.filter((it) => Number(it.count) >= min);
      }

      // Sorting
      const by = this.sort.by || 'id';
      const dir = this.sort.dir === 'desc' ? -1 : 1;

      list.sort((a, b) => {
        if (by === 'count') {
          const na = Number(a.count) || 0;
          const nb = Number(b.count) || 0;
          return (na - nb) * dir;
        }
        // default: sort by id (string)
        const sa = (a.id || '').toString().toLowerCase();
        const sb = (b.id || '').toString().toLowerCase();
        if (sa < sb) return -1 * dir;
        if (sa > sb) return 1 * dir;
        return 0;
      });

      return list;
    }
  }
}
</script>

<style lang="scss" scoped>
@import "./scss/widget.scss";

pre {
  background: transparent;
  border: none;
  margin: 0;
}

</style>
