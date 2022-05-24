using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

namespace Company.Function
{
    public static class BlobUpload
    {
        [FunctionName("BlobUpload")]
        
         public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log, ExecutionContext storage)
        {
            log.LogInformation($"C# Http trigger function executed at: {DateTime.Now}");
            CreateContainerIfNotExists(log, storage);
           //string info = req.Query["content"];
            string cont = req.Query["contname"];
            var info = await new StreamReader(req.Body).ReadToEndAsync();
           // Root myClass = JsonConvert.DeserializeObject<Root>(content)

            CloudStorageAccount storageAccount = GetCloudStorageAccount(storage);
            CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(cont);

            
            
                string randomStr = Guid.NewGuid().ToString()+".json";
                CloudBlockBlob blob = container.GetBlockBlobReference(randomStr);

                var serializeJesonObject = JsonConvert.SerializeObject(info);
                blob.Properties.ContentType = "application/json";

                using (var ms = new MemoryStream())
                {
                    LoadStreamWithJson(ms, serializeJesonObject);
                    await blob.UploadFromStreamAsync(ms);
                }
                log.LogInformation($"Bolb {randomStr} is uploaded to container {container.Name}");
                await blob.SetPropertiesAsync();
            

            return new OkObjectResult("UploadBlobHttpTrigger function executed successfully!!");
        }

        private static void CreateContainerIfNotExists(ILogger logger, ExecutionContext executionContext)
        {
            CloudStorageAccount storageAccount = GetCloudStorageAccount(executionContext);
            CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
            string[] containers = new string[] { "newcont" };
            foreach (var item in containers)
            {
                CloudBlobContainer blobContainer = blobClient.GetContainerReference(item);
                blobContainer.CreateIfNotExistsAsync();
            }
        }

        private static CloudStorageAccount GetCloudStorageAccount(ExecutionContext executionContext)
        {
            var config = new ConfigurationBuilder()
                            .SetBasePath(executionContext.FunctionAppDirectory)
                            .AddJsonFile("local.settings.json", true, true)
                            .AddEnvironmentVariables().Build();
            CloudStorageAccount storageAccount = CloudStorageAccount.Parse(config["CloudStorageAccount"]);
            return storageAccount;
        }
        private static void LoadStreamWithJson(Stream ms, object obj)
        {
            StreamWriter writer = new StreamWriter(ms);
            writer.Write(obj);
            writer.Flush();
            ms.Position = 0;
        }
    }
}
