<script lang="ts">
import axios from "axios";
import { Card, CardContent, CardHeader, CardTitle } from "$lib/components/ui/card";
import { Progress } from "$lib/components/ui/progress";
import { Button } from "$lib/components/ui/button";
import { Input } from "$lib/components/ui/input";
import { onMount } from "svelte";
import { Toaster, toast } from "svelte-sonner";

interface Station {
  id?: string;
  stasiun: string;
  pm10: number;
  pm25: number;
  so2: number;
  o3: number;
  co: number;
  no2: number;
  kategori?: string;
  created_at?: Date;
  updated_at?: Date;
}

let contributors = { total: 0, categories: [] };
let stations: Station[] = [];
let stationsAll: Station[] = [];
let recommendations = [];
let kategoriCounts = [];
let stationAQI = [];

let newStation: Station = {
  stasiun: "",
  pm10: 0,
  pm25: 0,
  so2: 0,
  o3: 0,
  co: 0,
  no2: 0
};

let editingIndex = -1;
let currentPage = 1;
let limit = 5;
let totalPages = 1;

onMount(async () => {
  await Promise.all([
    fetchStations(),
    fetchStationsAll(),
    fetchKategoriCounts(),
    fetchStationAQI()
  ]);
});

async function fetchStations() {
  try {
    const response = await axios.get(`https://backend-airquality-production.up.railway.app/api/v1/air-quality/?page=${currentPage}&limit=${limit}`);
    if (response.data?.success) {
      stations = response.data.data;
      totalPages = response.data.pagination.totalPages;
    } else {
      console.error("Format data tidak valid:", response.data);
      toast.error("Gagal mengambil data stasiun");
    }
  } catch (error) {
    console.error("Kesalahan saat mengambil data kualitas udara:", error);
    toast.error("Terjadi kesalahan saat mengambil data");
  }
}

async function fetchStationsAll() {
  try {
    const response = await axios.get("https://backend-airquality-production.up.railway.app/api/v1/air-quality/all");
    if (response.data?.success) {
      stationsAll = response.data.data;
    } else {
      console.error("Format data tidak valid:", response.data);
    }
  } catch (error) {
    console.error("Kesalahan saat mengambil semua data stasiun:", error);
  }
}

async function fetchKategoriCounts() {
  try {
    const response = await axios.get("https://backend-airquality-production.up.railway.app/api/v1/air-quality/kategori-counts");
    if (response.data?.success) {
      kategoriCounts = response.data.data;
    } else {
      console.error("Format data kategori tidak valid:", response.data);
    }
  } catch (error) {
    console.error("Kesalahan saat mengambil data kategori:", error);
  }
}

async function fetchStationAQI() {
  try {
    const response = await axios.get("https://backend-airquality-production.up.railway.app/api/v1/air-quality/station-aqi");
    if (response.data?.success) {
      stationAQI = response.data.data;
    } else {
      console.error("Format data AQI stasiun tidak valid:", response.data);
    }
  } catch (error) {
    console.error("Kesalahan saat mengambil data AQI stasiun:", error);
  }
}

function getAQIColor(aqi: number): string {
  if (aqi <= 50) return "bg-green-500";
  if (aqi <= 100) return "bg-yellow-500";
  if (aqi <= 150) return "bg-orange-500";
  if (aqi <= 200) return "bg-red-500";
  if (aqi <= 300) return "bg-purple-500";
  return "bg-red-900";
}

function getParameterPencemarKritis(station: Station): string {
  const values = [
    { param: "PM10", value: parseFloat(station.pm10.toString()) },
    { param: "PM25", value: parseFloat(station.pm25.toString()) },
    { param: "SO2", value: parseFloat(station.so2.toString()) },
    { param: "O3", value: parseFloat(station.o3.toString()) },
    { param: "CO", value: parseFloat(station.co.toString()) },
    { param: "NO2", value: parseFloat(station.no2.toString()) },
  ];
  return values.reduce((max, current) => (current.value > max.value ? current : max)).param;
}

