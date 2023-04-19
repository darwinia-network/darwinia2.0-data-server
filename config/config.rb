require "dotenv/load"
def get_config
  {
    crab_rpc: "#{ENV["CRAB_ENDPOINT"]}",
    pangolin_rpc: "#{ENV["PANGOLIN_ENDPOINT"]}",
    goerli_rpc: "#{ENV["GOERLI_ENDPOINT"]}",
    mongodb_uri: "#{ENV["MONGODB_URI"]}",
    metadata: {
      crab: File.join(__dir__, "metadata/crab.json"),
      pangolin: File.join(__dir__, "metadata/pangolin.json"),
    },
    abi: {
      lane_events: File.join(__dir__, "/abi/lane-events.json"),
    },
  }
end
