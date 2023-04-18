require "dotenv/load"
def get_config
  {
    crab_rpc: "#{ENV["CRAB_ENDPOINT"]}",
    pangolin_rpc: "#{ENV["PANGOLIN_ENDPOINT"]}",
    goerli_rpc: "#{ENV["GOERLI_ENDPOINT"]}",
    mongodb_uri: "#{ENV["MONGODB_URI"]}",
    metadata: {
      crab2: File.join(__dir__, "metadata/crab2.json"),
      pangolin2: File.join(__dir__, "metadata/pangolin2.json"),
    },
    abi: {
      lane_events: File.join(__dir__, "/abi/lane-events.json"),
    },
  }
end