async function addStation() {
  if (Object.values(newStation).every(value => value !== "" && value !== 0)) {
    try {
      const response = await axios.post("https://backend-airquality-production.up.railway.app/api/v1/air-quality", newStation);
      if (response.data?.success) {
        await refreshData();
        resetForm();
        toast.success(`Stasiun ${response.data.data.stasiun} berhasil ditambahkan dengan kategori ${response.data.data.kategori}`);
      } else {
        console.error("Gagal menambahkan stasiun:", response.data.error);
        toast.error("Gagal menambahkan stasiun");
      }
    } catch (error) {
      console.error("Kesalahan saat menambahkan stasiun:", error);
      toast.error("Terjadi kesalahan saat menambahkan stasiun");
    }
  } else {
    toast.error("Harap isi semua field");
  }
}

async function updateStation() {
  if (editingIndex > -1) {
    try {
      const stationToUpdate = stations[editingIndex];
      const response = await axios.put(`https://backend-airquality-production.up.railway.app/api/v1/air-quality/${stationToUpdate.id}`, newStation);
      if (response.data?.success) {
        await refreshData();
        editingIndex = -1;
        newStation = { stasiun: "", pm10: 0, pm25: 0, so2: 0, o3: 0, co: 0, no2: 0 };
        toast.success(`Stasiun ${stationToUpdate.stasiun} berhasil diperbarui`);
      } else {
        console.error("Gagal memperbarui stasiun:", response.data.error);
        toast.error("Gagal memperbarui stasiun");
      }
    } catch (error) {
      console.error("Kesalahan saat memperbarui stasiun:", error);
      toast.error("Terjadi kesalahan saat memperbarui stasiun");
    }
  }
}

async function deleteStation(id: string) {
  try {
    const response = await axios.delete(`https://backend-airquality-production.up.railway.app/api/v1/air-quality/${id}`);
    if (response.data?.success) {
      await refreshData();
      toast.error(`Stasiun berhasil dihapus dengan id ${id}`);
    } else {
      console.error("Gagal menghapus stasiun:", response.data.error);
    }
  } catch (error) {
    console.error("Kesalahan saat menghapus stasiun:", error);
  }
}

// UI handlers
function editStation(index: number) {
  editingIndex = index;
  newStation = { ...stations[index] };
}

function resetForm() {
  newStation = { stasiun: "", pm10: 0, pm25: 0, so2: 0, o3: 0, co: 0, no2: 0 };
  editingIndex = -1;
}

function nextPage() {
  if (currentPage < totalPages) {
    currentPage++;
    fetchStations();
  }
}

function prevPage() {
  if (currentPage > 1) {
    currentPage--;
    fetchStations();
  }
}

async function refreshData() {
  await Promise.all([
    fetchStations(),
    fetchStationsAll(),
    fetchKategoriCounts(),
    fetchStationAQI()
  ]);
}
</script>

