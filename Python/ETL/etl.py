import pandas as pd
import json

def etl(csv_file):

    df = pd.read_csv(csv_file, delimiter=';')
    
    data = {}
    data['schemaVersion'] = df['schemaVersion'].iloc[0]
    data['extractStartDateTime'] = df['extractStartDateTime'].iloc[0]
    data['MarketsList'] = []

    df = df.drop(['schemaVersion', 'extractStartDateTime', 'MarketsList'], axis=1)
    df = df.groupby(['Market_isoCode', 'Market_storeId', 'Interval_start', 'Interval_end', 'AverageTicket_currency'], as_index=False).agg(list)

    for _, row in df.iterrows():
        _d = {
            'Market': {
                'isoCode': row['Market_isoCode'],
                'storeId': row['Market_storeId']
            },
            'Interval': {
                'start': row['Interval_start'],
                'end': row['Interval_end']
            },
            'AverageTicket': {
                'currency': row['AverageTicket_currency'],
                'TiersList': [{
                    'tier': row['TiersList_tier'][x],
                    'amount': float(row['TiersList_amount'][x].replace(',', '.')),
                } for x in range(len(row['TiersList_tier']))]
            }
        }
        data['MarketsList'].append(_d)

    return data

def main():
    csv_file = 'MarketAvrgTicketSample.csv'
    json_data = etl(csv_file)
    with open('output.json', 'w') as output_file:
        json.dump(json_data, output_file, indent=4)

if __name__ == "__main__":
    main()