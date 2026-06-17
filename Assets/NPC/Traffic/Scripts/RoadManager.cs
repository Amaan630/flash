using UnityEngine;
using System.Collections.Generic;

public class RoadManager : MonoBehaviour
{
    [Header("Road Network")]
    public List<Transform> roadSegments = new List<Transform>();
    public List<IntersectionController> intersections = new List<IntersectionController>();
    
    [Header("Map Boundaries")]
    public float mapWidth = 500f;
    public float mapHeight = 500f;
    public bool showMapBoundaries = true;
    
    [Header("Car Management")]
    public GameObject carPrefab;
    public int maxCars = 20;
    public float respawnInterval = 5f;
    private List<CarController> activeCars = new List<CarController>();
    private float respawnTimer = 0f;
    
    private void Start()
    {
        // Initialize the road network
        if (roadSegments.Count == 0)
        {
            Debug.LogWarning("No road segments defined in RoadManager. Auto-detecting...");
            GameObject[] roads = GameObject.FindGameObjectsWithTag("Road");
            foreach (GameObject road in roads)
            {
                roadSegments.Add(road.transform);
            }
        }
        
        if (intersections.Count == 0)
        {
            Debug.LogWarning("No intersections defined in RoadManager. Auto-detecting...");
            IntersectionController[] foundIntersections = FindObjectsOfType<IntersectionController>();
            intersections.AddRange(foundIntersections);
        }
        
        // Spawn initial cars
        for (int i = 0; i < maxCars; i++)
        {
            SpawnCar();
        }
    }
    
    private void Update()
    {
        // Check for cars that have gone off the map
        CheckCarBoundaries();
        
        // Respawn cars if needed
        respawnTimer += Time.deltaTime;
        if (respawnTimer >= respawnInterval)
        {
            respawnTimer = 0f;
            
            // Count active cars
            int activeCarCount = 0;
            foreach (CarController car in activeCars)
            {
                if (car != null && car.gameObject.activeInHierarchy)
                {
                    activeCarCount++;
                }
            }
            
            // Spawn more cars if needed
            if (activeCarCount < maxCars)
            {
                SpawnCar();
            }
        }
    }
    
    private void SpawnCar()
    {
        if (carPrefab == null || roadSegments.Count == 0)
            return;
        
        // Choose a random road segment to spawn on
        Transform roadSegment = roadSegments[Random.Range(0, roadSegments.Count)];
        
        // Get a position on the road
        Vector3 spawnPosition = roadSegment.position;
        
        // Adjust height to be on the road
        spawnPosition.y = roadSegment.position.y + 0.5f; // Slight offset to avoid clipping
        
        // Instantiate the car
        GameObject carObject = Instantiate(carPrefab, spawnPosition, roadSegment.rotation);
        CarController car = carObject.GetComponent<CarController>();
        
        if (car != null)
        {
            // Add to active cars list
            activeCars.Add(car);
        }
    }
    
    private void CheckCarBoundaries()
    {
        List<CarController> carsToRemove = new List<CarController>();
        
        foreach (CarController car in activeCars)
        {
            if (car == null)
            {
                carsToRemove.Add(car);
                continue;
            }
            
            // Check if car is outside map boundaries
            Vector3 carPosition = car.transform.position;
            bool isOutOfBounds = Mathf.Abs(carPosition.x) > mapWidth / 2 || 
                                Mathf.Abs(carPosition.z) > mapHeight / 2;
            
            if (isOutOfBounds)
            {
                // Option 1: Destroy the car and spawn a new one
                carsToRemove.Add(car);
                Destroy(car.gameObject);
                
                // Option 2: Teleport the car back to a valid road segment
                // This could be implemented as an alternative
            }
        }
        
        // Remove destroyed cars from the list
        foreach (CarController car in carsToRemove)
        {
            activeCars.Remove(car);
        }
    }
    
    private void OnDrawGizmos()
    {
        if (showMapBoundaries)
        {
            // Draw map boundaries
            Gizmos.color = Color.red;
            Vector3 center = transform.position;
            Vector3 size = new Vector3(mapWidth, 10, mapHeight);
            Gizmos.DrawWireCube(center, size);
        }
    }
} 