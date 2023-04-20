require "dotenv/load"
def get_config
  {
    ethereum_rpc: "#{ENV["ETHEREUM_ENDPOINT"]}",
    darwinia_rpc: "#{ENV["DARWINIA_ENDPOINT"]}",
    crab_rpc: "#{ENV["CRAB_ENDPOINT"]}",
    pangolin_rpc: "#{ENV["PANGOLIN_ENDPOINT"]}",
    goerli_rpc: "#{ENV["GOERLI_ENDPOINT"]}",
    mongodb_uri: "#{ENV["MONGODB_URI"]}",
    metadata: {
      darwinia: File.join(__dir__, "metadata/darwinia.json"),
      crab: File.join(__dir__, "metadata/crab.json"),
      pangolin: File.join(__dir__, "metadata/pangolin.json"),
    },
    abi: {
      lane_events: File.join(__dir__, "/abi/lane-events.json"),
    },
  }
end