<div class="container mx-auto p-6">
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
    <Card class="h-full">
      <CardHeader>
        <CardTitle class="text-xl font-bold">Stasiun</CardTitle>
      </CardHeader>
      <CardContent>
        <p class="text-4xl font-bold">{stationsAll.length}</p>
        <p class="text-sm text-gray-500">Stasiun pemantau aktif</p>
      </CardContent>
    </Card>
    
    <Card class="md:col-span-3 h-full">
      <CardHeader>
        <CardTitle class="text-xl font-bold">Kategori Udara</CardTitle>
      </CardHeader>
      <CardContent>
        {#each kategoriCounts as category}
          <div class="mb-4 last:mb-0">
            <div class="flex justify-between mb-1">
              <span class="text-sm font-medium">{category.kategori}</span>
              <span class="text-sm font-medium">{category.count}</span>
            </div>
            <Progress value={category.count} max={stationsAll.length} class="h-2" />
          </div>
        {/each}
      </CardContent>
    </Card>
    
    <Card class="lg:col-span-3 h-full">
      <CardHeader>
        <CardTitle class="text-xl font-bold">Stasiun Kualitas Udara</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="mb-4">
          <Input type="text" placeholder="Nama Stasiun" bind:value={newStation.stasiun} />
          <div class="grid grid-cols-6 gap-2">
            <Input type="number" placeholder="PM10" bind:value={newStation.pm10} class="mt-2" />
            <Input type="number" placeholder="PM2.5" bind:value={newStation.pm25} class="mt-2" />
            <Input type="number" placeholder="SO2" bind:value={newStation.so2} class="mt-2" />
            <Input type="number" placeholder="O3" bind:value={newStation.o3} class="mt-2" />
            <Input type="number" placeholder="CO" bind:value={newStation.co} class="mt-2" />
            <Input type="number" placeholder="NO2" bind:value={newStation.no2} class="mt-2" />
          </div>
          <div class="mt-2 flex gap-2">
            {#if editingIndex > -1}
              <Button on:click={updateStation}>Update Stasiun</Button>
            {:else}
              <Button on:click={addStation}>Tambah Stasiun</Button>
            {/if}
            <Button on:click={resetForm} variant="outline">Reset</Button>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                <th class="pb-3 pl-2">#</th>
                <th class="pb-3">Stasiun</th>
                <th class="pb-3 text-right">PM10</th>
                <th class="pb-3 text-right">PM2.5</th>
                <th class="pb-3 text-right">SO2</th>
                <th class="pb-3 text-right">O3</th>
                <th class="pb-3 text-right">CO</th>
                <th class="pb-3 text-right">NO2</th>
                <th class="pb-3 text-right">Kategori</th>
                <th class="pb-3 text-right pr-2">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {#each stations as station, index}
                <tr class="border-t hover:bg-gray-50">
                  <td class="py-3 pl-2">{index + 1 + (currentPage - 1) * limit}</td>
                  <td class="py-3">{station.stasiun}</td>
                  <td class="py-3 text-right">{station.pm10}</td>
                  <td class="py-3 text-right">{station.pm25}</td>
                  <td class="py-3 text-right">{station.so2}</td>
                  <td class="py-3 text-right">{station.o3}</td>
                  <td class="py-3 text-right">{station.co}</td>
                  <td class="py-3 text-right">{station.no2}</td>
                  <td class="py-3 text-right">{station.kategori}</td>
                  <td class="py-3 text-right pr-2">
                    <Button on:click={() => editStation(index)} class="mr-2">Edit</Button>
                    <Button on:click={() => deleteStation(station.id)} variant="destructive">Hapus</Button>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
        <div class="mt-4 flex justify-between items-center">
          <Button on:click={prevPage} disabled={currentPage === 1}>Previous</Button>
          <span>Page {currentPage} of {totalPages}</span>
          <Button on:click={nextPage} disabled={currentPage === totalPages}>Next</Button>
        </div>
      </CardContent>
    </Card>
    
    <Card class="lg:col-span-1 h-full">
      <CardHeader>
        <CardTitle class="text-xl font-bold">Indeks Kualitas Udara per Stasiun</CardTitle>
      </CardHeader>
      <CardContent>
        {#each stationAQI as station}
          <div class="mb-4 last:mb-0">
            <div class="flex justify-between mb-1">
              <span class="text-sm font-medium">{station.stasiun}</span>
              <span class="text-sm font-medium">{station.aqi}</span>
            </div>
            <div class="relative pt-1">
              <div class="overflow-hidden h-2 text-xs flex rounded bg-gray-200">
                <div
                  style="width: {Math.min((station.aqi / 300) * 100, 100)}%"
                  class="{getAQIColor(station.aqi)} shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center"
                ></div>
              </div>
            </div>
          </div>
        {/each}
      </CardContent>
    </Card>
  </div>
</div>

<Toaster richColors position="top-right" />