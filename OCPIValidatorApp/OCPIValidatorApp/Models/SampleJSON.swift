import Foundation

enum SampleJSON {
    static let location = """
    {
        "id": "LOC1",
        "type": "PARKING_LOT",
        "name": "Downtown Parking",
        "address": "123 Main St",
        "city": "San Francisco",
        "country": "USA",
        "coordinates": {
            "latitude": "37.7749",
            "longitude": "-122.4194"
        },
        "last_updated": "2024-01-07T10:00:00Z"
    }
    """
    
    static let token = """
    {
        "uid": "012345678",
        "type": "RFID",
        "auth_id": "CARD123",
        "issuer": "Example Company",
        "valid": true,
        "whitelist": "ALLOWED",
        "last_updated": "2024-01-07T10:00:00Z"
    }
    """
    
    static let session = """
    {
        "id": "SESSION1",
        "start_datetime": "2024-01-07T10:00:00Z",
        "kwh": 20.5,
        "auth_id": "CARD123",
        "auth_method": "WHITELIST",
        "location": {
            "id": "LOC1",
            "type": "PARKING_LOT",
            "name": "Downtown Parking",
            "address": "123 Main St",
            "city": "San Francisco",
            "country": "USA",
            "coordinates": {
                "latitude": "37.7749",
                "longitude": "-122.4194"
            }
        },
        "last_updated": "2024-01-07T11:00:00Z"
    }
    """
    
    static let cdr = """
    {
        "id": "CDR1",
        "start_datetime": "2024-01-07T10:00:00Z",
        "end_datetime": "2024-01-07T11:00:00Z",
        "auth_id": "CARD123",
        "auth_method": "WHITELIST",
        "location": {
            "id": "LOC1",
            "type": "PARKING_LOT",
            "name": "Downtown Parking",
            "address": "123 Main St",
            "city": "San Francisco",
            "country": "USA",
            "coordinates": {
                "latitude": "37.7749",
                "longitude": "-122.4194"
            }
        },
        "total_energy": 20.5,
        "total_time": 3600,
        "total_cost": 10.25,
        "last_updated": "2024-01-07T11:00:00Z"
    }
    """
    
    static let tariff = """
    {
        "id": "TARIFF1",
        "currency": "USD",
        "elements": [
            {
                "price_components": [
                    {
                        "type": "TIME",
                        "price": 2.00,
                        "step_size": 300
                    },
                    {
                        "type": "ENERGY",
                        "price": 0.30,
                        "step_size": 1
                    }
                ]
            }
        ],
        "last_updated": "2024-01-07T10:00:00Z"
    }
    """
} 